import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import '../auth/FriendListPage.dart';
import '../services/tree_service.dart';

class PlantScreen extends StatefulWidget {
  const PlantScreen({Key? key}) : super(key: key);

  @override
  _PlantScreenState createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {
  Artboard? _riveArtboard;
  StateMachineController? _controller;
  SMIInput<double>? _progress;

  @override
  void initState() {
    super.initState();
    Provider.of<PlantState>(context, listen: false).updateLetterCount();
    // Rive 애니메이션 파일을 로드합니다.
    rootBundle.load('assets/rive/798-1554-tree-demo.riv').then(
          (data) async {
        final file = RiveFile.import(data);
        final artboard = file.mainArtboard;
        var controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
        if (controller != null) {
          artboard.addController(controller);
          _progress = controller.findInput('input');
        }
        setState(() => _riveArtboard = artboard);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double treeWidth = MediaQuery.of(context).size.width - 40;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_outlined,color: Colors.white,),
              onPressed: () { Navigator.of(context).pop(); },
              //tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        title: Text("마이 페이지",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.groups,color: Colors.white,), // 친구 리스트 아이콘
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendListPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Text(
              "Stay Focused",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Center(
              child: Consumer<PlantState>(
                builder: (context, treeState, _) {
                  if (_progress != null) {
                    _progress!.value = treeState.growth; // 트리의 성장 상태를 반영
                  }
                  return _riveArtboard == null ? const SizedBox() :
                  Container(
                    width: treeWidth,
                    height: treeWidth,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(treeWidth / 2),
                        border: Border.all(color: Colors.white12, width: 10)),
                    child: Rive(alignment: Alignment.center, artboard: _riveArtboard!),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Consumer<PlantState>(
              builder: (context, treeState, _) {
                return Text(
                  'Uploaded Letters: ${treeState.letterCount}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          // ... 기타 UI 구성 요소 ...
        ],
      ),
    );
  }
}
