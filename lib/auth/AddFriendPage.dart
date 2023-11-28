import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'FriendRequestsPage.dart';

class AddFriendPage extends StatefulWidget {
  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _searchResult; // 검색 결과를 저장할 변수
  int friendRequestsCount=0;

  Future<void> _searchUserByNickname() async {
    final String nickname = _searchController.text.trim();

    if (nickname.isNotEmpty) {
      // Firestore에서 닉네임 검색
      final querySnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 검색된 사용자의 데이터를 _searchResult에 저장
        setState(() {
          _searchResult = querySnapshot.docs.first.data();
        });
      } else {
        // 검색 결과가 없을 때
        setState(() {
          _searchResult = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자를 찾을 수 없습니다.')),
        );
      }
    }
  }
  Future<void> sendFriendRequest(String friendUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference requestDoc = _firestore.collection('friend_requests').doc();

    await _firestore.runTransaction((transaction) async {
      transaction.set(requestDoc, {
        'from': currentUserId,
        'to': friendUserId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(), // 요청 시간 기록
      });
    }).then((result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('친구 요청을 보냈습니다.')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('친구 요청을 보내는 데 실패했습니다.')),
      );
    });
  }
  void getFriendRequestsCount() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid; // 현재 사용자의 UID
    // 'friend_requests' 컬렉션에서 'to' 필드가 현재 사용자의 UID와 일치하고,
    // 'status' 필드가 'pending'인 문서의 개수를 쿼리합니다.
    QuerySnapshot querySnapshot = await _firestore
        .collection('friend_requests')
        .where('to', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    // State가 살아있을 때만 setState를 호출합니다.
    if (mounted) {
      setState(() {
        // 가져온 문서의 개수로 friendRequestsCount를 업데이트합니다.
        friendRequestsCount = querySnapshot.docs.length;
      });
    }
  }

  void initState() {
    super.initState();
    getFriendRequestsCount(); // 페이지 로드 시 친구 요청 개수를 가져옵니다.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('닉네임으로 친구 추가'),
      ),
      body: SingleChildScrollView( // 스크롤 가능하게 만들기 위해 SingleChildScrollView 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 가로축 정렬을 시작 부분으로 설정
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0), // 여백 조정
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: '닉네임 검색',
                  hintText: '친구의 닉네임을 입력하세요',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _searchUserByNickname,
                  ),
                ),
                onSubmitted: (value) => _searchUserByNickname(),
              ),
            ),
            SizedBox(height: 56.69), // 프로필 사진과 검색창 사이의 간격 설정
            if (_searchResult != null) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // 세로축 정렬을 시작 부분으로 설정
                  children: [
                    SizedBox(
                      height: 150, // Adjust the size as needed
                      width: 150, // Adjust the size as needed
                      child: CircleAvatar(
                        backgroundImage: AssetImage(_searchResult!['photoURL']),
                        radius: 75, // Adjust the size as needed
                      ),
                    ),
                    SizedBox(height: 8), // Provide some spacing between image and text
                    Text(
                      _searchResult!['nickname'],
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // _searchResult와 _searchResult['userId'] 둘 다 null이 아닌지 확인
                        if (_searchResult != null && _searchResult!['nickname'] != null) {
                          sendFriendRequest(_searchResult!['nickname']);
                        } else {
                          // 'userId'가 null일 경우 처리
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('유효하지 않은 사용자입니다.')),
                          );
                        }
                      },
                      child: Text('친구 추가'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: Stack(
        alignment: Alignment.topRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FriendRequestsPage()),
                );
              },
              child: Image.asset('assets/images/image 13.png'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          friendRequestsCount > 0 ? Positioned( // 친구 요청이 있을 때만 숫자를 표시
            right: 11,
            top: 11,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                friendRequestsCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ) : SizedBox.shrink(), // 친구 요청이 없으면 아무것도 표시하지 않음
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}