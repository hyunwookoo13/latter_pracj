
import 'package:flutter/cupertino.dart';

class TreeState extends ChangeNotifier {
  double _growth = 0.0;

  double get growth => _growth;

  void growTree() {
    _growth += 0.1; // 성장률을 조정하세요
    if (_growth > 1.0) {
      _growth = 1.0;
    }
    notifyListeners();
  }

  void resetTree() {
    _growth = 0.0;
    notifyListeners();
  }
}