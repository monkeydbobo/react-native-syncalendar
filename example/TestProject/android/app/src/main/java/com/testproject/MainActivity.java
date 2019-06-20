package com.testproject;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.ActivityCompat;

import com.facebook.react.ReactActivity;

public class MainActivity extends ReactActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        requestPermission();
    }

    /**
     * Returns the name of the main component registered from JavaScript.
     * This is used to schedule rendering of the component.
     */

    @Override
    protected String getMainComponentName() {
        return "TestProject";
    }

    private void requestPermission() {
        boolean WRITE_CALENDAR =
                getPackageManager().checkPermission(Manifest.permission.WRITE_CALENDAR, getPackageName()) == PackageManager.PERMISSION_GRANTED;

        boolean READ_CALENDAR =
                getPackageManager().checkPermission(Manifest.permission.READ_CALENDAR, getPackageName()) == PackageManager.PERMISSION_GRANTED;
        if (Build.VERSION.SDK_INT >= 23 && !WRITE_CALENDAR && !READ_CALENDAR) {
            // Android 版本高于6.0，且没有相机权限，则需要进行动态权限的申请
            requestPermissions(new String[]{Manifest.permission.READ_CALENDAR,Manifest.permission.WRITE_CALENDAR},0);
        }

    }
}
