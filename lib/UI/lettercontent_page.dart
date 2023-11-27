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
  @override
  Widget build(BuildContext context) {
    TextEditingController _messageController = TextEditingController();
    // ...

    return Scaffold(
      appBar: AppBar(
        title: Text("Letter Content"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 이미지와 내용을 표시합니다.
            widget.letter.imageUrl != null
                ? Image.network(widget.letter.imageUrl!)
                : SizedBox(),
            SizedBox(height: 10),
            Text(widget.letter.content),
            SizedBox(height: 10),

            // 메시지 목록을 표시하는 StreamBuilder입니다.
            // ...
            Text(widget.letter.content),
            Text(widget.letter.content),
            // 메시지 입력 필드와 전송 버튼을 포함한 Row입니다.
            // ...
          ],
        ),
      ),
    );
  }
}
