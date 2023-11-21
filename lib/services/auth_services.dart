import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//// Google Sign in
  Future<void> hangleSignIn() async {
    try {
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if(googleUser != null) {
        GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await _auth.signInWithCredential(credential);

        // Firestore에 유저 데이터 저장
        await _saveUserToFirestore(userCredential.user!);
      }
    } catch (e){
      print("Error signing in with google $e");
    }
  }
  ///google sign out function
  Future<void> handleSignOut() async {
    try{
      await _googleSignIn.signOut();
      await _auth.signOut();
    }catch(e){
      print("error signing out :$e");
    }
  }
  Future<void> _saveUserToFirestore(User user) async {
    // users 컬렉션에 유저 데이터 저장
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'nickname' : null,
      'gameImageURL' : null,
    }, SetOptions(merge: true));  // merge: true를 사용하여 이미 존재하는 데이터를 덮어쓰지 않습니다.
  }
}