## Requirements
- Flutter SDK
- Firebase CLI
- Git
- Android Studio or Visual Studio Code 
- Node.js (NPM) 

## Firebase
webrtc platform use Firebase for real time communication with Client App and database. To achieve this proposes webrtc-Platform use Firebase Authentication and Firestore Database services.

### Firebase Account 
To be able to use all the services of Firebase you will need an account that is going to be provided for the person in charge of the project. 

1. After create a Firebase account or login in an existing one you will need to create a project.

### Firebase Services
In the case that you will need to create a new account or re-create the Firebase services in that account you have to follow the following steps:

2. Create a **Firebase Authentication** service
    1. enable Google Sign-in method
        1. Create a public project name.
        2. Select the account email as support email
3. Create the **Firestore Database** service.

# Getting Started

1. After clone the project from GitHub repository you will need to get all the dependencies using the following command:`flutter pub get` in the source file of the project to download all the libraries dependencies of the project.

2. Make sure that the project is using the following permitions in android:
    - Camera.
    - Microphone. 
    - Internet connection.

3. If is the first time that you compile the project you will have to do the following steps:
    1. Open a CMD window in the root of the project you will have to verify your credentials of Firebase using the Firebase CLI command : `firebase login` (this step could throw problems if you don't install the Firebase CLI with node.js using npm. To install the Firebase CLI use the following command `npm install -g firebase-tools`).
    2. After verify the Firebase account execute the following command: `dart pub global activate flutterfire_cli`. This command activated the FlutterFire CLI.
    3. Next run this command and choose the Firebase project that you created: `flutterfire configure`. This command enables that our flutter application has the ability to communicate with our Firebase Cloud services.
    4. Finally, you have to go to the android folder that is inside the project and open a shell and execute the following command `gradlew signingReport` and copy the sha-1 and sha-256 fingerprints and add them to the project settings inside your Firebase project, under Android App. This process enables a secure Authentication with the Firebase Authentication Service.

4. Configure your android emulator or device and compile the project.


# Deployment
To create the APK of webrtc-plaform you have to compile the project in debug mode for some problems with the flutter WebRTC library. To compile the project you have to execute the following command: `flutter build apk --debug` in the root of the project. The APK file will be located at build/app/outputs/flutter-apk/app-debug.apk inside your project directory. 



