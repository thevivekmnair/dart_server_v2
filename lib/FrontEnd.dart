
import 'package:flutter/services.dart';
import 'dart:core';

class HtmlGen{
  String addData(){
      print('object');
    }


  Future<String> getHtmlString(String htmlfile,String cssfile,String styleid,List images,String listId)async{
  
    String css_string=await rootBundle.loadString(cssfile);
    String html_string=await rootBundle.loadString(htmlfile);
    List<String>spiltforstyle=html_string.split('id="$styleid">');
    String css_concat='<style>$css_string</style>';
    String eddited=spiltforstyle[0]+'id="$styleid">'+css_concat+spiltforstyle[1];
    //adding selected values
    List<String>spiltlist=eddited.split('id="$listId">');
    String list_concat=addLIelements(images, listId);
    eddited=spiltlist[0]+'id="$listId">'+list_concat+spiltlist[1];
    return eddited;
  }

  String addLIelements(List images,String id){
    String result='';
    for(String img in images){
      result+='<li><label for="$img"><h3>${img}</h3></label><button class="DownloadButton" name="$img" id="$img" value="selected">Download</button></li>';
    }
  return result;
  }


}