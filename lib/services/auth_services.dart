import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google 로그인 처리
  Future<void> handleSignIn() async {
    try {
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await _auth.signInWithCredential(credential);

        // Firestore에 유저 데이터 저장
        await _saveUserToFirestore(userCredential.user!);
      }
    } catch (e) {
      print("Error signing in with google: $e");
    }
  }

  // Google 로그아웃 처리
  Future<void> handleSignOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Firestore에 유저 데이터 저장
  Future<void> _saveUserToFirestore(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      //'photoURL': user.photoURL,
    }, SetOptions(merge: true));
  }

  // 프로필 업데이트 메소드
  Future<void> updateProfile(String uid, String nickname, String photoURL) async {
    await _firestore.collection('users').doc(uid).update({
      'nickname': nickname,
      'photoURL': photoURL,
    });
  }
  Future<void> updateNickname(String uid, String nickname) async {
    await _firestore.collection('users').doc(uid).update({
      'nickname': nickname,
    });
  }
  Future<void> updateUserProfile(String uid, String photoURL) async {
    await _firestore.collection('users').doc(uid).update({
      'photoURL': photoURL,
    });
  }
}
