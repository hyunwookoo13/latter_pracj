import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PlantState extends ChangeNotifier {
  double _growth = 0.0;
  int _letterCount = 0;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('Locations/Letters');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  double get growth => _growth;
  int get letterCount => _letterCount;

  // ... 기존의 growTree 및 resetTree 메서드 ...

  void updateLetterCount() {
    // 'Locations/Letters' 경로에서 편지 데이터를 가져옵니다.
    _dbRef.get().then((snapshot) {
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> letters = Map<dynamic, dynamic>.from(snapshot.value as Map);
        int userLetterCount = 0;
        // 각 편지를 순회하며 현재 사용자가 작성한 편지만 카운트합니다.
        for (var letter in letters.values) {
          if (letter['userId'] == _currentUserId) {
            userLetterCount++;
          }
        }
        _letterCount = userLetterCount;

        // 편지 수에 따라 트리 성장률을 업데이트합니다.
        _growth = _letterCount / 1; // 예시: 10편의 편지당 트리가 1만큼 성장
        // if (_growth > 1.0) {
        //   _growth = 0.0;
        // }
      } else {
        _letterCount = 0;
        _growth = 0.0;
      }
      notifyListeners();
    }).catchError((error) {
      // 오류 처리
      print("An error occurred while accessing the database: $error");
    });
  }
}
