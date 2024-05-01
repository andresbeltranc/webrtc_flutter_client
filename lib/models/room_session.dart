import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webrtc_platform/allConstants/all_constants.dart';

class RoomSession {

  String roomId;
  String roomName;

  RoomSession({
    required this.roomId,
    required this.roomName
  });
    Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.roomId: roomId,
      FirestoreConstants.roomName: roomName,
    };
  }
  factory RoomSession.fromDocument(DocumentSnapshot documentSnapshot) {
    String roomId = documentSnapshot.id;
    String roomName = documentSnapshot.get(FirestoreConstants.roomName);

    return RoomSession(
        roomId: roomId,
        roomName: roomName);
  }
}