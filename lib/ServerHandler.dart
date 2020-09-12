// import 'dart:io';
// import 'package:dart_server_v2/socket_Fileshare.dart';
// import 'FrontEnd.dart';

// class Server {
//   HttpServer server;
//   String ip_adress;
//   Function datatranfer;
//   WebSocket socket;

//   Server(Function datatransfer) {
//     this.datatranfer = datatransfer;
//   }

//   void startServer() async {
//     server = await HttpServer.bind('0.0.0.0', 8000);
//     ip_adress = hotspot['ipadress'];
//     setState(() {
//       loading = false;
//       running = true;
//     });
//     print('Server started');
//     server.listen((HttpRequest request) async {
//       print(request.uri);
//       if (request.uri.toString() == "/ws/socket") {
//         print("Hey there");

//         socket = await WebSocketTransformer.upgrade(request);
//         socket.listen((event) {
//           print('socketEvent');
//           print(event);
//           if (event.toString() == 'Vivek m nair') {
//             SocketFileShare().sendFileShare(socket, extention);
//           }
//         });
//       } else {
//         String html_String = await HtmlGen().getHtmlString('Assets/index.html',
//             'Assets/styles.css', 'head', ip_adress, img, 'li');
//         List filelist = [];
//         try {
//           Map params = request.uri.queryParameters;
//           print(params);
//           if (params.isNotEmpty) {
//             for (String filename in img) {
//               if (params[filename] != null) {
//                 filelist.add(filename);
//               }
//             }
//             print(filelist);
//             for (String val in filelist) {
//               String file_abs_path = "${extention['$val']}";
//               File _download_file = File(file_abs_path);
//               if (await _download_file.exists()) {
//                 // print(lookupMimeType(file_abs_path));
//                 // var file_stream=await _download_file.openRead();
//                 // print(file_stream);

//                 print(UriData.fromString('$val',
//                     encoding: Encoding.getByName('utf-8')));
//                 request.response
//                   ..headers.set('Content-Type',
//                       '${lookupMimeType(file_abs_path)}; charset=utf-8')
//                   ..headers.set('Content-Disposition',
//                       'attachment; filename="${UriData.fromString('$val', encoding: Encoding.getByName('utf-8'))}"');
//                 await request.response.addStream(_download_file.openRead());
//                 print('Done downloading');
//               }
//             }
//           } else {
//             request.response
//               ..headers.set('Content-Type', 'text/html; charset=utf-8')
//               ..write(html_String);
//           }
//         } finally {
//           request.response.close();
//         }
//       }
//     });
//   }
// }
