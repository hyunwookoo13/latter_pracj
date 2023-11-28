import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../UI/home_page.dart';
import '../services/auth_services.dart';

class ProfilePhotoSetupPage extends StatefulWidget {
  @override
  _ProfilePhotoSetupPageState createState() => _ProfilePhotoSetupPageState();
}

class _ProfilePhotoSetupPageState extends State<ProfilePhotoSetupPage> {
  int _selectedAvatarIndex = -1;
  AuthService authService = AuthService();
  final List<String> _avatarImages = List.generate(
    8,
        (index) => 'assets/images/user${index + 1}.png',
  );

  Widget _buildAvatarImage(int index) {
    bool isSelected = _selectedAvatarIndex == index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: isSelected ? 1.0 : 0.3,
          child: Image.asset(
            _avatarImages[index],
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
        Container(
          width: 20,
          height: 20,
          margin: EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
            color: isSelected ? Colors.deepPurple : Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedAvatar() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: _selectedAvatarIndex == -1 ? Colors.transparent : Colors.transparent, // 회색 배경 제거
        borderRadius: BorderRadius.circular(20),
      ),
      child: _selectedAvatarIndex != -1
          ? Image.asset(
        _avatarImages[_selectedAvatarIndex],
        fit: BoxFit.contain,
      )
          : null,
    );
  }

  Future<void> _saveProfilePhoto() async {
    if (_selectedAvatarIndex != -1) {
      String photoURL = _avatarImages[_selectedAvatarIndex];
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // updateUserProfile 메소드를 이용하여 Firestore에 프로필 사진 URL 업데이트
      await authService.updateUserProfile(uid, photoURL);

      // HomePage로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 사진을 선택해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: Column(
        children: [
          Stack(
            children: [
              ClipPath(
                clipper: HalfCircleClipper(),
                child: Container(
                  color: Colors.deepPurple,
                  height: 250,
                  width: double.infinity,
                ),
              ),
              Positioned(
                top: 95, // Adjust the position as needed
                left: 0,
                right: 0,
                child: Center(child: _buildSelectedAvatar()),
              ),
              Positioned(
                top: 40, // "프로필을 선택하세요" 텍스트의 위치 조정
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "프로필을 선택하세요",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 50),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: (80 / 80),
              ),
              itemCount: _avatarImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatarIndex = index;
                    });
                  },
                  child: _buildAvatarImage(index),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfilePhoto,
                style: ElevatedButton.styleFrom(
                  primary: Colors.deepPurple,
                  onPrimary: Colors.white,
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('저장하기'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HalfCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, size.height * 2, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}