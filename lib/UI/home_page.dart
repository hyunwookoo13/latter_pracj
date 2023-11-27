import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_services.dart';
import 'lettercontent_page.dart';

class Letter {
  String id;
  LatLng position;
  String content;
  String userId;
  String? imageUrl;  // 이미지 URL 필드 추가

  Letter({required this.id,required this.position, required this.content, required this.userId, this.imageUrl});
}

class Message {
  final String userId;
  final String content;
  final int timestamp; // Unix timestamp

  Message({required this.userId, required this.content, required this.timestamp});

  factory Message.fromSnapshot(Map<dynamic, dynamic> snapshot) {
    return Message(
      userId: snapshot['userId'] as String,
      content: snapshot['content'] as String,
      timestamp: snapshot['timestamp'] as int,
    );
  }
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

  final Set<Marker> _letterMarkers = {};
  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor latterIcon = BitmapDescriptor.defaultMarker;

  StreamSubscription<LocationData>? _locationSubscription;

  Map<String, Letter> _letters = {};

  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    databaseReference = FirebaseDatabase.instance.ref().child("Locations");
    _getCurrentLocation();
    setCustomUserIcon();
    setCustomMarkerIcon();
    _loadLetters();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<String> uploadImageToFirebase(XFile imageFile) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("path/to/storage/${imageFile.name}");
    UploadTask uploadTask = ref.putFile(File(imageFile.path));
    await uploadTask.whenComplete(() {});
    return await ref.getDownloadURL();
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
                id: key,  // Firebase 키를 ID로 사용
                position: letterPosition,
                content: value['content'],
                userId: value['userId'],
                imageUrl: value['imageUrl'],  // 이미지 URL 추가
              );
              _letters[key] = letter;
              _letterMarkers.add(
                Marker(
                  markerId: MarkerId(key),
                  position: letterPosition,
                  icon: latterIcon,
                  onTap: () => showLetterContentPage(letter),
                ),
              );
            });
          });
        }
      }
    });
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

  void showLetterContentPage(Letter letter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LetterContentPage(letter: letter),
      ),
    );
  }


  void _showLetterContent(Letter letter) {
    TextEditingController _messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Letter Content"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                letter.imageUrl != null
                    ? Image.network(letter.imageUrl!)  // 이미지 표시
                    : SizedBox(),  // 이미지 URL이 없을 경우 공백 표시
                SizedBox(height: 10),
                Text(letter.content),
                SizedBox(height: 10),
                StreamBuilder(
                  stream: databaseReference!.child('Letters/${letter.id}/Messages').onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasData && !snapshot.hasError) {
                      Map<dynamic, dynamic> messagesSnapshot = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};

                      List<Message> messages = messagesSnapshot.entries.map((entry) {
                        return Message.fromSnapshot(entry.value as Map<dynamic, dynamic>);
                      }).toList();

                      // 메시지 목록을 ListView.builder로 표시합니다.
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var message = messages[index];
                          bool isCurrentUser = message.userId == _auth.currentUser?.uid;
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
              ],
            ),
          ),
          actions: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
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
                        var messageRef = databaseReference!.child('Letters/${letter.id}/Messages').push();
                        messageRef.set({
                          'userId': _auth.currentUser?.uid,
                          'content': _messageController.text,
                          'timestamp': ServerValue.timestamp,
                        });
                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
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
                // Button to pick an image
                TextButton(
                  onPressed: _pickImage,
                  child: Text("Pick an Image"),
                ),

                // Display the selected image
                if (_selectedImage != null)
                  Image.file(File(_selectedImage!.path)),

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
                          _saveLetterWithImage(_currentPosition!, _letterController.text, _selectedImage!);
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

  void _saveLetterWithImage(LatLng position, String content, XFile imageFile) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      String imageUrl = await uploadImageToFirebase(imageFile);
      databaseReference!.child("Letters").push().set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'content': content,
        'userId': userId,
        'imageUrl': imageUrl,  // 이미지 URL 추가
      });
    } else {
      print("User is not logged in");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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