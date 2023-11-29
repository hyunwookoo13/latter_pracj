import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../auth/FriendListPage.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.groups), // 친구 리스트 아이콘
            onPressed: () {

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendListPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('여기에 마이페이지의 콘텐츠가 들어갑니다.'),
      ),
    );
  }
}
