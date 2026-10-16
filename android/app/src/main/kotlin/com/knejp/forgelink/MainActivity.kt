package com.knejp.forgelink

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: the health plugin's permission launcher needs a ComponentActivity.
class MainActivity : FlutterFragmentActivity() {
    private var askedForNotifications = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "forgelink/system_intents")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openHealthConnectSettings" -> result.success(openHealthConnectSettings())
                    "startSyncService" -> {
                        startSyncService(
                            call.argument<String>("title") ?: "Forgelink",
                            call.argument<String>("text") ?: "",
                            call.argument<String>("channel") ?: "Sync",
                        )
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(PowerManager::class.java)
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        startActivity(
                            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                .setData(Uri.parse("package:$packageName"))
                        )
                        result.success(null)
                    }
                    "openAppDetails" -> {
                        // Holds "Pause app activity if unused" (hibernation).
                        startActivity(
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                .setData(Uri.parse("package:$packageName"))
                        )
                        result.success(null)
                    }
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            try {
                                startActivity(
                                    Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                )
                            } catch (e: android.content.ActivityNotFoundException) {
                                // No browser / Sheets app; nothing to open.
                            }
                        }
                        result.success(null)
                    }
                    "stopSyncService" -> {
                        stopService(Intent(this, SyncForegroundService::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startSyncService(title: String, text: String, channel: String) {
        // Android 13+: without this permission the service still runs, only its
        // notification is hidden. Ask once per app start.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !askedForNotifications &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            askedForNotifications = true
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
        val intent = Intent(this, SyncForegroundService::class.java)
            .putExtra(SyncForegroundService.EXTRA_TITLE, title)
            .putExtra(SyncForegroundService.EXTRA_TEXT, text)
            .putExtra(SyncForegroundService.EXTRA_CHANNEL, channel)
        startForegroundService(intent)
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
