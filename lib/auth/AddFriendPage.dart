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
  Map<String, dynamic>? _searchResult;
  int friendRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    getFriendRequestsCount();
    WidgetsBinding.instance!.addPostFrameCallback((_) => setState(() {}));
  }

  Future<void> _searchUserByNickname() async {
    final String nickname = _searchController.text.trim();
    if (nickname.isNotEmpty) {
      final querySnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _searchResult = querySnapshot.docs.first.data();
          _searchResult!['userId'] = querySnapshot.docs.first.id;
        });
      } else {
        setState(() {
          _searchResult = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자를 찾을 수 없습니다.')),
        );
      }
    }
  }

  Future<void> sendFriendRequest(String receiverUserId) async {
    String senderUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference requestDoc = _firestore.collection('users')
        .doc(receiverUserId)
        .collection('friend_requests')
        .doc(senderUserId);

    await requestDoc.set({
      'from': senderUserId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
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
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests')
        .where('status', isEqualTo: 'pending')
        .get();

    if (mounted) {
      setState(() {
        friendRequestsCount = querySnapshot.docs.length;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('닉네임으로 친구 추가'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
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
            SizedBox(height: 56.69),
            if (_searchResult != null) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CircleAvatar(
                        backgroundImage: AssetImage(_searchResult!['photoURL']),
                        radius: 75,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _searchResult!['nickname'],
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_searchResult != null && _searchResult!['userId'] != null) {
                          sendFriendRequest(_searchResult!['userId']);
                        } else {
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
          if (friendRequestsCount > -1)

            Positioned(
              right: 37,
              top: -3,
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
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}