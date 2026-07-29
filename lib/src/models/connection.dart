import 'dart:convert';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/models/signaling_message.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


class BeshenceBankConnection {
  static final Map<BeshenceBank, BeshenceBankConnection> _connections = {};

  final BeshenceBank bank;
  late final WebSocketChannel _websocket;
  final List<String> _pendingMessages = [];

  bool get isDataChannelOpen =>
      _dataChannel?.state ==
          RTCDataChannelState.RTCDataChannelOpen;

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  BeshenceBankConnection({
    required this.bank,
  });


  Future<void> connect() async {
    if (_connections.containsKey(bank)) {
      return;
    }
    await _connect();
    _connections[bank] = this;
    return;
  }

  Future<void> disconnect() async {
    final connection = _connections.remove(bank);
    await connection?.close();
  }

  Future<void> _connect() async {
    final String sessionId = Uuid().v4();

    final uri = Uri.parse(
      'wss://gateway.beshence.com/api/bank/${bank.id}/ws?role=client&session_id=$sessionId',
    );

    _websocket = WebSocketChannel.connect(uri);
    await _websocket.ready;

    _websocket.stream.listen((message) async {
      print("got message! $message");
      final json = jsonDecode(message);
      final signal = SignalingMessage.fromJson(json);
      await handleSignaling(signal);
    },
      cancelOnError: true,
      onDone: () async {
        print('Bank ${bank.id} disconnected');
        final connection = _connections.remove(bank);
        await connection?.close();
      },
      onError: (error) async {
        print('Bank ${bank.id} websocket error: $error');
        final connection = _connections.remove(bank);
        await connection?.close();
      },
    );

    _peerConnection = await createPeerConnection({});
    await createDataChannel();
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    sendSignaling(SignalingMessage(
      type: SignalingType.offer,
      sdp: (await _peerConnection!.getLocalDescription())!.sdp,
    ).toJson());

    _peerConnection!.onIceCandidate = (candidate) {
      sendSignaling(SignalingMessage(
          type: SignalingType.iceCandidate,
          candidate: candidate.candidate,
          sdpMid: candidate.sdpMid,
          sdpmLineIndex: candidate.sdpMLineIndex
        ).toJson());
    };
  }

  void sendSignaling(Map<String, dynamic> message) {
    _websocket.sink.add(jsonEncode(message));
  }

  Future<void> createDataChannel() async {
    _dataChannel = await _peerConnection!.createDataChannel("main", RTCDataChannelInit());

    /*_dataChannel!.onMessage = (message) {
      print("BANK DATA: ${message.text}");
    };*/


    _dataChannel!.onDataChannelState =
        (state) {

      print(
          "DataChannel state: $state"
      );

      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        for (final message in _pendingMessages) {

          print("sending");

          _dataChannel!.send(
            RTCDataChannelMessage(message),
          );

        }


        _pendingMessages.clear();
      }

    };

  }

  Future<void> handleSignaling(SignalingMessage message) async {
    switch(message.type) {
      case SignalingType.answer:
        await _peerConnection!
            .setRemoteDescription(
          RTCSessionDescription(
            message.sdp,
            "answer",
          ),
        );
        break;
      case SignalingType.iceCandidate:


        await _peerConnection!
            .addCandidate(
          RTCIceCandidate(message.candidate, message.sdpMid, message.sdpmLineIndex),
        );

        break;


      default:
        break;

    }

  }

  void sendData(String message) {
    if (!isDataChannelOpen) {
      _pendingMessages.add(message);
      return;
    }
    _dataChannel!.send(
      RTCDataChannelMessage(message),
    );
  }

  Future<void> close() async {
    await _websocket.sink.close();
  }
}