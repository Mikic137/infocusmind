package com.infocusmind.mobile

import android.Manifest
import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.role.RoleManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.infocusmind.mobile/usage"
    private val NOTIF_CHANNEL_ID = "infocusmind_focus_session"
    private val NOTIF_ID = 1001
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsagePermission" -> {
                    result.success(checkUsagePermission())
                }
                "isDefaultLauncher" -> {
                    try {
                        val alias = ComponentName(this, "$packageName.LauncherAlias")
                        val state = packageManager.getComponentEnabledSetting(alias)
                        if (state == PackageManager.COMPONENT_ENABLED_STATE_DISABLED) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
                        val resolveInfo = packageManager.resolveActivity(homeIntent, PackageManager.MATCH_DEFAULT_ONLY)
                        val isDefault = resolveInfo?.activityInfo?.packageName == packageName
                        result.success(isDefault)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "wasLaunchedFromHome" -> {
                    try {
                        val alias = ComponentName(this, "$packageName.LauncherAlias")
                        val state = packageManager.getComponentEnabledSetting(alias)
                        val isEnabled = state != PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                        val isHome = intent?.hasCategory(Intent.CATEGORY_HOME) == true && isEnabled
                        result.success(isHome)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openUsageSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getUsageDuring" -> {
                    val start = call.argument<Long>("startTime") ?: 0L
                    val end = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                    val apps = getUsageStatsBetween(start, end)
                    result.success(apps)
                }
                "getInstalledApps" -> {
                    val apps = getLaunchableApps()
                    result.success(apps)
                }
                "showFocusNotification" -> {
                    val title = call.argument<String>("title") ?: "Sesión de estudio"
                    val time = call.argument<String>("time") ?: ""
                    showFocusNotification(title, time)
                    result.success(true)
                }
                "cancelFocusNotification" -> {
                    cancelFocusNotification()
                    result.success(true)
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1002)
                        }
                    }
                    result.success(true)
                }
                "launchApp" -> {
                    val pkg = call.argument<String>("package") ?: ""
                    val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launchIntent)
                        result.success(true)
                    } else {
                        result.error("NOT_FOUND", "No se pudo abrir la app", null)
                    }
                }
                "openHomeSettings" -> {
                    try {
                        val alias = ComponentName(this, "$packageName.LauncherAlias")
                        packageManager.setComponentEnabledSetting(
                            alias,
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                            PackageManager.DONT_KILL_APP
                        )
                    } catch (e: Exception) {
                        // ignore
                    }
                    try {
                        val intent = Intent(Settings.ACTION_HOME_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val fallback = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(fallback)
                            result.success(true)
                        } catch (e2: Exception) {
                            try {
                                val homeChooser = Intent(Intent.ACTION_MAIN).apply {
                                    addCategory(Intent.CATEGORY_HOME)
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(Intent.createChooser(homeChooser, "¿Qué aplicación usar como pantalla de inicio?"))
                                result.success(true)
                            } catch (e3: Exception) {
                                result.error("ERROR", e3.message, null)
                            }
                        }
                    }
                }
                "disableLauncher" -> {
                    try {
                        val alias = ComponentName(this, "$packageName.LauncherAlias")
                        packageManager.setComponentEnabledSetting(
                            alias,
                            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                            PackageManager.DONT_KILL_APP
                        )
                        packageManager.clearPackagePreferredActivities(packageName)

                        // Volver a la pantalla de inicio del sistema
                        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(homeIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_HOME_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "openDefaultAppsSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_HOME_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val fallback = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(fallback)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.hasCategory(Intent.CATEGORY_HOME)) {
            val alias = ComponentName(this, "$packageName.LauncherAlias")
            val state = packageManager.getComponentEnabledSetting(alias)
            if (state != PackageManager.COMPONENT_ENABLED_STATE_DISABLED) {
                methodChannel?.invokeMethod("onHomeButtonPressed", null)
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                "Sesión de Enfoque",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Muestra el temporizador de tu sesión de estudio activa"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    private fun showFocusNotification(title: String, timeText: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, pendingIntentFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIF_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val notification = builder
            .setContentTitle("🔥 Enfoque activo: $timeText")
            .setContentText(title)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(NOTIF_ID, notification)
    }

    private fun cancelFocusNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.cancel(NOTIF_ID)
    }

    private fun checkUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getUsageStatsBetween(startTime: Long, endTime: Long): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        val timeMap = mutableMapOf<String, Long>()
        val lastResumeMap = mutableMapOf<String, Long>()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            if (pkg == packageName) continue

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    lastResumeMap[pkg] = event.timeStamp
                }
                UsageEvents.Event.ACTIVITY_PAUSED, UsageEvents.Event.ACTIVITY_STOPPED -> {
                    val start = lastResumeMap.remove(pkg)
                    if (start != null && event.timeStamp > start) {
                        val diff = event.timeStamp - start
                        timeMap[pkg] = (timeMap[pkg] ?: 0L) + diff
                    }
                }
            }
        }

        for ((pkg, start) in lastResumeMap) {
            if (endTime > start) {
                val diff = endTime - start
                timeMap[pkg] = (timeMap[pkg] ?: 0L) + diff
            }
        }

        val pm = packageManager
        val resultList = mutableListOf<Map<String, Any>>()

        for ((pkg, millis) in timeMap) {
            val seconds = millis / 1000
            if (seconds >= 3) {
                val appName = try {
                    val info = pm.getApplicationInfo(pkg, 0)
                    pm.getApplicationLabel(info).toString()
                } catch (e: Exception) {
                    pkg
                }

                resultList.add(
                    mapOf(
                        "package" to pkg,
                        "name" to appName,
                        "seconds" to seconds
                    )
                )
            }
        }

        resultList.sortByDescending { (it["seconds"] as? Long) ?: 0L }
        return resultList
    }

    private fun getLaunchableApps(): List<Map<String, String>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(intent, 0)
        val apps = mutableListOf<Map<String, String>>()

        for (resolveInfo in resolveInfos) {
            val pkg = resolveInfo.activityInfo.packageName
            if (pkg == packageName) continue

            val name = resolveInfo.loadLabel(pm).toString()
            apps.add(mapOf("package" to pkg, "name" to name))
        }

        apps.sortBy { it["name"]?.lowercase() ?: "" }
        return apps
    }
}
