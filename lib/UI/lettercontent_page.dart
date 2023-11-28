import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

class LetterContentPage extends StatefulWidget {
  final Letter letter;
  LetterContentPage({Key? key, required this.letter}) : super(key: key);

  @override
  State<LetterContentPage> createState() => _LetterContentPageState();
}

class _LetterContentPageState extends State<LetterContentPage> {
  TextEditingController _messageController = TextEditingController();
  late final DatabaseReference _messagesRef;

  @override
  void initState() {
    super.initState();
    // 메시지 목록을 불러올 Firebase 경로를 설정합니다.
    _messagesRef = FirebaseDatabase.instance.ref().child('Letters/${widget.letter.id}/Messages');
  }

  Widget buildMessageBubble(String content, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: isCurrentUser
              ? BorderRadius.circular(15).subtract(BorderRadius.only(bottomRight: Radius.circular(15)))
              : BorderRadius.circular(15).subtract(BorderRadius.only(bottomLeft: Radius.circular(15))),
        ),
        child: Text(
          content,
          style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  // 편지를 삭제하는 함수
  void _deleteLetter(String letterId) {
    // AlertDialog 또는 다른 방식을 통해 사용자에게 삭제를 확인받습니다.
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
                FirebaseDatabase.instance.ref()
                    .child('Letters')
                    .child(letterId)
                    .remove()
                    .then((_) {
                  // 성공적으로 삭제되었을 때의 처리
                  print("Letter successfully deleted");
                  Navigator.of(context).pop(); // 닫기
                  Navigator.of(context).pop(); // 닫기
                })
                    .catchError((error) {
                  // 오류 발생 시 처리
                  print("Delete failed: $error");
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
      body: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              // 메시지 목록을 표시하는 StreamBuilder입니다.
              // 이미지와 내용을 표시합니다.
              widget.letter.imageUrl != null
                  ? Image.network(widget.letter.imageUrl!)
                  : SizedBox(),
              SizedBox(height: 10),
              Text(widget.letter.content),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder(
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
                          bool isCurrentUser = message.userId == FirebaseAuth.instance.currentUser?.uid;
                          // buildMessageBubble 함수를 사용하여 말풍선 스타일로 메시지를 표시합니다.
                          return buildMessageBubble(message.content, isCurrentUser);
                        },
                      );
                    } else {
                      // 데이터가 없거나 오류가 발생한 경우 로딩 인디케이터를 표시합니다.
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
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
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

// Message 클래스와 buildMessageBubble 함수를 적절히 정의해야 합니다.
