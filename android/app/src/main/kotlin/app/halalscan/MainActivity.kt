package app.halalscan

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // GeneratedPluginRegistrant uses the correct initialization order and handles
        // each plugin's internal setup. Wrap in Throwable (not just Exception) so
        // UnsatisfiedLinkError / NoClassDefFoundError from native libraries on Huawei
        // HMS devices without Google Play Services don't crash the app.
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (t: Throwable) {
            Log.e("HalalScan", "Plugin registration failed: ${t::class.java.name}: ${t.message}", t)
        }
    }
}
