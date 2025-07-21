package com.yourcompany.telecrm_mobile;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.telecom.TelecomManager;
import android.telephony.TelephonyManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.Manifest;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class DirectCallHandler implements MethodChannel.MethodCallHandler {
    private final Context context;

    public DirectCallHandler(Context context) {
        this.context = context;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("makeDirectCall")) {
            String number = call.argument("phoneNumber");
            makeCall(number, result);
        } else if (call.method.equals("isDirectCallSupported")) {
            result.success(true); // basic support check
        } else if (call.method.equals("endCall")) {
            result.success(false); // implement if needed
        } else if (call.method.equals("getCallState")) {
            result.success("UNKNOWN"); // implement if needed
        } else {
            result.notImplemented();
        }
    }

    private void makeCall(String number, MethodChannel.Result result) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "CALL_PHONE permission not granted", null);
            return;
        }

        Intent callIntent = new Intent(Intent.ACTION_CALL);
        callIntent.setData(Uri.parse("tel:" + number));
        callIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            context.startActivity(callIntent);
            result.success(true);
        } catch (Exception e) {
            result.error("CALL_FAILED", e.getMessage(), null);
        }
    }
}
