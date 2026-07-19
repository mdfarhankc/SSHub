package com.mdfarhankc.sshub

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity(), SecurePlatformApi {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Before Flutter starts, so launch is never capturable.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SecurePlatformApi.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
    }

    override fun setBlockScreenshots(enabled: Boolean) {
        runOnUiThread {
            if (enabled) {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }

    // Keyboards show a placeholder instead of the text. Android 12+.
    override fun copySensitive(text: String) {
        val clipboard =
            getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("SSHub", text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val key =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    ClipDescription.EXTRA_IS_SENSITIVE
                } else {
                    "android.content.extra.IS_SENSITIVE"
                }
            clip.description.extras = PersistableBundle().apply {
                putBoolean(key, true)
            }
        }
        clipboard.setPrimaryClip(clip)
    }
}
