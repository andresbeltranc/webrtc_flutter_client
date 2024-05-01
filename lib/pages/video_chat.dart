import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../allConstants/all_constants.dart';
import '../allConstants/firestore_constants.dart';
import '../allConstants/size_constants.dart';
import '../models/signaling.dart';
import '../providers/chat_provider.dart' as chatProviderRef;

class VideoChatPage extends StatefulWidget{
  final String roomId;
  final String currentUserId;
  final bool host;

  const VideoChatPage({Key?key, required this.roomId, required this.currentUserId, required this.host}): super(key:key);
  
  @override
  State<StatefulWidget> createState() => _VideoChatPage();

}

class _VideoChatPage extends State<VideoChatPage>{
  Signaling signaling = Signaling();
  final  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late bool _isLoading;
  String callStateClient = '';
  bool callingInProccess = false;
  bool tryToCallPeer = false;
  Timer? timer;
  late StreamSubscription<DocumentSnapshot<Map<String,dynamic>>> callStateClientListener;

  late chatProviderRef.ChatProvider chatProvider;
  var isListening = false;
  var finalText = "";
  var partialText = "";
  SpeechToText speechToText = SpeechToText();


  @override
  void initState(){
    _remoteRenderer.initialize();
    checkMicrophoneAvailability();
    chatProvider = context.read<chatProviderRef.ChatProvider>();  
    _isLoading = true;
    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      print("@ Receive remote Stream");
      setState(() {});
    });



    dummyFunction();
    super.initState();
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

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      chatProvider.sendChatMessage( content, type, widget.roomId, widget.currentUserId);
    } 
  }

void validateCallState(){

  if(callingInProccess == false){
      var roomsRef = chatProvider.firebaseFirestore.collection(FirestoreConstants.pathRoomCollection).doc(widget.roomId);
      signaling.hangUp(widget.roomId);
      roomsRef.update({'callStatePlatform':'closed_com','hostCalling':false});
      timer?.cancel();
      Navigator.pop(context);
  }
}
void dummyFunction() async{
      //await signaling.openUserMedia(_localRenderer,_remoteRenderer);
      var roomsRef = chatProvider.firebaseFirestore.collection(FirestoreConstants.pathRoomCollection).doc(widget.roomId);

      await signaling.createOffer(widget.roomId);
      roomsRef.update({'callStatePlatform':'connecting_com'});
      timer = Timer.periodic(const Duration(seconds: 20), (Timer t) => validateCallState());

      setState(() {
        tryToCallPeer = true;
      });
      signaling.peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
        print('@ Connection state change: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected){
          callingInProccess = true;  
          _isLoading = false;  
          roomsRef.update({'callStatePlatform':'started_com'});
          setState(() {});


        }
        else if(state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting){

        }
        else if(state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected){
          signaling.hangUp(widget.roomId);
          roomsRef.update({'callStatePlatform':'disc_com'});
          //callingInProccess = false; 
         // tryToCallPeer = false;

        }
        else if(state == RTCPeerConnectionState.RTCPeerConnectionStateFailed){
          signaling.hangUp(widget.roomId);
          roomsRef.update({'callStatePlatform':'failed_com'});
          //callingInProccess = false; 
          //tryToCallPeer = false;
        }
        else if(state == RTCPeerConnectionState.RTCPeerConnectionStateClosed){
          signaling.hangUp(widget.roomId);
          roomsRef.update({'callStatePlatform':'closed_com'});
          callingInProccess = false; 
          tryToCallPeer = false;

        }
      };

    signaling.peerConnection?.onAddStream = (MediaStream stream) {
      print("@ Add remote stream");
      signaling.onAddRemoteStream?.call(stream);
      signaling.remoteStream = stream;
    };


    
    callStateClientListener = roomsRef.snapshots().listen((event) { 
      Map<String, dynamic>? data = event.data();
      if(callingInProccess){
        if(data?["callStateClient"] == "closed_com" || data?["callStateClient"] == "disc_com" || data?["callStateClient"] == "failed_com" ){       
            signaling.hangUp(widget.roomId);
            callingInProccess = false;
            Navigator.pop(context);      
        }
      }
    });
    setState(() {});
    

}


  @override
  void dispose() {
    print("@ dispose Video Chat Page ${callingInProccess} or try call peer ${tryToCallPeer}");
    if(callingInProccess || tryToCallPeer){
      var roomsRef = chatProvider.firebaseFirestore.collection(FirestoreConstants.pathRoomCollection).doc(widget.roomId);
      signaling.hangUp(widget.roomId);
      roomsRef.update({'callStatePlatform':'closed_com','hostCalling':false});
      callStateClientListener.cancel();
    }
    _remoteRenderer.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

   // if(widget.host){
      return Scaffold(
          body: Stack(
           // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading ? const Center(child:CircularProgressIndicator()):Expanded(
                
                child: RTCVideoView( objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,_remoteRenderer)),
              _isLoading ? const SizedBox(width: double.infinity,height: 5) :

              Stack(
                children:[
                  Container(
                    alignment: FractionalOffset.bottomCenter,
                    padding: const EdgeInsets.all(5),
                    child:
                      GestureDetector(                                   
                  child: Container(  
                    height: 50,   
                    width: 50,
                  margin: const EdgeInsets.only(left: Sizes.dimen_4),
                  decoration: BoxDecoration(
                    color: isListening ? Colors.red : AppColors.spaceLight,
                    borderRadius: BorderRadius.circular(Sizes.dimen_30),
                  ),
                  child: Icon(color: AppColors.white, (isListening ? Icons.mic_off :Icons.mic)),
                ),
                onTap:() async  {
                  print("Press speak to text started");
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
                          partialText = result.recognizedWords;
                          if(result.finalResult){
                            finalText = result.recognizedWords;
                            onSendMessage(finalText, chatProviderRef.MessageType.text);
                            setState(() {isListening = false;});
                            partialText = '';
                          }                    
                        });
                      });
                    }
                  }
                  else if(isListening){
                    if(partialText != ""){
                      onSendMessage(partialText, chatProviderRef.MessageType.text);
                      partialText = '';
                    }
                  } 
                
                },
            )
                  ),

                ]
              )
        ]),
      );   
  }
}