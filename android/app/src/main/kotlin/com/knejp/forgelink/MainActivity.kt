package com.knejp.forgelink

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: the health plugin's permission launcher needs a ComponentActivity.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "forgelink/system_intents")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openHealthConnectSettings" -> result.success(openHealthConnectSettings())
                    else -> result.notImplemented()
                }
            }
    }

    // Tries the Health Connect settings screen, then the HC app, then its
    // app-details page. Returns false when none of them resolves.
    private fun openHealthConnectSettings(): Boolean {
        val intents = listOf(
            Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"),
            packageManager.getLaunchIntentForPackage("com.google.android.apps.healthdata"),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:com.google.android.apps.healthdata")
            },
        ).filterNotNull()

        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(packageManager) == null) continue
            startActivity(intent)
            return true
        }

        return false
    }
}
