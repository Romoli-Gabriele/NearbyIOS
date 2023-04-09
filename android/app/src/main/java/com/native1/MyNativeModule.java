package com.native1; // replace com.your-app-name with your app’s name

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Callback;

import java.util.Map;
import java.util.HashMap;
import android.util.Log;
import android.app.Activity;

import android.bluetooth.BluetoothAdapter;

public class MyNativeModule extends ReactContextBaseJavaModule {

    private static ReactApplicationContext reactContext;

    private Message message;
    private MessageListener messageListener;

    MyNativeModule(ReactApplicationContext context) {
        super(context);
        this.reactContext = context;
    }

    @Override
    public String getName() {
        return "MyNativeModule";
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String sayHi() {
        Log.d("MyNativeModule", "bella");
        return "HI";
    }

    @ReactMethod
    public void start() {
        Log.d("MyNativeModule", "start");
    }

    @ReactMethod
    public void stop() {
        Log.d("MyNativeModule", "stop");
    }
}