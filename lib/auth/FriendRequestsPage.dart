import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
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
        .collection('friend_requests')
        .where('to', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  void _acceptFriendRequest(DocumentSnapshot request) {
    // 친구 요청을 수락하는 로직
  }

  void _declineFriendRequest(DocumentSnapshot request) {
    // 친구 요청을 거절하는 로직
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
              return ListTile(
                title: Text(request['from']), // 요청 보낸 사용자의 닉네임 또는 ID 표시
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () => _acceptFriendRequest(request),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => _declineFriendRequest(request),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
