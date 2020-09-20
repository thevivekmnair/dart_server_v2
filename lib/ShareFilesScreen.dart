import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_server_v2/ServerHandler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Map<String, double> filesMap = {};
Stream<List> progressBarStream() async* {
  while (true) {
    await Future.delayed(Duration(milliseconds: 500));
    yield filesMap.values.toList();
  }
}

class ShareFilesScreen extends StatefulWidget {
  final ServerHandler serverHandler;
  ShareFilesScreen(this.serverHandler);
  @override
  _ShareFilesScreenState createState() => _ShareFilesScreenState(serverHandler);
}

class _ShareFilesScreenState extends State<ShareFilesScreen> {
  ServerHandler serverHandler;
  bool loading = false;
  List<Map> widgetlist = [];
  double progress = 0.0;
  Uint8List uint8list;
  String title;
  Stream<List<double>> progressStream;

  _ShareFilesScreenState(this.serverHandler);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    filesMap = {};
  }

  void loadingFunc(bool val) {
    setState(() {
      loading = val;
    });
  }

  void updateProgress(String fileName, double _progress) {
    if (filesMap[fileName] != null) {
      filesMap[fileName] = _progress;
    }
  }

  void updateFilesMap(String key, int status, String base64encoded) {
    filesMap.addAll({key: status.toDouble()});
    this.setState(() {
      widgetlist.add({'img': base64encoded});
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
      backgroundColor: Color(0xff1B2631),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            serverHandler.alreadyDidNavigation = false;
            serverHandler.stopServer();
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color(0xff283747),
        centerTitle: true,
        title: Text('Share Files'),
      ),
      body: Center(
          child: filesMap.isEmpty
              ? Text(
                  "Choose files to send",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                )
              : ListView.builder(
                  itemCount: widgetlist.length,
                  itemBuilder: (context, index) {
                    uint8list = base64.decode(widgetlist[index]['img']);
                    title = filesMap.keys.toList()[index];
                    progress = filesMap.values.toList()[index].toDouble();
                    return ListElement(uint8list, title, index);
                  },
                )),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.folder),
        tooltip: "Select Files",
        onPressed: () {
          if (!loading) {
            loading = true;
            serverHandler.chooseFile(
                loadingFunc, updateFilesMap, updateProgress);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}

class ListElement extends StatefulWidget {
  final Uint8List img;
  final String title;
  final int index;
  ListElement(this.img, this.title, this.index);
  @override
  _ListElementState createState() => _ListElementState(img, title, index);
}

class _ListElementState extends State<ListElement> {
  Uint8List img;
  String title;
  int index;
  _ListElementState(this.img, this.title, this.index);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
          color: Colors.blueAccent[100].withOpacity(0.1),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      width: MediaQuery.of(context).size.width / 1.2,
      height: MediaQuery.of(context).size.height / 9,
      child: ListTile(
        leading: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              border: Border.all(color: Colors.lightBlueAccent, width: 2)),
          child: Image.memory(
            img,
            scale: 1,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedOpacity(
                child: child,
                opacity: frame == null ? 0 : 1,
                duration: const Duration(seconds: 1),
                curve: Curves.easeOut,
              );
            },
            fit: BoxFit.cover,
            height: 40,
            width: 50,
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        subtitle: ProgressBar(index),
      ),
    );
  }
}

class ProgressBar extends StatefulWidget {
  final int index;
  ProgressBar(this.index);
  @override
  _ProgressBarState createState() => _ProgressBarState(index);
}

class _ProgressBarState extends State<ProgressBar> {
  int index;
  double progress = 0;
  StreamSubscription<List> streamSubscription;

  _ProgressBarState(this.index);
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setStateFunc();
  }

  void setStateFunc() async {
    streamSubscription = progressBarStream().listen((event) {
      if (event.length > 0 && mounted) {
        setState(() {
          progress = event[index];
          if (progress == 100.0) {
            print("cancelled");
            streamSubscription.cancel();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 5,
        ),
        progress == 0
            ? SizedBox()
            : LinearProgressIndicator(
                backgroundColor: Colors.white,
                value: progress / 100,
              ),
        Text(
          progress == 0 ? 'waiting...' : "${progress.round().toString()}%",
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
      ],
    );
  }
}
