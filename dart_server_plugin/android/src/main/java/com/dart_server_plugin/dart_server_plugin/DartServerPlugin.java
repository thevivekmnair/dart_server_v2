package com.dart_server_plugin.dart_server_plugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static android.app.Activity.RESULT_OK;

/** DartServerPlugin */
public class DartServerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context context;
  private Activity activity;
  private Result resultvar;
  private FileService fileService;
  private HotspotService hotspotService;
  private ActivityPluginBinding activityPluginBinding;

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activityPluginBinding=binding;
    this.activity=binding.getActivity();
    binding.addRequestPermissionsResultListener(this);
    binding.addActivityResultListener(this);
    hotspotService=new HotspotService(context,activity);

  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {
    activityPluginBinding.removeActivityResultListener(null);
    activityPluginBinding.addRequestPermissionsResultListener(null);
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "dart_server_plugin");
    channel.setMethodCallHandler(this);
    context=flutterPluginBinding.getApplicationContext();
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "dart_server_plugin");
    channel.setMethodCallHandler(new DartServerPlugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + Build.VERSION.RELEASE);
    }
    else if(call.method.equals("OpenFileManager")){
        resultvar=result;
        fileService= new FileService(this.activity,context,resultvar);
        fileService.OpenFileManager();
    }
    else if(call.method.equals("turnOnHotspot")){
        resultvar=result;
//        hotspotService=new HotspotService(context,activity);
        hotspotService.result=resultvar;
        hotspotService.turnOnHotspot();
    }
    else {
      result.notImplemented();
    }
  }

  public void returnResults(@Nullable HashMap<String,String> files, Result result){
    result.success(files);
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    switch (requestCode){
      case 20:
        System.out.println(resultCode);
        if(resultCode==RESULT_OK){
          fileService.pathFetcher(data);
        }else {
          final HashMap<String,String> paths = new HashMap<>();
          paths.put("null","null");
          resultvar.success(paths);
        }
        break;
      case 50:
        System.out.println("Hotspot....");
        if(hotspotService.checkHotspotState()){
          System.out.println("if...");
          hotspotService.turnOnMobileHotspot();
        }else{
          System.out.println("else...");
          HashMap<String,String> hotspotCred=new HashMap<>();
          hotspotCred.put("ipadress","null");
          resultvar.success(hotspotCred);
        }
        break;
    }
    return true;
  }

  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {

    switch (requestCode){
      case 10:
        if(PackageManager.PERMISSION_GRANTED==grantResults[0]){
          hotspotService.result=resultvar;
        }
        break;
      case 100:
        if (PackageManager.PERMISSION_GRANTED==grantResults[0]){
          fileService.startFileManagerActivity();
        }
        break;
    }

    return true;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
