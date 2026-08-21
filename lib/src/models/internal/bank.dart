import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart' hide Hmac;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:pqcrypto/pqcrypto.dart' hide sha256;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../beshence_sdk_flutter.dart';
import '../../hive_objects/account_v1.dart';
import '../../hive_objects/bank_v1.dart';
import '../../misc.dart';

class BeshenceBankInternal {
  BeshenceBank bank;

  static final Map<String, String?> _onlineApiUrls = {};

  String? get onlineApiUrl => _onlineApiUrls[bank.id];
  set onlineApiUrl(String? value) => _onlineApiUrls[bank.id] = value;

  BeshenceBankInternal({required this.bank});


  Future<void> updateOnlineApiUrl() async {
    try {
      onlineApiUrl = (await Beshence.pingBank(bankId: bank.id)).apiUrl;
    } catch(e) {
      onlineApiUrl = null;
    }
  }

  Future<http.Response> get({
    BeshenceVault? vault,
    required String path,
    Map<String,String>? headers,
    int? tries,
  }) async {
    if((tries ?? 0) >= 3) {
      throw StateError("Too many attempts.");
    }

    if(onlineApiUrl == null) {
      await updateOnlineApiUrl().timeout(const Duration(seconds: 60));
    }

    if (onlineApiUrl == null) {
      throw StateError("Bank is offline");
    }

    final (newHeaders, oauth, refreshToken) = tokenize(vault: vault, headers: headers);

    final response = await _request(
      method: "GET",
      path: path,
      headers: newHeaders,
    );

    final jsonResponse = jsonDecode(response.body);

    if(jsonResponse["err"] != "UNAUTHORIZED") {
      return response;
    }

    if(oauth) {
      throw StateError("OAuth token expired");
    }

    await refreshTokens(refreshToken);

    return get(
      vault: vault,
      path: path,
      headers: headers,
      tries: (tries ?? 0)+1,
    );
  }

  Future<http.Response> post({
    BeshenceVault? vault,
    required String path,
    Map<String,String>? headers,
    String? body,
    int? tries,
  }) async {
    if((tries ?? 0) >= 3) {
      throw StateError("Too many attempts.");
    }

    if(onlineApiUrl == null) {
      await updateOnlineApiUrl().timeout(const Duration(seconds: 60));
    }

    if (onlineApiUrl == null) {
      throw StateError("Bank is offline");
    }

    final (newHeaders, oauth, refreshToken) = tokenize(vault: vault, headers: headers);

    final response = await _request(
        method: "POST",
        path: path,
        headers: newHeaders,
        body: body
    );

    final jsonResponse = jsonDecode(response.body);

    if(jsonResponse["err"] != "UNAUTHORIZED") {
      return response;
    }

    if(oauth) {
      throw StateError("OAuth token expired");
    }

    await refreshTokens(refreshToken);

    return post(
      vault: vault,
      path: path,
      headers: headers,
      body: body,
      tries: (tries ?? 0)+1,
    );
  }

  (Map<String, String>, bool, String?) tokenize({BeshenceVault? vault, Map<String, String>? headers}) {
    BankV1 bankV1 = banksV1Box.get(encodeKey(bankId: bank.id))!;
    AccountV1? accountV1 = accountsV1Box.get(encodeKey(accountId: vault?.account.id));

    String? accessToken = bankV1.accessToken;
    String? refreshToken = bankV1.refreshToken;
    String? oauthTokenId = accountV1?.oauthTokenId;

    bool oauth = false;

    if (oauthTokenId != null && vault != null) {
      oauth = true;
    } else if(accessToken == null || refreshToken == null) {
      throw Exception("no authentication tokens");
    }

    Map<String, String> newHeaders = {};

    if(headers != null) newHeaders.addAll(headers);
    newHeaders["Authorization"] = "Bearer ${oauth ? "oauthv1_${vault!.id}_$oauthTokenId" : accessToken}";

    return (newHeaders, oauth, refreshToken);
  }

