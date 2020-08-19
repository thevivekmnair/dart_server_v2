
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:wifi/wifi.dart';
import 'package:url_launcher/url_launcher.dart';
import 'FrontEnd.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(MaterialApp(
    home:DartServer()
  ));
}

class DartServer extends StatefulWidget {
  @override
  _DartServerState createState() => _DartServerState();
}

class _DartServerState extends State<DartServer> {

bool loading=false;
bool running=false;
String ip_adress='';


 HttpServer server;
 var img=[];
 List<String> file_path=[];
 Map<String,String> extention;


                //Server statrter function
  void startServer()async{
    // Directory directory=Directory('/storage/');
    // await directory.list().forEach((FileSystemEntity element)=>print(element));
    setState(() {
      loading=true;
    });
   server=await HttpServer.bind('0.0.0.0', 8000);
   ip_adress= await Wifi.ip;
   setState((){
     loading=false;
     running=true;
   });
   print('Server started');
   server.listen((HttpRequest request) async{
     String html_String=await HtmlGen().getHtmlString('Assets/index.html', 'Assets/styles.css','head',img,'li');
     List filelist=[];
     try{
       Map params=request.uri.queryParameters;
       print(params);
       if(params.isNotEmpty){
       for(String filename in img){
        if(params[filename]!=null){
          filelist.add(filename);
        }
       }
       print(filelist);
       for(String val in filelist){
       String file_abs_path="${extention['$val']}";
       File _download_file=File(file_abs_path);
        if(await _download_file.exists()){
          // print(lookupMimeType(file_abs_path));
        // var file_stream=await _download_file.openRead();
        // print(file_stream);
        print(UriData.fromString('$val',encoding: Encoding.getByName('utf-8')));
        request.response
        ..headers.set('Content-Type', '${lookupMimeType(file_abs_path)}; charset=utf-8')
        ..headers.set('Content-Disposition', 'attachment; filename="${ UriData.fromString('$val',encoding: Encoding.getByName('utf-8'))}"');
        await request.response.addStream(_download_file.openRead());
        print('Done downloading');
         }
        
         
       }
       }else{
       request.response
       ..headers.set('Content-Type', 'text/html; charset=utf-8')
       ..write(html_String);
       }
     }finally{
       request.response.close();
     }
    });
    
  }

  void chooseFile()async{                          //Select files
    setState(() {
      loading=true;
    });
    Map<String,String> fileMap= await FilePicker.getMultiFilePath(
      type: FileType.any,
    );
    if(fileMap!=null){
    setState(() {
      loading=false;
      extention==null?extention=fileMap:extention.addAll(fileMap);
      print(fileMap.values.toList());
      print(fileMap.keys.toList());
      img.addAll(fileMap.keys.toList());
    });
    }else{
      setState(() {
        loading=false;
      });
    }
  }

  void stopServer()async{
    if(running){
    await server.close();
    setState(() {
      running=false;
    });
    print('Server stopped');
    }
  }

  Widget loadSwitcher(int i){
    if(i==0){
    return loading?Text('Loading...'):Text('Start Server',style: TextStyle(color: Colors.white),);
    }
    else{
      return running?Text('Server is running!!',style: TextStyle(fontSize: 22,color: Colors.blue),):Text('');
    }
  }

  Widget widgetSwitcher(){
    switch(running){
      case false:
        return MaterialButton(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_tethering,color: Colors.grey[500],),
              Icon(Icons.computer,color: Colors.grey[500],),
              Text('Tap to start server sharing',style: TextStyle(
                color: Colors.grey[100],fontSize: 18
              ),)
            ],
          ),
          onPressed:(){
                if(!running){
                startServer();
                }
              },
        );
      case true:
        return MaterialButton(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_tethering,color: Colors.grey[300],),
              Icon(Icons.computer,color: Colors.grey[300],),
              Text('Tap to stop server sharing',style: TextStyle(
                color: Colors.grey[100],fontSize: 18
              ),),
              SizedBox
            ],
          ),
          onPressed:stopServer
        );
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
        child: loading?Container(child: SpinKitFadingFour(color: Colors.grey[200],),): widgetSwitcher()
      ),
      floatingActionButton: !running?SizedBox(height: 1,width: 1,):FloatingActionButton(
        child: Icon(Icons.folder),
        tooltip: "Select Files",
        onPressed: chooseFile,
      )
    );
  }
}