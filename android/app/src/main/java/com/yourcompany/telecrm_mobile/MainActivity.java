package com.example.telecrm_mobile;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.provider.Settings;
import android.content.pm.PackageManager;
import android.Manifest;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "telecrm/direct_call";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("makeDirectCall")) {
                        String phoneNumber = call.argument("phoneNumber");
                        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
                                != PackageManager.PERMISSION_GRANTED) {
                            result.error("PERMISSION_DENIED", "CALL_PHONE permission not granted", null);
                            return;
                        }

                        Intent callIntent = new Intent(Intent.ACTION_CALL);
                        callIntent.setData(Uri.parse("tel:" + phoneNumber));
                        callIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        startActivity(callIntent);
                        result.success(true);

                    } else if (call.method.equals("requestCallPermissions")) {
                        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
                                == PackageManager.PERMISSION_GRANTED) {
                            result.success(true);
                        } else {
                            ActivityCompat.requestPermissions(this,
                                    new String[]{Manifest.permission.CALL_PHONE}, 1);
                            result.success(false);
                        }
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
