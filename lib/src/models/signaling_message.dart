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