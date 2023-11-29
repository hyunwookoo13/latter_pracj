import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendListPage extends StatefulWidget {
  @override
  _FriendListPageState createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot> getFriendRequests() {
    // 'accepted' 상태의 친구 요청만 가져옵니다.
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests')
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    // 다른 사용자의 프로필 데이터를 가져옵니다.
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('친구 목록'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getFriendRequests(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('친구 요청이 없습니다.'));
          }

          List<FutureBuilder> friendsList = snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> request = document.data() as Map<String, dynamic>;
            // 친구의 userID를 사용하여 프로필 데이터를 가져옵니다.
            String friendUserId = request['from'];

            return FutureBuilder<Map<String, dynamic>?>(
              future: getUserData(friendUserId),
              builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(leading: CircularProgressIndicator());
                }
                if (!userSnapshot.hasData) {
                  return ListTile(title: Text('사용자 정보를 불러오는 데 실패했습니다.'));
                }
                var userData = userSnapshot.data!;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(userData['photoURL'] ?? 'https://via.placeholder.com/150'),
                  ),
                  title: Text(userData['nickname'] ?? '알 수 없음'),
                );
              },
            );
          }).toList();

          return ListView(
            children: friendsList,
          );
        },
      ),
    );
  }
}
