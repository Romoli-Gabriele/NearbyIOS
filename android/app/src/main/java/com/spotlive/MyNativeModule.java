package com.spotlive;

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import android.content.pm.PackageManager;
import android.os.Handler;
import java.util.Map;
import java.util.HashMap;
import android.util.Log;

// bluetooth
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;

import android.os.Looper;

// eventi
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;


public class MyNativeModule extends ReactContextBaseJavaModule {
    private ReactContext reactContext;
    private BluetoothAdapter bluetoothAdapter;
    private Handler handler;

    MyNativeModule(ReactApplicationContext context) {
        super(context);
        this.reactContext = context;
        final BluetoothManager bluetoothManager = (BluetoothManager) reactContext.getSystemService(context.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();
        handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public String getName() {
        return "MyNativeModule";
    }

    @ReactMethod
    public void start(String code) {
        if (!getReactApplicationContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            Log.e("ERROR", "BLE not allowed");
            return;
        }
        Log.d("MyModule", "start");
    }

    @ReactMethod
    public void stop() {
        Log.d("MyModule", "stop");
    }


    private void emitMessageEvent(String eventName, String message) {

        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, message);
    }
    //emitMessageEvent("onMessageFound","hello word");
}
