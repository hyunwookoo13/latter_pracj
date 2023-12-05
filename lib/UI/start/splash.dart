import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latter_pracj/auth/auth.dart';
//import 'package:rive/rive.dart';
import 'package:rive/rive.dart' hide LinearGradient;


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

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF7209b7), // Purple
              Color(0xFF3f37c9), // Indigo
              Color(0xFF4895ef), // Blue
              Color(0xFF4cc9f0), // Light Blue
            ],
          ),
        ),
        child: Center(
          child: Text(
            'One Piece Map',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color
            ),
          ),
        ),
      ),
    );
  }

}
