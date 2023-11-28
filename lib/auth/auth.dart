import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latter_pracj/UI/home_page.dart';
import 'package:latter_pracj/auth/NicknameSetupPage.dart';
import 'package:latter_pracj/auth/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            // 로그인한 사용자의 정보를 Firestore에서 확인
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.data != null && userSnapshot.data!.exists) {
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  if (userData['nickname'] == null || userData['photoURL'] == null) {
                    // 프로필 정보가 미완성인 경우
                    return NicknameSetupPage();
                  } else {
                    // 프로필 정보가 완성된 경우
                    return HomePage();
                  }
                } else {
                  // Firestore에서 사용자 데이터를 찾을 수 없는 경우
                  return LoginPage();
                }
              },
            );
          } else {
            // 로그인하지 않은 경우
            return LoginPage();
          }
        },
      ),
    );
  }
}