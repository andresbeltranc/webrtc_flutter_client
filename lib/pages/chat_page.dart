import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:webrtc_platform/pages/video_chat.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webrtc_platform/allConstants/all_constants.dart';
import 'package:webrtc_platform/widgets/common_widgets.dart';
import 'package:webrtc_platform/models/chat_messages.dart';
import 'package:webrtc_platform/providers/auth_provider.dart';
import 'package:webrtc_platform/providers/chat_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:webrtc_platform/pages/login_page.dart';

class ChatPage extends StatefulWidget {
  final String roomId;
  final String userAvatar;

  const ChatPage(
      {Key? key,
      required this.roomId,
      required this.userAvatar})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String currentUserId;

  List<QueryDocumentSnapshot> listMessages = [];

  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId = '';

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = '';

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;
  var isListening = false;
  var finalText = "";
  var partialText = "";

  SpeechToText speechToText = SpeechToText();


  @override
  void initState() {
    super.initState();
    checkMicrophoneAvailability();

    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    focusNode.addListener(onFocusChanged);
    scrollController.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  // Future<void> listenToCallingFromHost()async{
  //   FirebaseFirestore db = FirebaseFirestore.instance;
  //   var currentRoomRef = db.collection(FirestoreConstants.pathRoomCollection);
  //   var docSnapshot = await currentRoomRef.doc(widget.roomId).get();
  //   Map<String, dynamic>? data = docSnapshot.data();

  //   if(currentUserId != data?["hostUserId"]){
  //     var roomRef = db.collection(FirestoreConstants.pathRoomCollection).doc(widget.roomId);
  //     roomRef.snapshots().listen((event) { 
  //       print("current data : ${event.data()}");

  //     },
  //     onError: (error){
  //       print("error : ${error}");
  //     }
  //     );
  //   }
  // }


  void onFocusChanged() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void readLocal() {
    if (authProvider.getFirebaseUserId()?.isNotEmpty == true) {
      currentUserId = authProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false);
    }
    // if (currentUserId.compareTo(widget.peerId) > 0) {
    //   groupChatId = '$currentUserId - ${widget.peerId}';
    // } else {
    //   groupChatId = '${widget.peerId} - $currentUserId';
    // }
    // chatProvider.updateFirestoreData(FirestoreConstants.pathUserCollection,
    //     currentUserId, {FirestoreConstants.chattingWith: widget.peerId});
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future<bool> onBackPressed() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateFirestoreData(FirestoreConstants.pathUserCollection,
          currentUserId, {FirestoreConstants.chattingWith: null});
    }
    return Future.value(false);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;
    pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadImageFile();
      }
    }
  }
  
  void uploadImageFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadImageFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, MessageType.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendChatMessage(
          content, type, widget.roomId, currentUserId);
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send', backgroundColor: Colors.grey);
    }
  }

  // checking if received message
  bool isMessageReceived(int index) {
    if ((index > 0 &&
            listMessages[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  // checking if sent message
  bool isMessageSent(int index) {
    if ((index > 0 &&
            listMessages[index - 1].get(FirestoreConstants.idFrom) !=
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Chat'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.dimen_8),
          child: Column(
            children: [
              buildListMessage(),
              buildMessageInput(),
              const SizedBox(width: double.infinity,height: 5)

             // buildModalCallingMsg()
            ],
          ),
        ),
      ),
    );
  }

  void checkMicrophoneAvailability() async {
    bool available = await speechToText.initialize();


// Some UI or other code to select a locale from the list
// resulting in an index, selectedLocale

    //var selectedLocale = locales[2];
    if (available) {
      setState(() {
        if (kDebugMode) {
          print('Microphone available: $available');
        }
      });
    } else {
      if (kDebugMode) {
        print("The user has denied the use of speech recognition.");
      }
    }
  }
  Widget buildMessageInput() {

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: Sizes.dimen_4),
            decoration: BoxDecoration(
              color: AppColors.indyBlue,
              borderRadius: BorderRadius.circular(Sizes.dimen_30),
            ),
            child: StreamBuilder(
              stream:FirebaseFirestore.instance.collection(FirestoreConstants.pathRoomCollection).doc(widget.roomId).snapshots() ,
              builder: ((context, snapshot) {
                Map<String, dynamic>? data = snapshot.data?.data();
                return IconButton(
                  onPressed: (){
                    FirebaseFirestore db = FirebaseFirestore.instance;     
                    var roomRef = db.collection(FirestoreConstants.pathRoomCollection).doc(widget.roomId);  
                    roomRef.update({'hostCalling':true});
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => VideoChatPage(
                          roomId: widget.roomId,
                          currentUserId: authProvider.getFirebaseUserId()!, 
                          host: true,  
                        )
                      )
                    );         
                  }, 
                  icon: const Icon(
                    Icons.video_call_rounded,
                    size: Sizes.dimen_28,
                  ),
                  color: AppColors.white,
                );
              
              })     
            ),        
          ),         
          Flexible(child: TextField(
            focusNode: focusNode,
            textInputAction: TextInputAction.send,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: textEditingController,
            decoration:
                kTextInputDecoration.copyWith(hintText: 'write here...'),
            onSubmitted: (value) {
              onSendMessage(textEditingController.text, MessageType.text);
            },
          )),
          GestureDetector(
              child: Container(  
                height: 50,   
                width: 50,           
                margin: const EdgeInsets.only(left: Sizes.dimen_4),
                decoration: BoxDecoration(
                  color: isListening ? Colors.red : AppColors.spaceLight,
                  borderRadius: BorderRadius.circular(Sizes.dimen_30),
                ),
                child: Icon(color: AppColors.white, (isListening ? Icons.mic :Icons.send_rounded)),
              ),
              onTap: () {
                onSendMessage(textEditingController.text, MessageType.text);
              },
              onLongPress:() async  {
                print("Long Press speak to text started");
                finalText = "";
                partialText = "";
                if (!isListening) {
                  var available = await speechToText.initialize();
                  
                  if (available) {
                    setState(() {
                      isListening = true;
                    });
                    speechToText.listen(
                        listenFor: const Duration(days: 7),
                        listenMode: ListenMode.confirmation,                       
                        onResult: (result) {
                        setState(() {                   
                        if(result.finalResult){
                          finalText = result.recognizedWords;
                          onSendMessage(finalText, MessageType.text);
                        }                    
                      });
                    });
                  }
                } 
              },
              onLongPressEnd: (details) {
                setState(() {
                    isListening = false;
                });
                speechToText.stop();
              },
            )    
        ],
      ),
    );
  }

  Widget buildItem(int index, DocumentSnapshot? documentSnapshot) {
    if (documentSnapshot != null) {
      ChatMessages chatMessages = ChatMessages.fromDocument(documentSnapshot);

     // var  myFuture = Provider.of<ChatProvider>(context).getUserImage(chatMessages.idFrom);
     // var idUP =  chatProvider.getUserImage(chatMessages.idFrom);
      if (chatMessages.idFrom == currentUserId) {
        // right side (my message)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                chatMessages.type == MessageType.text
                    ? messageBubble(chatContent: chatMessages.content, color: AppColors.spaceLight,textColor: AppColors.white, margin: const EdgeInsets.only(right: Sizes.dimen_10),)
                    : chatMessages.type == MessageType.image ? Container(margin: const EdgeInsets.only(right: Sizes.dimen_10, top: Sizes.dimen_10), child: chatImage(imageSrc: chatMessages.content, onTap: () {}),) : const SizedBox.shrink(),
                    // Container(
                    //     clipBehavior: Clip.antiAlias,
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(Sizes.dimen_20),
                    //     ),
                    //     child: Image.network(
                    //       widget.userAvatar,
                    //       width: Sizes.dimen_30,
                    //       height: Sizes.dimen_30,
                    //       fit: BoxFit.cover,
                    //       loadingBuilder: (BuildContext ctx, Widget child,
                    //           ImageChunkEvent? loadingProgress) {
                    //         if (loadingProgress == null) return child;
                    //         return Center(
                    //           child: CircularProgressIndicator(
                    //             color: AppColors.burgundy,
                    //             value: loadingProgress.expectedTotalBytes !=
                    //                         null &&
                    //                     loadingProgress.expectedTotalBytes !=
                    //                         null
                    //                 ? loadingProgress.cumulativeBytesLoaded /
                    //                     loadingProgress.expectedTotalBytes!
                    //                 : null,
                    //           ),
                    //         );
                    //       },
                    //       errorBuilder: (context, object, stackTrace) {
                    //         return const Icon(
                    //           Icons.account_circle,
                    //           size: 35,
                    //           color: AppColors.greyColor,
                    //         );
                    //       },
                    //     ),
                    //   )

              ],
            ),
            Container(
                    margin: const EdgeInsets.only(
                        right: Sizes.dimen_50,
                        top: Sizes.dimen_6,
                        bottom: Sizes.dimen_8),
                    child: Text("yo - "+
                       DateFormat('dd MMM yyyy, hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          int.parse(chatMessages.timestamp),
                        ),
                      ),
                      style: const TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: Sizes.dimen_12,
                          fontStyle: FontStyle.italic),
                    ),
                  )
          ],
        );
      } else {

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                //isMessageReceived(index)
                    // left side (received message)
                   // ? 
                FutureBuilder(
                  future:chatProvider.getUserImage(chatMessages.idFrom),
                  builder: (BuildContext context, AsyncSnapshot<String> imageUrl){                 
                    return Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Sizes.dimen_20),
                      ),
                      child: Image.network(
                        imageUrl.data.toString(),//getUserImage(chatMessages.idFrom),
                        width: Sizes.dimen_30,
                        height: Sizes.dimen_30,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext ctx, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.burgundy,
                              value: loadingProgress.expectedTotalBytes !=
                                          null &&
                                      loadingProgress.expectedTotalBytes !=
                                          null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, object, stackTrace) {
                          return const Icon(
                            Icons.account_circle,
                            size: 35,
                            color: AppColors.greyColor,
                          );
                        },
                      ), 
                    );
                  },                    
                ),                           
                chatMessages.type == MessageType.text
                    ? messageBubble(
                        color: AppColors.burgundy,
                        textColor: AppColors.white,
                        chatContent: chatMessages.content,
                        margin: const EdgeInsets.only(left: Sizes.dimen_10),
                      )
                    : chatMessages.type == MessageType.image
                        ? Container(
                            margin: const EdgeInsets.only(
                                left: Sizes.dimen_10, top: Sizes.dimen_10),
                            child: chatImage(
                                imageSrc: chatMessages.content, onTap: () {}),
                          )
                        : const SizedBox.shrink(),
              ],
            ),
            FutureBuilder(future: chatProvider.getUserName(chatMessages.idFrom),
              builder:(BuildContext context, AsyncSnapshot<String> userName){
                return Container(
                  margin: const EdgeInsets.only(
                      left: Sizes.dimen_50,
                      top: Sizes.dimen_6,
                      bottom: Sizes.dimen_8),
                  child: Text("${userName.data} - ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(int.parse(chatMessages.timestamp),),)}",
                    style: const TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: Sizes.dimen_12,
                        fontStyle: FontStyle.italic),
                  ),
                );
              },              
            )               
          ],
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  // Widget buildModalCallingMsg(){

  //   return StreamBuilder(
  //       stream:FirebaseFirestore.instance.collection(FirestoreConstants.pathRoomCollection).doc(widget.roomId).snapshots() ,
  //       builder: ((context, snapshot) {
  //         Map<String, dynamic>? data = snapshot.data?.data();
  //         FirebaseFirestore db = FirebaseFirestore.instance;     
  //         var roomRef = db.collection(FirestoreConstants.pathRoomCollection).doc(widget.roomId);

  //         if(data?["hostUserId"] != currentUserId){
  //           if(data?["hostCalling"] == true){
  //             return AlertDialog(
  //               title: const Text("Host is Calling",
  //                 style: TextStyle(color: AppColors.indyBlue),
  //                 textAlign: TextAlign.center,
  //               ),
  //               content: const Text("answer the call",),
  //               actions:<Widget>[
  //                 ElevatedButton(onPressed:(){     
  //                   roomRef.update({'hostCalling':false});
  //                 },
  //                   child: const Text("hang up"),
  //                   ),
  //                 ElevatedButton(onPressed:(){ 
  //                   Navigator.push(
  //                     context, 
  //                     MaterialPageRoute(
  //                       builder: (context) => (VideoChatPage(
  //                         roomId: widget.roomId, 
  //                         currentUserId: currentUserId,
  //                         host: false,
  //                         )
  //                       )
  //                     )
  //                   ); 
  //                 },
  //                   child:  const Text("answer"),
  //                 ),
  //               ],
  //             );            
  //           }
  //         }
  //         return const SizedBox.shrink();
  //       })     
  //     );

  // }


  Widget buildListMessage() {
    return Flexible(
      child: widget.roomId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatMessage(widget.roomId, _limit),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessages = snapshot.data!.docs;
                  if (listMessages.isNotEmpty) {
                    return ListView.builder(
                        padding: const EdgeInsets.all(1),
                        itemCount: snapshot.data?.docs.length,
                        reverse: true,
                        controller: scrollController,
                        itemBuilder: (context, index) =>
                            buildItem(index, snapshot.data?.docs[index]));
                  } else {
                    return const Center(
                      child: Text('No messages...'),
                    );
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.burgundy,
                    ),
                  );
                }
              })
          : const Center(
              child: CircularProgressIndicator(
                color: AppColors.burgundy,
              ),
            ),
    );
  }
}