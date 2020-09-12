import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'FrontEnd.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:dart_server_plugin/dart_server_plugin.dart';
import 'dart:convert';
import 'package:dart_server_v2/socket_Fileshare.dart';

void main() {
  runApp(MaterialApp(home: DartServer()));
}

class DartServer extends StatefulWidget {
  @override
  _DartServerState createState() => _DartServerState();
}

class _DartServerState extends State<DartServer> {
  bool loading = false;
  bool running = false;
  String ip_adress = '';
  Map hotspot = {};
  WebSocket socket;
  SocketFileShare socketFileShare;
  Stopwatch stopwatch = Stopwatch();

  HttpServer server;
  var img = [];
  List<String> file_path = [];
  Map<String, String> extention;

  _DartServerState() {
    socketFileShare = SocketFileShare();
  }

  Stream<List<int>> downloadStream(Stream<List<int>> stream) async* {
    int count = 0;
    await for (var value in stream) {
      count += value.length;
      yield value;
    }
    print(count);
  }

  void sendDownloadCompletedMsg(WebSocket wbs) {
    Map<String, String> download_msg = {};
    download_msg.addAll({"type": "downloadpermission", "data": 'true'});
    wbs.add(jsonEncode(download_msg));
  }

  //Server statrter function
  void serverHandler() async {
    setState(() {
      loading = true;
    });
    hotspot = await DartServerPlugin.enableHotspot;
    if (hotspot == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    server = await HttpServer.bind('0.0.0.0', 8000);
    ip_adress = hotspot['ipadress'];
    setState(() {
      loading = false;
      running = true;
    });
    print('Server started');
    server.listen((HttpRequest request) async {
      print(request.uri);
      if (request.uri.toString() == "/ws/socket") {
        print("Hey there");
        socket = await WebSocketTransformer.upgrade(request);
        socket.listen((event) {
          print('socketEvent');
          print(event);
          if (event.toString() == 'Vivek m nair') {
            socketFileShare.sendFileShare(socket, extention, 'fileupdate');
          }
        });
      } else {
        print(request.uri);
        String html_String = await HtmlGen().getHtmlString('Assets/index.html',
            'Assets/styles.css', 'head', ip_adress, img, 'li');

        try {
          Map params = request.uri.queryParameters;
          print('params are-- ${params}');
          if (params.isNotEmpty) {
            String val = params['selected'];

            String file_abs_path = "${extention['$val']}";
            File _download_file = File(file_abs_path);
            if (await _download_file.exists()) {
              int start_time = 0;
              int stop_time = 0;
              stopwatch.start();
              int file_length = await _download_file.length();
              print(file_length);
              start_time = stopwatch.elapsedMilliseconds;
              print(UriData.fromString('$val',
                  encoding: Encoding.getByName('utf-8')));
              request.response
                ..headers.set('Content-Type',
                    '${lookupMimeType(file_abs_path)}; charset=utf-8')
                ..headers.set('Content-Length', '$file_length')
                ..headers.set('Content-Disposition',
                    'attachment; filename="${UriData.fromString('$val', encoding: Encoding.getByName('utf-8'))}"');
              await request.response
                  .addStream(downloadStream(_download_file.openRead()));
              stop_time = stopwatch.elapsedMilliseconds;
              while (stop_time - start_time < 1000) {
                stop_time = stopwatch.elapsedMilliseconds;
              }
              sendDownloadCompletedMsg(socket);
              print('Done downloading');
            }
          } else {
            request.response
              ..headers.set('Content-Type', 'text/html; charset=utf-8')
              ..write(html_String);
          }
        } finally {
          request.response.close();
        }
      }
    });
  }

  void chooseFile() async {
    //Select files
    setState(() {
      loading = true;
    });
    Map<String, String> fileMap = await DartServerPlugin.openFileManager;

    if (fileMap != null) {
      fileMap.forEach((key, value) {
        print(value);
      });
      setState(() {
        loading = false;
        extention == null ? extention = fileMap : extention.addAll(fileMap);
        print(fileMap.values.toList());
        print(fileMap.keys.toList());
        img.addAll(fileMap.keys.toList());
      });
      if (socket != null) {
        socketFileShare.sendFileShare(socket, extention, 'fileupdate');
      }
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  void stopServer() async {
    if (running) {
      DartServerPlugin.enableHotspot;
      await server.close();
      setState(() {
        running = false;
      });
      print('Server stopped');
    }
  }

  Widget loadSwitcher(int i) {
    if (i == 0) {
      return loading
          ? Text('Loading...')
          : Text(
              'Start Server',
              style: TextStyle(color: Colors.white),
            );
    } else {
      return running
          ? Text(
              'Server is running!!',
              style: TextStyle(fontSize: 22, color: Colors.blue),
            )
          : Text('');
    }
  }

  Widget widgetSwitcher() {
    switch (running) {
      case false:
        return IconButton(
          key: UniqueKey(),
          highlightColor: Color(0xff1B2631),
          icon: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_tethering,
                color: Colors.grey[500],
              ),
              Icon(
                Icons.computer,
                color: Colors.grey[500],
              ),
              Text(
                'Tap to start server sharing',
                style: TextStyle(color: Colors.grey[100], fontSize: 18),
              )
            ],
          ),
          onPressed: () {
            if (!running) {
              serverHandler();
            }
          },
        );
      case true:
        return MaterialButton(
            key: UniqueKey(),
            highlightColor: Color(0xff1B2631),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Server running',
                  style: TextStyle(color: Colors.green[600], fontSize: 18),
                ),
                SizedBox(
                  height: 20,
                ),
                Icon(
                  Icons.wifi_tethering,
                  color: Colors.grey[300],
                ),
                Icon(
                  Icons.computer,
                  color: Colors.grey[300],
                ),
                Text(
                  'Tap to stop server sharing',
                  style: TextStyle(color: Colors.grey[100], fontSize: 18),
                ),
                Text(
                  'SSID - ${hotspot['ssid']}',
                  style: TextStyle(color: Colors.grey[100], fontSize: 18),
                ),
                Text(
                  'Password - ${hotspot['password']}',
                  style: TextStyle(color: Colors.grey[100], fontSize: 18),
                ),
                SizedBox(
                  height: 60,
                ),
                ip_adress.isNotEmpty
                    ? InkWell(
                        child: Text(
                          'Go to- http://$ip_adress:8000',
                          style: TextStyle(color: Colors.blue, fontSize: 18),
                        ),
                        onTap: () => launch('http://$ip_adress:8000'),
                      )
                    : Text(''),
              ],
            ),
            onPressed: stopServer);
      default:
        return Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xff1B2631),
        appBar: AppBar(
          title: Text('Dart Server'),
          backgroundColor: Color(0xff283747),
          centerTitle: true,
        ),
        body: Center(
            child: loading
                ? Container(
                    child: SpinKitFadingFour(
                      color: Colors.grey[200],
                    ),
                  )
                : AnimatedSwitcher(
                    child: widgetSwitcher(),
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        child: child,
                        opacity: animation,
                      );
                    },
                  )),
        floatingActionButton: !running
            ? SizedBox(
                height: 1,
                width: 1,
              )
            : FloatingActionButton(
                child: Icon(Icons.folder),
                tooltip: "Select Files",
                onPressed: () {
                  if (!loading) {
                    chooseFile();
                  }
                },
              ));
  }

  @override
  void dispose() {
    FilePicker.clearTemporaryFiles();
    // TODO: implement dispose
    super.dispose();
  }
}
