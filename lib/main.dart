import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:dart_server_v2/socket_Fileshare.dart';
import 'package:dart_server_v2/ServerHandler.dart';
import 'package:flare_flutter/flare_actor.dart';

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
  ServerHandler server_Handler;
  bool webSocConnected = false;
  BuildContext buildContext;

  _DartServerState() {
    socketFileShare = SocketFileShare();
    server_Handler = ServerHandler(interFuncdataShare);
    server_Handler.server_Handler = server_Handler;
  }

  void interFuncdataShare(int condition,
      {bool loaDing, bool runNing, String ipaDress, bool conNected}) {
    switch (condition) {
      case 1:
        setState(() {
          loading = loaDing;
        });
        break;
      case 2:
        setState(() {
          loading = loaDing;
          running = runNing;
        });
        break;
      case 3:
        setState(() {
          ip_adress = ipaDress;
        });
        break;
      case 4:
        setState(() {
          print("Connected..");
          webSocConnected = conNected;
        });
        break;
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
        return GestureDetector(
          key: UniqueKey(),
          onTap: () {
            if (!running) {
              server_Handler.serverHandler();
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_tethering,
                color: Colors.grey[500],
                size: 50,
              ),
              Icon(
                Icons.computer,
                color: Colors.grey[500],
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'Tap to start sharing',
                style: TextStyle(color: Colors.grey[100], fontSize: 18),
              )
            ],
          ),
        );
      case true:
        return Column(
          key: UniqueKey(),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 1,
                  sigmaY: 1,
                ),
                child: Container(
                    padding: EdgeInsets.fromLTRB(9, 12, 9, 12),
                    height: MediaQuery.of(context).size.height / 2,
                    width: MediaQuery.of(context).size.width / 1.2,
                    color: Colors.black.withOpacity(0.2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Connect your computer to your mobile hotspot',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 22,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 50,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.height / 10,
                          height: MediaQuery.of(context).size.height / 10,
                          child: FlareActor(
                            'Assets/check_connection.flr',
                            animation: 'loading',
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 50,
                        ),
                        Text(
                          "Then search for the below address on your chrome browser's address bar",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 22,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                          child: Text(
                            "$ip_adress:8000",
                            style: TextStyle(
                                fontSize: 25, color: Colors.greenAccent[400]),
                          ),
                        )
                      ],
                    )),
              ),
              clipBehavior: Clip.hardEdge,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
              minWidth: 50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              color: Color(0xff283747),
              child: Text(
                'Stop sharing',
                style: TextStyle(color: Colors.grey[300], fontSize: 20),
              ),
              onPressed: () {
                server_Handler.stopServer();
              },
            )
          ],
        );

      default:
        return Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    server_Handler.buildContext = context;
    return Scaffold(
      backgroundColor: Color(0xff1B2631),
      appBar: AppBar(
        title: Text('ChromeSpot'),
        backgroundColor: Color(0xff283747),
        centerTitle: true,
      ),
      body: Center(
          child: AnimatedSwitcher(
        duration: Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return SizeTransition(
            axis: Axis.horizontal,
            axisAlignment: 0.0,
            sizeFactor: animation,
            child: child,
          );
        },
        child: loading
            ? Container(
                key: UniqueKey(),
                child: SpinKitFadingFour(
                  color: Colors.grey[200],
                ),
              )
            : widgetSwitcher(),
      )),
    );
  }
}
