import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendRequestsPage extends StatefulWidget {
  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot> _friendRequestsStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>?;
  }

  Widget _buildFriendRequestItem(DocumentSnapshot request) {
    String requesterUserId = request['from'];
    String requestId = request.id;

    return Dismissible(
      key: Key(requestId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.0),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // 여기에 친구 요청 거절 로직을 구현하세요.
        _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friend_requests')
            .doc(requestId)
            .delete(); // 슬라이드로 거절시 문서 삭제
      },
      child: FutureBuilder<Map<String, dynamic>?>(
        future: getUserProfile(requesterUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return ListTile(title: Text("사용자 정보를 불러오는 데 실패했습니다."));
          }

          Map<String, dynamic>? userProfile = snapshot.data;
          String profileImage = userProfile?['photoURL'] ?? 'default_profile_image_path';
          String nickname = userProfile?['nickname'] ?? 'Unknown';

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(profileImage),
            ),
            title: Text(nickname),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () {
                    // 여기에 친구 요청 수락 로직을 구현하세요.
                    _firestore
                        .collection('users')
                        .doc(currentUserId)
                        .collection('friend_requests')
                        .doc(requestId)
                        .update({'status': 'accepted'}); // 수락 시 상태 업데이트
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('친구 요청'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _friendRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('받은 친구 요청이 없습니다.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot request = snapshot.data!.docs[index];
              return _buildFriendRequestItem(request);
            },
          );
        },
      ),
    );
  }
}