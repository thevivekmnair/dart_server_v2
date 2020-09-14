import 'dart:convert';
import 'dart:io';
import 'package:dart_server_v2/socket_Fileshare.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'FrontEnd.dart';
import 'package:dart_server_plugin/dart_server_plugin.dart';
import 'package:mime/mime.dart';

import 'ShareFilesScreen.dart';

class ServerHandler {
  HttpServer server;
  String ip_adress;
  Function datatranfer;
  WebSocket socket;
  List<String> file_path = [];
  Map<String, String> extention;
  Map hotspot = {};
  SocketFileShare socketFileShare;
  var img = [];
  Stopwatch stopwatch = Stopwatch();
  Function interFuncdataShare;
  BuildContext buildContext;
  ServerHandler server_Handler;
  bool alreadyDidNavigation = false;
  Function sendMapFiles;
  Function progressUpdateFunction;
  double percentageCalc = 0.0;

  ServerHandler(this.interFuncdataShare) {
    socketFileShare = SocketFileShare();
  }

  Stream<List<int>> downloadStream(
      Stream<List<int>> stream, int filelegth, String filename) async* {
    int count = 0;
    await for (var value in stream) {
      count += value.length;
      percentageCalc = (count / filelegth) * 100;
      progressUpdateFunction(filename, percentageCalc);
      yield value;
    }
    print(count);
  }

  void sendDownloadCompletedMsg(WebSocket wbs) {
    print("called...");
    Map<String, String> download_msg = {};
    download_msg.addAll({"type": "downloadpermission", "data": 'true'});
    wbs.add(jsonEncode(download_msg));
  }

  void serverHandler() async {
    interFuncdataShare(1, loaDing: true);
    hotspot = await DartServerPlugin.enableHotspot;
    if (hotspot == null) {
      interFuncdataShare(1, loaDing: false);
      return;
    }
    server = await HttpServer.bind('0.0.0.0', 8000);
    ip_adress = hotspot['ipadress'];
    interFuncdataShare(2, loaDing: false, runNing: true);
    interFuncdataShare(3, ipaDress: ip_adress);
    print('Server started');
    server.listen((HttpRequest request) async {
      print(request.uri);
      if (request.uri.toString() == "/ws/socket") {
        print("Hey there");
        socket = await WebSocketTransformer.upgrade(request).then((value) {
          extention = null;
          if (alreadyDidNavigation) {
            Navigator.pop(buildContext);
            Navigator.push(
                buildContext,
                MaterialPageRoute(
                  builder: (context) => ShareFilesScreen(server_Handler),
                ));
          } else {
            alreadyDidNavigation = true;
            Navigator.push(
                buildContext,
                MaterialPageRoute(
                  builder: (context) => ShareFilesScreen(server_Handler),
                ));
          }
          return value;
        });
        socket.listen((event) {
          print('socketEvent');
          print(event);
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
              socketFileShare.toggle_donwnload_permission(false);
              start_time = stopwatch.elapsedMilliseconds;
              print(UriData.fromString('$val',
                  encoding: Encoding.getByName('utf-8')));
              request.response
                ..headers.set('Content-Type',
                    '${lookupMimeType(file_abs_path)}; charset=utf-8')
                ..headers.set('Content-Length', '$file_length')
                ..headers.set('Content-Disposition',
                    'attachment; filename="${UriData.fromString('$val', encoding: Encoding.getByName('utf-8'))}"');
              await request.response.addStream(
                  downloadStream(_download_file.openRead(), file_length, val));
              stop_time = stopwatch.elapsedMilliseconds;
              while (stop_time - start_time < 1000) {
                stop_time = stopwatch.elapsedMilliseconds;
              }
              socketFileShare.toggle_donwnload_permission(true);
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

  void chooseFile(Function loadingFunc, Function mapFilesUpdateFunc,
      Function progressUpdateFunc) async {
    //Select files
    progressUpdateFunction = progressUpdateFunc;
    loadingFunc(true);
    Map<String, String> fileMap = await DartServerPlugin.openFileManager;

    if (fileMap != null) {
      fileMap.forEach((key, value) {
        print(value);
      });
      print('before....');
      loadingFunc(false);
      print('after....');
      extention == null ? extention = fileMap : extention.addAll(fileMap);
      print(fileMap.values.toList());
      print(fileMap.keys.toList());
      img.addAll(fileMap.keys.toList());

      if (socket != null) {
        socketFileShare.sendFileShare(
            socket, extention, 'fileupdate', mapFilesUpdateFunc);
      }
    } else {
      loadingFunc(false);
    }
  }

  void stopServer() async {
    if (server != null) {
      await server.close();
      interFuncdataShare(2, loaDing: false, runNing: false);
      print('Server stopped');
    }
  }
}
