import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../allConstants/firestore_constants.dart';

class FirebaseUser extends Equatable{
  final String id;
  final String photoUrl;
  final String displayName;
  final String role;

  const FirebaseUser(
      {required this.id,
      required this.photoUrl,
      required this.displayName,
      required this.role,});
  FirebaseUser copyWith({
    String? id,
    String? photoUrl,
    String? nickname,
    String? role,
  }) =>
      FirebaseUser(
          id: id ?? this.id,
          photoUrl: photoUrl ?? this.photoUrl,
          displayName: nickname ?? displayName,
          role: role ?? this.role,
          );

  Map<String, dynamic> toJson() => {
        FirestoreConstants.displayName: displayName,
        FirestoreConstants.photoUrl: photoUrl,
      };
  factory FirebaseUser.fromDocument(DocumentSnapshot snapshot) {
    String photoUrl = "";
    String nickname = "";
    String role = "person";


    try {
      photoUrl = snapshot.get(FirestoreConstants.photoUrl);
      nickname = snapshot.get(FirestoreConstants.displayName);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return FirebaseUser(
        id: snapshot.id,
        photoUrl: photoUrl,
        displayName: nickname,
        role: role,);
  }
  @override
  // TODO: implement props
  List<Object?> get props => [id, photoUrl, displayName,role];

}