import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webrtc_platform/allConstants/all_constants.dart';
import 'package:webrtc_platform/models/chat_messages.dart';

class ChatProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  ChatProvider(
      {required this.prefs,
      required this.firebaseStorage,
      required this.firebaseFirestore});

  UploadTask uploadImageFile(File image, String filename) {
    Reference reference = firebaseStorage.ref().child(filename);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateFirestoreData(
      String collectionPath, String docPath, Map<String, dynamic> dataUpdate) {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(docPath)
        .update(dataUpdate);
  }

Future<String> getUserImage(String userId) async {
  var docRef = firebaseFirestore.collection(FirestoreConstants.pathUserCollection);
  var docSnapshot = await docRef.doc(userId).get();
  Map<String, dynamic>? data = docSnapshot.data();
  //print(value);
  return Future.value(data?["photoUrl"]);
  
  // docRef.get().then((DocumentSnapshot doc){
  //   final data = doc.data() as Map<String, dynamic>;
  //   print(data['photoUrl']);
  // });

  // return firebaseFirestore
  //       .collection(FirestoreConstants.pathUserCollection)
  //       .doc(userId)
  //       .get("photoUrl")
  //       .toString();
}

Future<String> getUserName(String userId) async {
  var docRef = firebaseFirestore.collection(FirestoreConstants.pathUserCollection);
  var docSnapshot = await docRef.doc(userId).get();
  Map<String, dynamic>? data = docSnapshot.data();
  //print(value);
  return Future.value(data?["displayName"]);
}


  Stream<QuerySnapshot> getChatMessage(String roomId, int limit) {
    return firebaseFirestore
        .collection(FirestoreConstants.pathRoomCollection)
        .doc(roomId)
        .collection(FirestoreConstants.pathMessageCollection)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }
  
  void sendChatMessage(String content, int type, String roomId, String currentUserId) {
    DocumentReference documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathRoomCollection)
        .doc(roomId)
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());
    ChatMessages chatMessages = ChatMessages(
        roomId: roomId,
        idFrom: currentUserId,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        type: type,
        readByClient:false);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(documentReference, chatMessages.toJson());
    });
  }
}

class MessageType {
  static const text = 0;
  static const image = 1;
  static const sticker = 2;
}