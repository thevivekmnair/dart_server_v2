package com.dart_server_plugin.dart_server_plugin;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.wifi.WifiManager;
import android.location.LocationManager;
import android.os.Build;
import android.os.Handler;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;
import android.content.ComponentName;

import androidx.annotation.RequiresApi;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import java.lang.reflect.Method;
import java.net.InetAddress;
import java.util.Collections;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.List;

import io.flutter.plugin.common.MethodChannel;

import static android.content.ContentValues.TAG;


public class HotspotService{
    private Context context;
    private Activity activity;
    private  WifiManager wifiManager;
    private LocationManager locationManager;
    private WifiManager.LocalOnlyHotspotReservation mReservation;
    public MethodChannel.Result result;
    private DartServerPlugin dartServerPlugin;
    private int locationrequestCode=10;

    public HotspotService(Context context, Activity activity){

        this.context=context;
        this.activity=activity;

        wifiManager = (WifiManager) this.context.getSystemService(Context.WIFI_SERVICE);
        locationManager= (LocationManager) this.context.getSystemService(Context.LOCATION_SERVICE);
    }

//    public void  getResultVar(MethodChannel.Result result){
//        this.result=result;
//    }

    private boolean checkForLoactionPermission(){
        return ContextCompat.checkSelfPermission(context,Manifest.permission.ACCESS_COARSE_LOCATION)==PackageManager.PERMISSION_GRANTED;
    }

    private void askForLoacationPermission(){
        if(ContextCompat.checkSelfPermission(context,Manifest.permission.ACCESS_COARSE_LOCATION)==PackageManager.PERMISSION_DENIED){
            ActivityCompat.requestPermissions(activity,new String[]{Manifest.permission.ACCESS_COARSE_LOCATION},locationrequestCode);
        }
    }


    public String getWifiApIpAddress() {
        String ipAdress="";
        try {
            for (Enumeration<NetworkInterface> en = NetworkInterface.getNetworkInterfaces(); en
                    .hasMoreElements();) {
                NetworkInterface intf = en.nextElement();
                if (intf.getName().contains("wlan")) {
                    System.out.println("Heyy");
                    for (Enumeration<InetAddress> enumIpAddr = intf.getInetAddresses(); enumIpAddr
                            .hasMoreElements();) {
                        InetAddress inetAddress = enumIpAddr.nextElement();
                        System.out.println(inetAddress.getHostAddress());
                        if (!inetAddress.isLoopbackAddress()
                                && (inetAddress.getAddress().length == 4)) {
                            Log.d(TAG, inetAddress.getHostAddress());
                            ipAdress= inetAddress.getHostAddress();
                        }
                    }
                }
            }
            if(ipAdress.isEmpty()){
                try {
                    List<NetworkInterface> interfaces = Collections.list(NetworkInterface.getNetworkInterfaces());
                    for (NetworkInterface intf1 : interfaces) {
                        List<InetAddress> addrs = Collections.list(intf1.getInetAddresses());
                        for (InetAddress addr : addrs) {
                            if (!addr.isLoopbackAddress()) {
                                String sAddr = addr.getHostAddress().toUpperCase();
                                return sAddr;
                            }
                        }
                    }
                } catch (Exception ex) { } // for now eat exceptions
                return "";
            }else {
                return ipAdress;
            }
        } catch (SocketException ex) {
            System.out.println(ex.toString());
        }
        return null;
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    public void startLocalOnlyHotspot(){
        dartServerPlugin= new DartServerPlugin();
        if(mReservation!=null){
            mReservation.close();
            mReservation=null;
        }else {
            wifiManager.startLocalOnlyHotspot(new WifiManager.LocalOnlyHotspotCallback() {
                HashMap<String,String> hotspotCred=new HashMap<>();
                @Override
                public void onStarted(WifiManager.LocalOnlyHotspotReservation reservation) {
                    super.onStarted(reservation);
                    hotspotCred.clear();
                    Log.d(TAG, "Wifi Hotspot is on now");
                    mReservation = reservation;
                    String ipAdress=getWifiApIpAddress();
                    String password=mReservation.getWifiConfiguration().preSharedKey;
                    String ssid=mReservation.getWifiConfiguration().SSID;
                    System.out.println(password);
                    hotspotCred.put("ssid",ssid);
                    hotspotCred.put("password",password);
                    hotspotCred.put("ipadress",ipAdress);
                    hotspotCred.put("status","active");
                    dartServerPlugin.returnResults(hotspotCred,result);
                }

                @Override
                public void onStopped() {
                    super.onStopped();
                    hotspotCred.clear();
                    Log.d(TAG, "onStopped: ");
                    hotspotCred.put("status","deactivated");
                }

                @Override
                public void onFailed(int reason) {
//                (wifiManager.isWifiEnabled())
                    super.onFailed(reason);
                    hotspotCred.clear();
                    Toast.makeText(context, "Turn off hotspot", Toast.LENGTH_LONG).show();
                    final Intent intent=new Intent(Intent.ACTION_MAIN,null);
                    intent.addCategory(Intent.CATEGORY_LAUNCHER);
                    final ComponentName cn=new ComponentName("com.android.settings","com.android.settings.TetherSettings");
                    intent.setComponent(cn);
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    activity.startActivity(intent);
                    Log.d(TAG, "onFailed: ");
                    hotspotCred.put("status","failed");
                    dartServerPlugin.returnResults(hotspotCred,result);
                }
            }, new Handler());
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    public void turnOnHotspot(){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            if(!locationManager.isLocationEnabled()){
                Toast.makeText(context, "Turn On location", Toast.LENGTH_LONG).show();
                Intent intent= new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                activity.startActivity(intent);
            }
        }
        if(checkForLoactionPermission()){
            startLocalOnlyHotspot();
        }
        else{
            askForLoacationPermission();
        }
    }

}