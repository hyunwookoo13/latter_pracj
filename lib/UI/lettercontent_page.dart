import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

class UserData {
  final String uid;
  final String nickname;
  final String photoURL;

  UserData({required this.uid, required this.nickname, required this.photoURL});

  factory UserData.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: data['uid'] as String,
      nickname: data['nickname'] as String,
      photoURL: data['photoURL'] as String,
    );
  }
}


class LetterContentPage extends StatefulWidget {
  final Letter letter;
  LetterContentPage({Key? key, required this.letter}) : super(key: key);

  @override
  State<LetterContentPage> createState() => _LetterContentPageState();
}

class _LetterContentPageState extends State<LetterContentPage> {
  TextEditingController _messageController = TextEditingController();
  late final DatabaseReference _messagesRef;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // 메시지 목록을 불러올 Firebase 경로를 설정합니다.
    _messagesRef = FirebaseDatabase.instance.ref().child('Letters/${widget.letter.id}/Messages');
  }

  Future<UserData> _getUserData(String userId) async {
    DocumentSnapshot snapshot = await _firestore.collection('users').doc(userId).get();
    return UserData.fromDocumentSnapshot(snapshot);
  }


  Widget buildMessageBubble(Message message) {
    // isCurrentUser를 계산합니다.
    bool isCurrentUser = FirebaseAuth.instance.currentUser?.uid == message.userId;

    return FutureBuilder<UserData>(
      future: _getUserData(message.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          UserData userData = snapshot.data!;
          return Row(
            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isCurrentUser) ...[
                CircleAvatar(backgroundImage: AssetImage(userData.photoURL)),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData.nickname, style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(message.content),
                    ),
                  ],
                ),
              ] else ...[
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(backgroundImage: AssetImage(userData.photoURL)),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(userData.nickname, style: TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              message.content,
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }
        return CircularProgressIndicator(); // 데이터 로딩 중 표시
      },
    );
  }


  // 편지와 해당 댓글을 삭제하는 함수
  void _deleteLetter(String letterId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('편지 삭제하기'),
          content: Text('정말로 이 편지를 삭제하기를 원하십니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(); // 닫기
              },
            ),
            TextButton(
              child: Text('삭제'),
              onPressed: () {
                // Firebase에서 편지를 삭제합니다.
                // 1. 편지 삭제
                FirebaseDatabase.instance.ref()
                    .child('Locations/Letters')
                    .child(letterId)
                    .remove()
                    .then((_) {
                  print("Letter successfully deleted from Locations.");
                }).catchError((error) {
                  print("Delete failed: $error");
                });

                // 2. 해당 편지의 댓글 삭제
                FirebaseDatabase.instance.ref()
                    .child('Letters')
                    .child(letterId)
                    .remove()
                    .then((_) {
                  print("Comments successfully deleted from Letters.");
                  Navigator.of(context).pop(); // AlertDialog 닫기
                  Navigator.of(context).pop(); // LetterContentPage 닫기
                }).catchError((error) {
                  print("Delete failed: $error");
                  Navigator.of(context).pop(); // AlertDialog 닫기
                });
              },
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    // 현재 사용자가 편지를 올린 사람과 동일한지 확인합니다.
    bool isOwner = FirebaseAuth.instance.currentUser?.uid == widget.letter.userId;
    return Scaffold(
      appBar: AppBar(
        title: Text("Letter Content"),
        centerTitle: true,
        actions: [
          // 편지를 올린 사람만 삭제 버튼을 볼 수 있습니다.
          if (isOwner)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _deleteLetter(widget.letter.id);
              },
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 이미지와 편지 내용을 표시합니다.
              widget.letter.imageUrl != null
                  ? Image.network(widget.letter.imageUrl!)
                  : SizedBox(),
              SizedBox(height: 10),
              Text(widget.letter.content),
              SizedBox(height: 10),
              // 메시지 목록을 표시하는 StreamBuilder입니다.

              Divider(),
              StreamBuilder(
                stream: _messagesRef.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.hasData && !snapshot.hasError) {
                    Map<dynamic, dynamic> messagesSnapshot = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
                    List<Message> messages = messagesSnapshot.entries.map((entry) {
                      Map<dynamic, dynamic> messageMap = Map<dynamic, dynamic>.from(entry.value);
                      return Message.fromSnapshot(messageMap);
                    }).toList();

                    // 메시지 목록을 역순으로 정렬합니다.
                    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    // 메시지 목록을 ListView로 표시합니다.
                    return ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var message = messages[index];
                        // buildMessageBubble 함수를 사용하여 메시지 버블을 생성합니다.
                        // 이제 사용자의 닉네임과 사진 URL도 함께 표시합니다.
                        return buildMessageBubble(message);
                      },
                    );
                  } else {
                    // 데이터가 없거나 오류가 발생한 경우 로딩 인디케이터를 표시합니다.
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
              // 메시지 입력 필드와 전송 버튼을 포함한 Row입니다.
              Divider(),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message here...",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_messageController.text.isNotEmpty) {
                        var messageRef = _messagesRef.push();
                        messageRef.set({
                          'userId': FirebaseAuth.instance.currentUser?.uid,
                          'content': _messageController.text,
                          'timestamp': ServerValue.timestamp,
                        });
                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

// Message 클래스와 buildMessageBubble 함수를 적절히 정의해야 합니다.
