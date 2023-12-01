import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/AddFriendPage.dart';
import '../services/auth_services.dart';
import 'lettercontent_page.dart';
import 'my_page.dart';

class Letter {
  String id;
  LatLng position;
  String content;
  String userId;
  String? imageUrl; // 이미지 URL 필드 추가

  Letter({required this.id, required this.position, required this.content, required this.userId, this.imageUrl});
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  String? nickname;

  StreamSubscription<LocationData>? _locationSubscription;

  Map<String, Letter> _letters = {};
  Set<Marker> _friendMarkers = {};

  XFile? _selectedImage;

  @override
  void initState() {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    super.initState();
    databaseReference = FirebaseDatabase.instance.ref().child("Locations");
    _getCurrentLocation();
    setCustomUserIcon(currentUserId);
    setCustomMarkerIcon();
    _loadLetters();
    prepareFriendMarkers(); // 친구들의 위치를 로드하는 함수 호출
  }

  // 비동기 작업을 수행하고 결과를 임시 저장소에 저장하는 함수
  Future<void> prepareFriendMarkers() async {
    var friends = await getFriendsData();
    List<Marker> tempMarkers = [];

    for (var friend in friends) {
      var latitude = friend['latitude'];
      var longitude = friend['longitude'];
      var nickname = friend['nickname'];
      var photoURL = friend['photoURL'];

      BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty,
          photoURL
      );

      var marker = Marker(
        markerId: MarkerId(friend['uid']),
        position: LatLng(latitude, longitude),
        icon: customIcon,
        infoWindow: InfoWindow(title: nickname),
      );

      tempMarkers.add(marker);
    }

    // setState를 호출하여 UI를 업데이트합니다.
    setState(() {
      _friendMarkers.clear();
      _friendMarkers.addAll(tempMarkers);
    });
  }

  Future<List<Map<String, dynamic>>> getFriendsData() async {
    List<Map<String, dynamic>> friendsData = [];

    // Assuming you have a current user ID
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Get the accepted friend requests
    QuerySnapshot friendRequests = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests')
        .where('status', isEqualTo: 'accepted')
        .get();

    // For each friend, get their details
    for (var doc in friendRequests.docs) {
      String friendId = doc.id; // Assuming the document ID is the friend's user ID

      // Get friend's data from Firestore
      DocumentSnapshot friendDoc = await _firestore.collection('users').doc(friendId).get();
      Map<String, dynamic> friendData = friendDoc.data() as Map<String, dynamic>;

      // Add additional data as needed, e.g., friend's UID
      friendData['uid'] = friendId;

      // Assuming you store the location in Realtime Database
      // Fetch location data from Realtime Database
      DataSnapshot locationSnapshot = await FirebaseDatabase.instance.ref('Locations').child(friendId).get();
      if (locationSnapshot.exists) {
        Map<dynamic, dynamic> locationData = locationSnapshot.value as Map<dynamic, dynamic>;
        friendData['latitude'] = locationData['latitude'];
        friendData['longitude'] = locationData['longitude'];
      }

      friendsData.add(friendData);
    }

    return friendsData;
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
                id: key,
                // Firebase 키를 ID로 사용
                position: letterPosition,
                content: value['content'],
                userId: value['userId'],
                imageUrl: value['imageUrl'], // 이미지 URL 추가
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

  void showLetterContentPage(Letter letter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LetterContentPage(letter: letter),
      ),
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

  Future<String?> getUserPhotoURL(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // 'data()' 메서드의 반환 값을 'Map<String, dynamic>'으로 캐스팅합니다.
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    return userData?['photoURL'] as String?;
  }

  Future<String?> getUserNickname(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // 'data()' 메서드의 반환 값을 'Map<String, dynamic>'으로 캐스팅합니다.
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    return userData?['nickname'] as String?;
  }

  Future<void> setCustomUserIcon(String userId) async {
    String? photoURL = await getUserPhotoURL(userId);
    String? nickName = await getUserNickname(userId);

    if (photoURL != null && photoURL.isNotEmpty) {
      BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration.empty, photoURL);

      setState(() {
        sourceIcon = customIcon;
        nickname = nickName!;
      });
    } else {
      print("사용자 photoURL을 찾을 수 없음");
    }
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

        return AlertDialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.all(10),
          title: Image.asset("assets/images/latter.png", width: 60, height: 60),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // 이 부분을 통해 다이얼로그 크기를 내용에 맞게 조절
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "지금 위치에",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("이야기를 남겨주세요", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                // Button to pick an image
                TextButton(
                  onPressed: _pickImage,
                  child: Text("Pick an Image"),
                ),

                // Display the selected image
                if (_selectedImage != null) Image.file(File(_selectedImage!.path)),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // 텍스트 필드 색상
                    boxShadow: [
                      // 그림자 추가
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
                      icon: Image.asset(
                        "assets/images/cancel_button.png",
                        width: 50,
                        height: 50,
                      ),
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
                      icon: Image.asset(
                        "assets/images/save_button.png",
                        width: 180,
                        height: 50,
                      ),
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
        'imageUrl': imageUrl, // 이미지 URL 추가
      });
    } else {
      print("User is not logged in");
    }
  }

  void _navigateToAddFriendPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddFriendPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Peace Map"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.account_circle), // 마이페이지 아이콘
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyPage()),
            );
          },
        ),
        actions: [IconButton(onPressed: authService.handleSignOut, icon: Icon(Icons.logout))],
      ),
      body: _getMap(),
    );
  }

  Widget _getMap() {
    return Stack(
      children: [
        GoogleMap(
          myLocationEnabled: true,
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
                      infoWindow: InfoWindow(title: nickname ?? 'Unknown'),
                  ),
                  ..._letterMarkers,
                  ..._friendMarkers,  // Markers for friends
                }
              : {},
        ),
        Transform.translate(
          offset: Offset(90, 600),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              shape: CircleBorder(),
              padding: EdgeInsets.all(20),
                shadowColor: Colors.black,
                elevation: 4,
            ),
            onPressed: _navigateToAddFriendPage,
            child: Icon(Icons.person_add_alt,color: Colors.white,),
          ),
        ),
        Transform.translate(
          offset: Offset(260, 580),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              shape: CircleBorder(),
              padding: EdgeInsets.all(20),
            ),
            onPressed: _showLetterDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Icon(Icons.edit,color: Colors.white,),
            ),
          ),
        ),
      ],
    );
  }
}