  Future<void> refreshTokens(String? refreshToken) async {
    if (refreshToken == null) {
      throw StateError("No refresh token available");
    }

    final response = await _request(
      method: "GET",
      path: "/auth/refresh",
      headers: {
        "Authorization": "Bearer $refreshToken",
        "Content-Type": "application/json; charset=UTF-8",
      },
    );

    final jsonResponse =
    jsonDecode(response.body);

    if (jsonResponse["err"] != "0") {
      throw StateError('Token refresh failed: ''${jsonResponse["err"]}');
    }

    if (jsonResponse is! Map<String, dynamic>) {
      throw StateError("Invalid response format");
    }

    final bankV1 = banksV1Box.get(encodeKey(bankId: bank.id,));
    if (bankV1 == null) {
      throw StateError("Bank not found",);
    }

    bankV1.accessToken = jsonResponse["access_token"];
    bankV1.refreshToken = jsonResponse["refresh_token"];

    await banksV1Box.put(encodeKey(bankId: bankV1.id), bankV1);
  }

  Future<http.Response> _request({
    required String method,
    required String path,
    Map<String,String>? headers,
    String? body,
  }) async {
    if(onlineApiUrl!.startsWith("gateway://")) {
      final peer = await BBIPeerConnection.getFor(bank.id);

      return peer.request(
        method: method,
        path: path,
        headers: headers,
        body: body,
      );
    }

    final uri = Uri.parse(onlineApiUrl! + path);

    switch(method) {
      case "GET":
        return http.get(
          uri,
          headers:headers,
        );
      case "POST":
        return http.post(
          uri,
          headers:headers,
          body:body,
        );
      default:
        throw UnsupportedError(method);
    }
  }
}

enum BBIPeerConnectionState {
  init,
  starting,
  running,
  dead
}

class BBIPeerConnection {
  final String bankId;

  static final Map<String, BBIPeerConnection> _peerConnections = {};

  BBIPeerConnectionState _state = BBIPeerConnectionState.init;
  late final WebSocketChannel _websocket;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  final List<RTCDataChannelMessage> _pendingMessages = [];
  final Map<String, Completer<http.Response>> _requests = {};

  bool get isDataChannelOpen => _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;
  BBIPeerConnectionState get state => _state;

  late final Uint8List _encapsulationKey;
  late final Uint8List _decapsulationKey;

  late final SecretKeyData _b2cKey;
  late final SecretKeyData _c2bKey;

  BBIPeerConnection._internal({required this.bankId});

  static Future<BBIPeerConnection> getFor(String bankId) async {
    if (_peerConnections.containsKey(bankId)) {
      if(_peerConnections[bankId]!.state != BBIPeerConnectionState.dead) {
        return _peerConnections[bankId]!;
      }
    }

    BBIPeerConnection connection = BBIPeerConnection._internal(bankId: bankId);
    _peerConnections[bankId] = connection;
    await connection.connect();

    return connection;
  }

