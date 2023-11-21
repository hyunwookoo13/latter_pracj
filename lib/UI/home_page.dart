import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../services/auth_services.dart';

class Letter {
  LatLng position;
  String content;
  String userId;

  Letter({required this.position, required this.content, required this.userId});
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AuthService authService = AuthService();

  GoogleMapController? _controller;
  Location location = Location();
  DatabaseReference? databaseReference;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LatLng _initialcameraposition = LatLng(35.8673, 127.7339);
  LatLng? _currentPosition;

  Set<Marker> _letterMarkers = {};
  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor latterIcon = BitmapDescriptor.defaultMarker;

  StreamSubscription<LocationData>? _locationSubscription;

  Map<String, Letter> _letters = {};

  @override
  void initState() {
    super.initState();
    databaseReference = FirebaseDatabase.instance.ref().child("Locations");
    _getCurrentLocation();
    setCustomUserIcon();
    setCustomMarkerIcon();
    _loadLetters();
  }

  void _loadLetters() {
    databaseReference!.child("Letters").onValue.listen((event) {
      var snapshot = event.snapshot;
      Map<dynamic, dynamic>? letters = snapshot.value as Map<dynamic, dynamic>?;
      if (letters != null) {
        if (mounted) {
          setState(() {
            _letterMarkers.clear();
            _letters.clear();
            letters.forEach((key, value) {
              LatLng letterPosition = LatLng(value['latitude'], value['longitude']);
              Letter letter = Letter(
                position: letterPosition,
                content: value['content'],
                userId: value['userId'],
              );
              _letters[key] = letter;
              _letterMarkers.add(
                Marker(
                  markerId: MarkerId(key),
                  position: letterPosition,
                  icon: latterIcon,
                  onTap: () => _showLetterContent(letter.content),
                ),
              );
            });
          });
        }
      }
    });
  }

  void _showLetterContent(String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Letter Content"),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _getCurrentLocation() async {
    LocationData position = await location.getLocation();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude!, position.longitude!);
        _initialcameraposition = LatLng(position.latitude!, position.longitude!);
        _updateLocationToFirebase(_currentPosition!);
      });
    }

    _locationSubscription = location.onLocationChanged.listen((LocationData currentLocation) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _controller!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentPosition!, zoom: 18.0, tilt: 45.0),
            ),
          );
          _updateLocationToFirebase(_currentPosition!);
        });
      }
    });
  }

  _updateLocationToFirebase(LatLng position) {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      databaseReference!.child(userId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } else {
      print("User is not logged in");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void setCustomUserIcon() {
    BitmapDescriptor.fromAssetImage(ImageConfiguration.empty, "assets/images/user1.png").then((icon) {
      sourceIcon = icon;
    });
  }

  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(ImageConfiguration.empty, "assets/images/gift.png").then((icon) {
      latterIcon = icon;
    });
  }

  void _showLetterDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        TextEditingController _letterController = TextEditingController();

        return AlertDialog(backgroundColor: Colors.white,
          insetPadding: EdgeInsets.all(10),
          title: Image.asset("assets/images/latter.png", width: 60, height: 60),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // 이 부분을 통해 다이얼로그 크기를 내용에 맞게 조절
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("지금 위치에",style: TextStyle(fontWeight: FontWeight.bold),),
                    Text("이야기를 남겨주세요",style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // 텍스트 필드 색상
                    boxShadow: [ // 그림자 추가
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 3,
                        offset: Offset(0, 3), // 그림자 위치
                      ),
                    ],
                    borderRadius: BorderRadius.circular(4), // 텍스트 필드의 모서리를 둥글게 만듭니다.
                  ),
                  child: TextField(
                    controller: _letterController,
                    maxLines: 9,
                    decoration: InputDecoration(
                      hintText: "여기에 편지 내용을 입력하세요",
                      border: OutlineInputBorder(borderSide: BorderSide.none), // 테두리 제거
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context); // 다이얼로그 닫기
                      },
                      icon: Image.asset("assets/images/cancel_button.png",width: 50,height: 50,),
                    ),
                    IconButton(
                      onPressed: () {
                        // 편지 내용 저장 및 처리 코드 추가
                        if (_currentPosition != null && _letterController.text.isNotEmpty) {
                          _saveLetterToFirebase(_currentPosition!, _letterController.text);
                          _letterController.clear();
                        }
                        Navigator.pop(context); // 다이얼로그 닫기
                      },
                      icon: Image.asset("assets/images/save_button.png",width: 180,height: 50,),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextEditingController _letterContentController = TextEditingController();

  void _saveLetterToFirebase(LatLng position, String content) {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      databaseReference!.child("Letters").push().set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'content': content,
        'userId': userId,
      });
    } else {
      print("User is not logged in");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Tracker'),
        actions: [IconButton(onPressed: authService.handleSignOut, icon: Icon(Icons.cancel_outlined))],
      ),
      body: _getMap(),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Color(0xFF6117D6),
        backgroundColor: Color(0xFF6117D6),
        onPressed: _showLetterDialog,
        child: Icon(Icons.create,color: Colors.white,),
      ),
    );
  }

  Widget _getMap(){
    return Stack(
      children: [
        GoogleMap(
          myLocationEnabled:true,
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(target: _initialcameraposition, zoom: 18.0),
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
          },
          markers: _currentPosition != null
              ? {
            Marker(
              markerId: MarkerId('source'),
              position: _currentPosition!,
              icon: sourceIcon,
            ),
            ..._letterMarkers,
          }
              : {},
        ),
      ],
    );
  }
}
