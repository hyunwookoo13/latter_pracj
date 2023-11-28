import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latter_pracj/UI/home_page.dart';
import 'ProfilePhotoSetupPage.dart'; // 프로필 사진 설정 페이지 import

class NicknameSetupPage extends StatefulWidget {
  @override
  _NicknameSetupPageState createState() => _NicknameSetupPageState();
}

class _NicknameSetupPageState extends State<NicknameSetupPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateNickname() async {
    String nickname = _nicknameController.text.trim(); // 공백 제거

    if (nickname.isNotEmpty) {
      // Firestore에서 닉네임 중복 확인
      var existingNickname = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get();

      if (existingNickname.docs.isEmpty) {
        // 중복되는 닉네임이 없으면 업데이트
        String uid = FirebaseAuth.instance.currentUser!.uid;
        await _firestore.collection('users').doc(uid).update({
          'nickname': nickname,
        });
        // 닉네임 업데이트 후 프로필 사진 설정 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePhotoSetupPage()),
        );
      } else {
        // 중복될 경우 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 존재하는 닉네임입니다. 다른 닉네임을 입력해주세요.')),
        );
      }
    } else {
      // 닉네임이 비어있는 경우 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('닉네임 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: '닉네임',
                hintText: '원하는 닉네임을 입력하세요',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateNickname,
              child: Text('닉네임 저장'),
            ),
          ],
        ),
      ),
    );
  }
}