package com.dart_server_plugin.dart_server_plugin;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import javax.xml.transform.Result;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import static android.app.Activity.RESULT_OK;

public class FileService{
    private Activity activity;
    private Context context;
    private int storageIntentCode =20;
    private int storagepermissionCode=100;
    private DartServerPlugin dartServerPlugin;
    private MethodChannel.Result result;

    public FileService(Activity activity, Context context, MethodChannel.Result result){

        this.activity=activity;
        this.context=context;
        this.result=result;

    }

    private boolean checkStoragePermission(){

        return ContextCompat.checkSelfPermission(context, Manifest.permission.READ_EXTERNAL_STORAGE)== PackageManager.PERMISSION_GRANTED;

    }

    private void requestStoragePermission(){

        if(ContextCompat.checkSelfPermission(context, Manifest.permission.READ_EXTERNAL_STORAGE)== PackageManager.PERMISSION_DENIED){
            System.out.println("No permission");
            ActivityCompat.requestPermissions(activity,new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,},storagepermissionCode);

        }

    }

    public void startFileManagerActivity(){
        Intent intent=new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("*/*");
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE,true);
        activity.startActivityForResult(intent,storageIntentCode);
    }

    public void OpenFileManager(){

        if(checkStoragePermission()){
            startFileManagerActivity();
        }
        else {
            requestStoragePermission();
        }

    }

    void pathFetcher(Intent data){
        System.out.println("Inside path fetcher");
        if(data!=null){
            final HashMap<String,String> paths = new HashMap<>();
            if(data.getClipData()!=null) {
                final int count = data.getClipData().getItemCount();
                for (int i = 0; i < count; i++) {
                    final Uri currentUri = data.getClipData().getItemAt(i).getUri();
                    String file_path=filePathMaker(currentUri);
                    String fileName=file_path.split("/")[file_path.split("/").length-1];
                    paths.put(fileName,file_path);
                }
            }else {
                String file_path=filePathMaker(data.getData());
                String fileName=file_path.split("/")[file_path.split("/").length-1];
                paths.put(fileName,file_path);
            }
            dartServerPlugin = new DartServerPlugin();
            dartServerPlugin.returnResults(paths, result);
        }else {
            final HashMap<String,String> paths = new HashMap<>();
            paths.put("null","null");
            dartServerPlugin.returnResults(paths,result);
        }
    }

    private String filePathMaker(Uri uri){
        String docstr= null;
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            docstr = DocumentsContract.getDocumentId(uri);
        }
        String[] split=docstr.split(":");
        String envDir= Environment.getExternalStorageDirectory().toString();
        System.out.println(docstr);
        System.out.println(split[0]);
        if(isExternalStorageDocument(uri) && split[0].equalsIgnoreCase("primary")){
            return envDir+(split.length>1?("/"+split[1]):"");
        }else if (isDownloadsDocument(uri) && split[0].equalsIgnoreCase("raw")){
            return split[1];
        }else if(isMediaDocument(uri)){
            final String selection = MediaStore.Images.Media._ID + "=?";
            final String[] selectionArgs = new String[]{
                    split[1]
            };
            Uri imguri=null;
            if (split[0].equalsIgnoreCase("image")){
                imguri=MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                System.out.println(imguri);
            }else if(split[0].equalsIgnoreCase("audio")){
                imguri=MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
            }else if(split[0].equalsIgnoreCase("video")){
                imguri=MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
            }
            return getDataColumn(context, imguri, selection, selectionArgs);
        }
        else {
            return "/"+envDir.split("/")[1]+(split.length>1?("/"+split[0]+"/"+split[1]):"");
        }

    }

    private static String getDataColumn(final Context context, final Uri uri, final String selection,
                                        final String[] selectionArgs) {
        Cursor cursor = null;
        final String column = MediaStore.Images.Media.DATA;
        final String[] projection = {
                column
        };
        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs,
                    null);
            if (cursor != null && cursor.moveToFirst()) {
                final int index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(index);
            }
        } catch (final Exception ex) {
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
        return null;
    }

    private static boolean isExternalStorageDocument(final Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    private static boolean isDownloadsDocument(final Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    private static boolean isMediaDocument(final Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }


}