  Future<void> connect() async {
    _state = BBIPeerConnectionState.starting;

    // create WebSocket connection

    final String sessionId = Uuid().v4();
    var (encapsulationKey, decapsulationKey) = PqcKem.kyber1024.generateKeyPair();
    _encapsulationKey = encapsulationKey; _decapsulationKey = decapsulationKey;

    final wsUri = Uri.parse('wss://gateway.beshence.com:443/api/bank/$bankId/ws?role=client&session_id=$sessionId');
    _websocket = WebSocketChannel.connect(wsUri);
    _websocket.stream.listen((message) async {
      //print("got message! $message");
      final json = jsonDecode(message);

      if(json["type"] == "sh_v1") {
        BeshenceBankPKResponseV1 pks = await Beshence.getBankPublicKeysV1(bankId: bankId);

        Uint8List ciphertext = Uint8List.fromList(rawBase64UrlDecode(json["ct"]));
        Uint8List contextSig = Uint8List.fromList(rawBase64UrlDecode(json["sig"]));

        // check bank id

        var domain = utf8.encode("BESHENCE-BANK-ID-V1");

        final rootPk = Uint8List.fromList(rawBase64UrlDecode(pks.rootPk));

        var message = Uint8List.fromList(<int>[
          ...domain,
          ...rootPk,
        ]);

        final hash = sha256.convert(message);

        final encoded = base32.encode(Uint8List.fromList(hash.bytes));

        final generatedBankId = encoded.replaceAll('=', '').toLowerCase();

        if (generatedBankId != bankId) {
          _state = BBIPeerConnectionState.dead;
          return;
        }

        // check leaf pk

        domain = utf8.encode("BESHENCE-BANK-MLDSA-KEY-V1",);

        final leafPk = Uint8List.fromList(rawBase64UrlDecode(pks.leafPk));
        final sig = Uint8List.fromList(rawBase64UrlDecode(pks.leafSig));

        message = Uint8List.fromList(<int>[
          ...domain,
          ...leafPk,
        ]);

        var valid = SlhDsa.verify(
            rootPk,
            message,
            sig,
            SlhDsaParams.shake256s
        );

        if(!valid) {
          _state = BBIPeerConnectionState.dead;
          return;
        }

        // check encryption context

        domain = utf8.encode(
          "BESHENCE-BANK-SIGNALING-SIGN-CONTEXT-V1",
        );

        message = Uint8List.fromList([
          ...domain,
          ..._encapsulationKey,
          ...ciphertext,
        ]);

        valid = MlDsa.verify(
          leafPk,
          message,
          contextSig,
          DilithiumParams.mlDsa87,
        );

        if(!valid) {
          _state = BBIPeerConnectionState.dead;
          return;
        }

        final sharedSecret = PqcKem.kyber1024.decapsulate(_decapsulationKey, ciphertext);

        final hkdf = Hkdf(
          hmac: Hmac.sha256(),
          outputLength: 32,
        );

        final sessionKey = await hkdf.deriveKey(
          secretKey: SecretKey(sharedSecret),
          info: utf8.encode(
            'BESHENCE-BANK-SIGNALING-SESSION-KEY-V1',
          ),
        );

        _c2bKey = await hkdf.deriveKey(
          secretKey: sessionKey,
          info: utf8.encode(
            'BESHENCE-BANK-SIGNALING-C2B-KEY-V1',
          ),
        );

        _b2cKey = await hkdf.deriveKey(
          secretKey: sessionKey,
          info: utf8.encode(
            'BESHENCE-BANK-SIGNALING-B2C-KEY-V1',
          ),
        );

        await createWebRtcConnection();
      } else if(json["type"] == "ct_v1") {
        await handleSignaling(await decryptSignaling(json));
      } // else ignore
    },
      cancelOnError: true,
      onDone: () async {
        //print('Bank ${bank.id} disconnected');
        _state = BBIPeerConnectionState.dead;
        //final connection = _peerConnections.remove(bank.id);
        //await connection?.close();
      },
      onError: (error) async {
        //print('Bank ${bank.id} ws error: $error');
        _state = BBIPeerConnectionState.dead;
        //final connection = _peerConnections.remove(bank.id);
        //await connection?.close();
      },
    );

    await _websocket.ready;

    sendWebSocket(jsonEncode({
      "type": "ch_v1",
      "ek": rawBase64UrlEncode(_encapsulationKey)
    }));
  }

  Future<void> createWebRtcConnection() async {
    _peerConnection = await createPeerConnection({'iceServers': [
      {'urls': ['stun:stun.l.google.com:19302']}
    ]});

    _peerConnection!.onIceCandidate = (candidate) async {
      String encryptedSignaling = await encryptSignaling(SignalingMessage(
          type: SignalingType.iceCandidate,
          candidate: candidate.candidate,
          sdpMid: candidate.sdpMid,
          sdpmLineIndex: candidate.sdpMLineIndex
      ));

      sendWebSocket(encryptedSignaling);
    };

    _peerConnection!.onConnectionState = (state) {
      switch(state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _state = BBIPeerConnectionState.dead;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateNew:
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          break;
      }
    };

    _dataChannel = await _peerConnection!.createDataChannel("main", RTCDataChannelInit());

    _dataChannel!.onMessage = (message) => handleMessage(message);

    _dataChannel!.onDataChannelState = (state) {
      switch(state) {
        case RTCDataChannelState.RTCDataChannelOpen:
          for (final message in _pendingMessages) {
            _dataChannel!.send(message);
          }
          _pendingMessages.clear();
          break;
        case RTCDataChannelState.RTCDataChannelConnecting:
          break;
        case RTCDataChannelState.RTCDataChannelClosing:
          break;
        case RTCDataChannelState.RTCDataChannelClosed:
          _state = BBIPeerConnectionState.dead;
          break;
      }
    };

    final offer = await _peerConnection!.createOffer({
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': false,
      },
      'optional': []
    });

    await _peerConnection!.setLocalDescription(offer);

    String encryptedOffer = await encryptSignaling(SignalingMessage(
      type: SignalingType.offer,
      sdp: (await _peerConnection!.getLocalDescription())!.sdp,
    ));

