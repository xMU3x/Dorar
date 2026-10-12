// يُنفَّذ بعد `cap add android`: يضبط الأذونات، ملء الشاشة كاملة (edge-to-edge)، الاهتزاز الأصلي، وأيقونة الإشعار
const fs = require('fs'), path = require('path');
const A = 'android/app/src/main';
if (!fs.existsSync(A)) { console.log('لا يوجد android/ بعد'); process.exit(0) }
const rd = p => fs.readFileSync(p, 'utf8'), wr = (p, s) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, s) };

/* ---------- AndroidManifest ---------- */
const mp = `${A}/AndroidManifest.xml`; let x = rd(mp);
if (!x.includes('android:scheme="com.werd.habittracker"'))
  x = x.replace(/(<activity[\s\S]*?<\/intent-filter>)/, `$1
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="com.werd.habittracker" android:host="auth" />
            </intent-filter>`);
for (const perm of ['POST_NOTIFICATIONS', 'SCHEDULE_EXACT_ALARM', 'RECEIVE_BOOT_COMPLETED', 'VIBRATE', 'WAKE_LOCK'])
  if (!x.includes(`android.permission.${perm}`)) x = x.replace('</manifest>', `    <uses-permission android:name="android.permission.${perm}" />\n</manifest>`);
if (!x.includes('windowSoftInputMode')) x = x.replace(/<activity\b/, '<activity android:windowSoftInputMode="adjustResize"');
wr(mp, x);

/* ---------- الثيم: شفاف خلف شريط الحالة والتنقل ---------- */
const sp = `${A}/res/values/styles.xml`;
if (fs.existsSync(sp)) {
  let s = rd(sp);
  if (!s.includes('werd-e2e')) s = s.replace(/(<style name="AppTheme\.NoActionBar"[^>]*>)/, `$1
        <!-- werd-e2e -->
        <item name="android:statusBarColor">@android:color/transparent</item>
        <item name="android:navigationBarColor">@android:color/transparent</item>
        <item name="android:windowDrawsSystemBarBackgrounds">true</item>
        <item name="android:enforceNavigationBarContrast">false</item>
        <item name="android:enforceStatusBarContrast">false</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>`);
  wr(sp, s);
}

/* ---------- أيقونة الإشعار (أحادية اللون) ---------- */
wr(`${A}/res/drawable/ic_stat_werd.xml`, `<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
  <path android:fillColor="#FFFFFFFF" android:pathData="M12,2C11,4 10,5 10,6.5C10,7.9 10.9,9 12,9C13.1,9 14,7.9 14,6.5C14,5 13,4 12,2zM4,22L4,11L6,9L8,11L8,22zM16,22L16,11L18,9L20,11L20,22zM8,22L8,15C8,12.8 9.8,11 12,11C14.2,11 16,12.8 16,15L16,22L14,22L14,19L10,19L10,22z"/>
</vector>
`);

/* ---------- Java: MainActivity + WerdNative ---------- */
const pk = 'com.werd.habittracker', jd = `${A}/java/${pk.replace(/\./g, '/')}`;
wr(`${jd}/MainActivity.java`, `package ${pk};

import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(WerdNative.class);
        super.onCreate(savedInstanceState);
    }
}
`);
wr(`${jd}/WerdNative.java`, `package ${pk};

import android.content.Context;
import android.graphics.Color;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.os.VibratorManager;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

/** ملء الشاشة بالكامل + اهتزاز أصلي دقيق (نبضات مثل Flutter/Material) */
@CapacitorPlugin(name = "WerdNative")
public class WerdNative extends Plugin {
    private int top = 0, bottom = 0, kb = 0;
    private Vibrator vib;

    @Override
    public void load() {
        getActivity().runOnUiThread(() -> {
            Window w = getActivity().getWindow();
            WindowCompat.setDecorFitsSystemWindows(w, false);
            w.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            w.setStatusBarColor(Color.TRANSPARENT);
            w.setNavigationBarColor(Color.TRANSPARENT);
            if (Build.VERSION.SDK_INT >= 29) { w.setNavigationBarContrastEnforced(false); w.setStatusBarContrastEnforced(false); }
            if (Build.VERSION.SDK_INT >= 28) w.getAttributes().layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            final View root = w.getDecorView();
            ViewCompat.setOnApplyWindowInsetsListener(root, (v, ins) -> {
                Insets sb = ins.getInsets(WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.displayCutout());
                Insets ime = ins.getInsets(WindowInsetsCompat.Type.ime());
                float d = getActivity().getResources().getDisplayMetrics().density;
                top = Math.round(sb.top / d);
                bottom = Math.round(sb.bottom / d);
                kb = ime.bottom > sb.bottom ? Math.round((ime.bottom - sb.bottom) / d) : 0;
                notifyListeners("insets", data());
                return ins;
            });
            ViewCompat.requestApplyInsets(root);
        });
        Context c = getContext();
        if (Build.VERSION.SDK_INT >= 31) {
            VibratorManager vm = (VibratorManager) c.getSystemService(Context.VIBRATOR_MANAGER_SERVICE);
            vib = vm != null ? vm.getDefaultVibrator() : null;
        } else vib = (Vibrator) c.getSystemService(Context.VIBRATOR_SERVICE);
    }

    private JSObject data() { JSObject o = new JSObject(); o.put("top", top); o.put("bottom", bottom); o.put("kb", kb); return o; }

    @PluginMethod
    public void insets(PluginCall call) { call.resolve(data()); }

    /** dark = المظهر داكن → أيقونات فاتحة */
    @PluginMethod
    public void bars(PluginCall call) {
        final boolean dark = Boolean.TRUE.equals(call.getBoolean("dark", false));
        getActivity().runOnUiThread(() -> {
            Window w = getActivity().getWindow();
            WindowInsetsControllerCompat c = WindowCompat.getInsetsController(w, w.getDecorView());
            c.setAppearanceLightStatusBars(!dark);
            c.setAppearanceLightNavigationBars(!dark);
        });
        call.resolve();
    }

    /** type: tick | click | heavy | success | error | select */
    @PluginMethod
    public void haptic(PluginCall call) {
        String t = call.getString("type", "click");
        try {
            if (vib == null || !vib.hasVibrator()) { call.resolve(); return; }
            if (Build.VERSION.SDK_INT >= 29) {
                VibrationEffect e;
                switch (t) {
                    case "tick": case "select": e = VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK); break;
                    case "heavy": e = VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK); break;
                    case "success": e = VibrationEffect.createWaveform(new long[]{0, 18, 55, 34}, new int[]{0, 160, 0, 255}, -1); break;
                    case "error": e = VibrationEffect.createWaveform(new long[]{0, 40, 50, 40, 50, 60}, new int[]{0, 255, 0, 255, 0, 255}, -1); break;
                    default: e = VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK);
                }
                vib.vibrate(e);
            } else if (Build.VERSION.SDK_INT >= 26) {
                long ms = t.equals("heavy") ? 40 : t.equals("tick") || t.equals("select") ? 8 : t.equals("success") ? 30 : t.equals("error") ? 70 : 16;
                vib.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE));
            } else vib.vibrate(16);
        } catch (Exception ignored) { }
        call.resolve();
    }
}
`);
console.log('تم تحديث مشروع الأندرويد ✔ (Manifest + ثيم شفاف + أيقونة الإشعار + WerdNative)');
