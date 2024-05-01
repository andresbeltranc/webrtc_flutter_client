import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webrtc_platform/allConstants/all_constants.dart';

class ChatMessages {
  String roomId;
  String idFrom;
  String timestamp;
  String content;
  bool readByClient;
  int type;

  ChatMessages(
      {required this.roomId,
      required this.idFrom,
      required this.timestamp,
      required this.content,
      required this.type,
      required this.readByClient});

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.roomId: roomId,
      FirestoreConstants.idFrom: idFrom,
      FirestoreConstants.timestamp: timestamp,
      FirestoreConstants.content: content,
      FirestoreConstants.type: type,
      FirestoreConstants.readByClient: readByClient
    };
  }

  factory ChatMessages.fromDocument(DocumentSnapshot documentSnapshot) {
    String idFrom = documentSnapshot.get(FirestoreConstants.idFrom);
    String roomId = documentSnapshot.get(FirestoreConstants.roomId);
    String timestamp = documentSnapshot.get(FirestoreConstants.timestamp);
    String content = documentSnapshot.get(FirestoreConstants.content);
    int type = documentSnapshot.get(FirestoreConstants.type);
    bool readByClient = documentSnapshot.get(FirestoreConstants.readByClient);

    return ChatMessages(
        idFrom: idFrom,
        roomId: roomId,
        timestamp: timestamp,
        content: content,
        type: type,
        readByClient: readByClient);
  }
}