    sendWebSocket(encryptedOffer);
  }

  Future<String> encryptSignaling(SignalingMessage message) async {
    final cipher = Chacha20.poly1305Aead();
    final plaintext = utf8.encode(jsonEncode(message.toJson()));

    final box = await cipher.encrypt(
      plaintext,
      secretKey: _c2bKey,
    );

    return jsonEncode({
      "type": "ct_v1",
      "ct": rawBase64UrlEncode(box.cipherText),
      "nonce": rawBase64UrlEncode(box.nonce),
      "mac": rawBase64UrlEncode(box.mac.bytes)
    });
  }

  Future<SignalingMessage> decryptSignaling(Map<String, dynamic> message) async {
    final cipher = Chacha20.poly1305Aead();
    final Uint8List nonce = Uint8List.fromList(rawBase64UrlDecode(message["nonce"]));
    final mac = Mac(rawBase64UrlDecode(message["mac"]));
    final ciphertext = rawBase64UrlDecode(message["ct"]);

    return SignalingMessage.fromJson(
        jsonDecode(utf8.decode(
            await cipher.decrypt(
              SecretBox(
                ciphertext,
                nonce: nonce,
                mac: mac,
              ),
              secretKey: _b2cKey,
            )
        ))
    );
  }

  void sendWebSocket(dynamic message) {
    _websocket.sink.add(message);
  }

  Future<void> handleSignaling(SignalingMessage message) async {
    switch(message.type) {
      case SignalingType.answer:
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(message.sdp, "answer"),
        );
        break;
      case SignalingType.iceCandidate:
        await _peerConnection!.addCandidate(
          RTCIceCandidate(message.candidate, message.sdpMid, message.sdpmLineIndex),
        );
        break;
      default:
        break;
    }
  }

  Future<http.Response> request({
    required String method,
    required String path,
    Map<String,String>? headers,
    String? body,
  }) async {
    final id = const Uuid().v4();
    final completer = Completer<http.Response>();
    _requests[id] = completer;
    sendMessage(RTCDataChannelMessage(
        jsonEncode({
          "type": "request",
          "id": id,
          "method": method,
          "path": path,
          "headers": headers,
          "body": body != null ? rawBase64UrlEncode(utf8.encode(body)) : null,
        })
    ));

    return completer.future;
  }

  void handleResponse(String id, dynamic json) {
    final completer = _requests.remove(id);
    if(completer == null) {
      return;
    }

    completer.complete(
        http.Response(
            utf8.decode(rawBase64UrlDecode(json["body"])),
            json["status"],
            headers: {
              "content-type": "application/json"
            }
        )
    );
  }

  void sendMessage(RTCDataChannelMessage message) {
    if (!isDataChannelOpen) {
      _pendingMessages.add(message);
      return;
    }
    _dataChannel!.send(message);
  }

  void handleMessage(RTCDataChannelMessage message) {
    final String text;

    if (message.isBinary) {
      text = utf8.decode(message.binary);
    } else {
      text = message.text;
    }

    final json = jsonDecode(text);
    final id = json["id"];

    handleResponse(id, json);
  }

  Future<void> disconnect() async {
    await _websocket.sink.close();
    _state = BBIPeerConnectionState.dead;
  }
}

enum SignalingType {
  offer,
  answer,
  iceCandidate,
}

class SignalingMessage {
  final SignalingType type;
  final String? sdp;
  final String? candidate;
  final String? sdpMid;
  final int? sdpmLineIndex;

  SignalingMessage({
    required this.type,
    this.sdp,
    this.candidate,
    this.sdpMid,
    this.sdpmLineIndex
  });


  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    switch (json["type"]) {
      case "offer":
        return SignalingMessage(
          type: SignalingType.offer,
          sdp: json["sdp"],
        );
      case "answer":
        return SignalingMessage(
          type: SignalingType.answer,
          sdp: json["sdp"],
        );
      case "candidate":
        return SignalingMessage(
            type: SignalingType.iceCandidate,
            candidate: json["candidate"],
            sdpMid: json["sdpmid"],
            sdpmLineIndex: json["sdpmlineindex"]
        );
      default:
        throw Exception(
          "Unknown signaling type ${json["type"]}",
        );
    }
  }

  Map<String,dynamic> toJson() {
    return {
      "type": switch(type) {
        SignalingType.offer => "offer",
        SignalingType.answer => "answer",
        SignalingType.iceCandidate => "ice_candidate",
      },
      if(sdp != null) "sdp": sdp,
      if(candidate != null) "candidate": candidate,
      if(sdpMid != null) "sdpmid": sdpMid,
      if(sdpmLineIndex != null) "sdpmlineindex": sdpmLineIndex,
    };
  }
}