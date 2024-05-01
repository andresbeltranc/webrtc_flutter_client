import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:webrtc_platform/models/room_session.dart';
import 'package:webrtc_platform/pages/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:webrtc_platform/allConstants/all_constants.dart';
import 'package:webrtc_platform/widgets/loading_view.dart';

import '../models/firebase_user.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/room_provider.dart';

import '../utilities/debouncer.dart';
import '../utilities/keyboard_utils.dart';
import 'chat_page.dart';
import 'login_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController scrollController = ScrollController();
  int _limit = 20;
  final int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;
  late AuthProvider authProvider;
  late String currentUserId;
  late HomeProvider homeProvider;
  late RoomProvider roomProvider;
  Debouncer searchDebouncer = Debouncer(milliseconds: 300);
  StreamController<bool> buttonClearController = StreamController<bool>();
  TextEditingController searchTextEditingController = TextEditingController();
  Future<void> googleSignOut() async {
    authProvider.googleSignOut();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }
  
  Future<void> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return SimpleDialog(
            backgroundColor: Color.fromARGB(255, 99, 35, 124),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Exit Application',
                  style: TextStyle(color: AppColors.white),
                ),
                Icon(
                  Icons.exit_to_app,
                  size: 30,
                  color: Colors.white,
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Sizes.dimen_10),
            ),
            children: [
              vertical10,
              const Text(
                'Are you sure?',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.white, fontSize: Sizes.dimen_16),
              ),
              vertical15,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, 0);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, 1);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Sizes.dimen_8),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: const Text(
                        'Yes',
                        style: TextStyle(color: AppColors.spaceCadet),
                      ),
                    ),
                  )
                ],
              )
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }
   Future<void> openDialogCreateRoom() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          TextEditingController displayNameController = TextEditingController();
          final FocusNode focusNodeRoomName = FocusNode();
          String RoomName = '';
        
          return AlertDialog(
            title: const Text("Create Room",
              style: TextStyle(color: AppColors.indyBlue),
              textAlign: TextAlign.center,
            ),
            content: TextField(
              controller: displayNameController,
              decoration: const InputDecoration(hintText: "Enter Name"),
            ),
            actions:<Widget>[
              ElevatedButton(onPressed:(){ Navigator.pop(context, 0);},
                child: const Text("Cancel"),
                ),
              ElevatedButton(onPressed:(){ 
                roomProvider.createRoom(displayNameController.text,currentUserId);
                Navigator.pop(context, 0);             
              },
                child:  const Text("Create"),
                ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  void scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    buttonClearController.close();
  }

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();
    roomProvider = context.read<RoomProvider>();
    if (authProvider.getFirebaseUserId()?.isNotEmpty == true) {
      currentUserId = authProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false);
    }

    scrollController.addListener(scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: const Text('Sesiones'),
            actions: [
              IconButton(
                  onPressed: () => googleSignOut(),
                  icon: const Icon(Icons.logout)),
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()));
                  },
                  icon: const Icon(Icons.person)),
            ]),
        body: WillPopScope(
          onWillPop: onBackPress,
          child: Stack(
            children: [
              Scaffold(
                body: Center( 
                  child:Column(
                    children: [
                      buildSearchBar(),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: roomProvider.getFirestoreData(
                              FirestoreConstants.pathRoomCollection,
                              _limit,
                              _textSearch),
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.hasData) {
                              if ((snapshot.data?.docs.length ?? 0) > 0) {
                                return ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) => buildItem(
                                      context, snapshot.data?.docs[index]),
                                  controller: scrollController,
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          const Divider(),
                                );
                              } else {
                                return const Center(
                                  child: Text('No user found...'),
                                );
                              }
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                ),                
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: openDialogCreateRoom,
                tooltip: 'Create Room',
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.add),
              ),

      ),

              Positioned(
                child:          
                    isLoading ? const LoadingView() : const SizedBox.shrink(),
              ),
            ],
          ),
        ));
  }

  Widget buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(Sizes.dimen_10),
      height: Sizes.dimen_50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Sizes.dimen_30),
        color: AppColors.spaceLight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: Sizes.dimen_10,
          ),
          const Icon(
            Icons.person_search,
            color: AppColors.white,
            size: Sizes.dimen_24,
          ),
          const SizedBox(
            width: 5,
          ),
          Expanded(
            child: TextFormField(
              textInputAction: TextInputAction.search,
              controller: searchTextEditingController,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  buttonClearController.add(true);
                  setState(() {
                    _textSearch = value;
                  });
                } else {
                  buttonClearController.add(false);
                  setState(() {
                    _textSearch = "";
                  });
                }
              },
              decoration: const InputDecoration.collapsed(
                hintText: 'Search here...',
                hintStyle: TextStyle(color: AppColors.white),
              ),
            ),
          ),
          StreamBuilder(
              stream: buttonClearController.stream,
              builder: (context, snapshot) {
                return snapshot.data == true
                    ? GestureDetector(
                        onTap: () {
                          searchTextEditingController.clear();
                          buttonClearController.add(false);
                          setState(() {
                            _textSearch = '';
                          });
                        },
                        child: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.greyColor,
                          size: 20,
                        ),
                      )
                    : const SizedBox.shrink();
              })
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot? documentSnapshot) {
    final firebaseAuth = FirebaseAuth.instance;
    if (documentSnapshot != null) {
      RoomSession roomSession = RoomSession.fromDocument(documentSnapshot);
      return TextButton(
        onPressed: (){
          if(KeyboardUtils.isKeyboardShowing()){
            KeyboardUtils.closeKeyboard(context);
          }
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ChatPage(
                roomId: roomSession.roomId,   
                userAvatar: firebaseAuth.currentUser!.photoURL!,
              )
            )
          );         
        },
        child: ListTile(
          leading: const Icon(Icons.message),
          title: Text(roomSession.roomName,
              style: const TextStyle(color: Colors.black),
            ),
          subtitle: Text(roomSession.roomId) ,
          trailing: const Icon(Icons.copy_all),
          ),
      );    
    } else {
      return const SizedBox.shrink();
    }
  }
}