package com.getui.syncalendar;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.modules.core.PermissionAwareActivity;
import com.facebook.react.modules.core.PermissionListener;

import javax.annotation.Nonnull;

public class CalendarModule extends ReactContextBaseJavaModule {
    private static final String ModuleName = "CalendarModule";
    private static final String TAG = "CalendarModule";

    private static Context mContext;
    private static CalendarReminderUtils utils;
    protected static ReactApplicationContext mRAC;
    private static boolean flag = false;
    private static final int CALENDAR_WR_PERMISSION_REQUEST = 1;
    private PermissionListener calendarWrPermissonListner = new PermissionListener() {
        @Override
        public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
            switch (requestCode) {
                case CALENDAR_WR_PERMISSION_REQUEST: {
                    // If request is cancelled, the result arrays are empty.
                    if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                        flag = true;
                    } else {
                        Toast.makeText(getCurrentActivity().getApplicationContext(), "calendar permission denied...", Toast.LENGTH_LONG).show();
                    }
                    return true;
                }
            }
            return false;
        }
    };


    public CalendarModule(ReactApplicationContext reactContext) {
        super(reactContext);
        mRAC = reactContext;
        mContext = reactContext;
        utils = new CalendarReminderUtils(mContext);
    }

    @Nonnull
    @Override
    public String getName() {
        return CalendarModule.ModuleName;
    }

    @Override
    public void initialize() {
        super.initialize();
    }

    @Override
    public void onCatalystInstanceDestroy() {
        super.onCatalystInstanceDestroy();
    }

    /**
     * utils
     */
    public void initCalendar(Context context) {
        utils = new CalendarReminderUtils(context);
        Log.d(TAG, "init calendar utils...");
    }


    @ReactMethod
    public void addCalendarEvent(ReadableMap map, Callback callback) {
        long startTime = Long.valueOf(map.getString("startTime"));
        long endTime = Long.valueOf(map.getString("endTime"));
        Log.d(TAG, map.toString());
        if(grantCalendarPermisson()) {
            String result = utils.addCalendarEvent(
                    map.getString("id"),
                    map.getString("title"),
                    map.getString("location"),
                    startTime,
                    endTime,
                    map.getArray("alarm"));
            callback.invoke(map.toString() + '\n' + result);
        } else  {
            callback.invoke(map.toString() + '\n' + "calendar permission denied!");
        }
    }


    public boolean grantCalendarPermisson() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true;
        }

        boolean result = true;
        if (ContextCompat.checkSelfPermission(getCurrentActivity(),
                Manifest.permission.READ_CALENDAR) != PackageManager.PERMISSION_GRANTED
                || ContextCompat.checkSelfPermission(getCurrentActivity(),
                Manifest.permission.WRITE_CALENDAR) != PackageManager.PERMISSION_GRANTED) {
            result = false;
        }

        if (!result) {
            PermissionAwareActivity activity = getPermissionAwareActivity();
            activity.requestPermissions(new String[]{Manifest.permission.READ_CALENDAR,
                    Manifest.permission.WRITE_CALENDAR}, CALENDAR_WR_PERMISSION_REQUEST, calendarWrPermissonListner);
        }

        return result;
    }

    private PermissionAwareActivity getPermissionAwareActivity() {
        Activity activity = getCurrentActivity();
        if (activity == null) {
            throw new IllegalStateException("Tried to use permissions API while not attached to an Activity.");
        } else if (!(activity instanceof PermissionAwareActivity)) {
            throw new IllegalStateException("Tried to use permissions API but the host Activity doesn't implement PermissionAwareActivity.");
        }
        return (PermissionAwareActivity) activity;
    }
}
