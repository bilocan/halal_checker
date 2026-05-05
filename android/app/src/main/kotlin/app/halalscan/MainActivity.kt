package app.halalscan

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Register each plugin individually, catching Throwable (not just Exception).
        // GeneratedPluginRegistrant only catches Exception, so UnsatisfiedLinkError and
        // NoClassDefFoundError from native library loading crash the app — especially on
        // Huawei HMS devices that don't have Google Play Services.
        val registrations = listOf<() -> Unit>(
            { flutterEngine.plugins.add(com.llfbandit.app_links.AppLinksPlugin()) },
            { flutterEngine.plugins.add(com.mr.flutter.plugin.filepicker.FilePickerPlugin()) },
            { flutterEngine.plugins.add(io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin()) },
            { flutterEngine.plugins.add(com.github.dart_lang.jni.JniPlugin()) },
            { flutterEngine.plugins.add(com.github.dart_lang.jni_flutter.JniFlutterPlugin()) },
            { flutterEngine.plugins.add(dev.steenbakker.mobile_scanner.MobileScannerPlugin()) },
            { flutterEngine.plugins.add(io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin()) },
            { flutterEngine.plugins.add(com.tekartik.sqflite.SqflitePlugin()) },
            { flutterEngine.plugins.add(io.flutter.plugins.urllauncher.UrlLauncherPlugin()) },
        )

        for (register in registrations) {
            try {
                register()
            } catch (t: Throwable) {
                Log.e("HalalScan", "Plugin registration failed: ${t::class.java.name}: ${t.message}", t)
            }
        }
    }
}
