import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:latter_pracj/services/auth_services.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin{
  late AnimationController _controller;
  AuthService authService = AuthService();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(seconds: 10),
      upperBound: 1,
      lowerBound: -1,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final globalKey = GlobalKey<NavigatorState>();

    return Scaffold(
        body: Stack(
            children: [
              // Image Background
              Positioned.fill(
                child: Image.asset(
                  'assets/images/5162027.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Column(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (BuildContext context, Widget? child) {
                          return ClipPath(
                            clipper: DrawClip(_controller.value),
                            child: Container(
                              height: size.height * 0.8,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/images/5162027.jpg'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),// 그라데이션 배경
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/lottie/Animation - 1701418666868.json',
                            width: 120,
                            height: 120,
                            fit: BoxFit.fill,
                          ),

                          Transform.translate(
                            offset: Offset(0, 100), // Change offset values as needed
                            child: Image.asset(
                              'assets/images/login.png',
                              width: 250,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          ),


                          SizedBox(height: 7,),
                          Transform.translate(
                            offset: Offset(0,-350),
                            child: Text(
                              'ONE PIECE MAP',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Jalnan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Container(
                    width: 230, // 원하는 너비
                    height: 50, // 원하는 높이
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2), // 그림자 색상 및 불투명도 조절
                          spreadRadius: 5, // 그림자 확산 범위 조절
                          blurRadius: 7, // 그림자 흐릿한 정도 조절
                          offset: Offset(0, 5), // 그림자 위치 조절 (수평, 수직)
                        ),
                      ],
                    ),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white, width: 2), // 테두리 스타일 지정
                        elevation: 5, // 그림자 높이
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // 버튼 모서리 둥글게
                        ),
                      ),
                      onPressed: authService.handleSignIn,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google.png',
                            height: 35,
                            width: 35,
                          ),
                          Text(
                            'Google 계정으로 로그인',
                            style: TextStyle(
                              color: Colors.black, // 버튼 텍스트 색상을 흰색으로 지정
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20,)
                ],
              ),
            ]
        )

    );
  }
}

Widget input(String hint, {bool isPass = false}) {
  return TextField(
    obscureText: isPass,
    decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFACACAC), fontSize: 14),
        contentPadding: const EdgeInsets.only(top: 20, bottom: 20, left: 38),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF1F1F1)),
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC7C7C7)),
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
        )),
  );
}

class DrawClip extends CustomClipper<Path> {
  double move = 0;
  double slice = math.pi;
  DrawClip(this.move);
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.8);

    // Increase the multiplier for a greater amplitude
    double amplitude = 100; // Increased amplitude value

    // The xCenter calculation can stay the same
    double xCenter = size.width * 0.5 + (size.width * 0.6 + 1) * math.sin(move * slice);

    // Apply the increased amplitude here
    double yCenter = size.height * 0.8 + amplitude * math.cos(move * slice);

    path.quadraticBezierTo(xCenter, yCenter, size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}