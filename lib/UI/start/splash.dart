import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latter_pracj/auth/auth.dart';
import 'package:rive/rive.dart';

import '../../auth/login_page.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  void initState() {
    super.initState();
    // Wait for a few seconds and then navigate to the main screen
    _navigateToMainScreen();
  }

  Future<void> _navigateToMainScreen() async {
    await Future.delayed(Duration(seconds: 3)); // Adjust the duration as needed
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AuthPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // Set the background color of your splash screen
        child: Center(
          child:  Container(
            color: Colors.deepPurple, // 오른쪽 스플래시 화면의 배경색
            alignment: Alignment.center,
            child: Text(
              'One Piece Map',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white, // 텍스트 색상
              ),
            ),
          ),
        ),
      ),
    );
  }
}
