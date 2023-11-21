import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> saveLetter(LatLng position, String title, String content) async {
    final prefs = await SharedPreferences.getInstance();

    // 마커 위치, 제목, 내용을 저장
    await prefs.setDouble('latitude', position.latitude);
    await prefs.setDouble('longitude', position.longitude);
    await prefs.setString('title', title);  // Add this line
    await prefs.setString('content', content);
  }

  Future<Map<String, dynamic>> loadLetter() async {
    final prefs = await SharedPreferences.getInstance();

    // 저장된 마커 위치, 제목, 내용을 불러옴
    double? latitude = prefs.getDouble('latitude');
    double? longitude = prefs.getDouble('longitude');
    String? title = prefs.getString('title');  // Add this line
    String? content = prefs.getString('content');

    if (latitude != null && longitude != null && title != null && content != null) {
      return {
        'position': LatLng(latitude, longitude),
        'title': title,  // Add this line
        'content': content,
      };
    } else {
      return {};
    }
  }
}
