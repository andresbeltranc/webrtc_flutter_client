import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webrtc_platform/allConstants/all_constants.dart';

class RoomProvider{
  final FirebaseFirestore firebaseFirestore;
  RoomProvider({required this.firebaseFirestore});
  Future<void> updateFirestoreData(
      String collectionPath, String path, Map<String, dynamic> updateData) {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(path)
        .update(updateData);
  }
  Stream<QuerySnapshot> getFirestoreData(String collectionPath, int limit, String? textSearch) {
    if (textSearch?.isNotEmpty == true) {
      return firebaseFirestore
          .collection(collectionPath)
          .limit(limit)
          .where(FirestoreConstants.roomName, isEqualTo: textSearch)
          .snapshots();
    } else {
      return firebaseFirestore
          .collection(collectionPath)
          .limit(limit)
          .snapshots();
    }
  }
  Future<void> createRoom(String roomName, String currentUserId )async{
    CollectionReference roomRef = firebaseFirestore.collection('rooms');
    roomRef.add({"roomName":roomName, "hostUserId":currentUserId,"hostCalling":false,"callStateClient":'closed_com', "callStatePlatform":'closed_com'});
  }
}