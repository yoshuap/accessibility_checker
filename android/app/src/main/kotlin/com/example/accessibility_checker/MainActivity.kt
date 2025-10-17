package com.example.accessibility_checker

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity: FlutterActivity() {
    private val ACCESSIBILITY_CHANNEL = "accessibility_checker"
    private val INSTALLED_APPS_CHANNEL = "installed_apps_checker"
    private lateinit var accessibilityManager: AccessibilityManager
    
    // Coroutine scope untuk background tasks
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        
        // Channel 1: Accessibility Checker
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getEnabledAccessibilityServices" -> {
                        scope.launch {
                            try {
                                val services = getEnabledAccessibilityServices()
                                withContext(Dispatchers.Main) {
                                    result.success(services)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("ERROR", e.message, null)
                                }
                            }
                        }
                    }
                    "getDetailedAccessibilityServices" -> {
                        scope.launch {
                            try {
                                val services = getDetailedAccessibilityServices()
                                withContext(Dispatchers.Main) {
                                    result.success(services)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("ERROR", e.message, null)
                                }
                            }
                        }
                    }
                    "isAccessibilityEnabled" -> {
                        // Quick check bisa langsung di main thread
                        val isEnabled = isAccessibilityEnabled()
                        result.success(isEnabled)
                    }
                    else -> result.notImplemented()
                }
            }
        
        // Channel 2: Installed Apps Checker
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALLED_APPS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAllInstalledApps" -> {
                        // Jalankan di background thread
                        scope.launch {
                            try {
                                val apps = getAllInstalledApps()
                                withContext(Dispatchers.Main) {
                                    result.success(apps)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("ERROR", e.message, null)
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel() // Cancel semua coroutines
    }

    // ============ Accessibility Methods ============
    
    /**
     * Method 1: Simple boolean check (Quick & Official API)
     */
    private fun isAccessibilityEnabled(): Boolean {
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_ALL_MASK
        )
        return enabledServices.isNotEmpty()
    }
    
    /**
     * Method 2: Get service names only (Lightweight)
     */
    private fun getEnabledAccessibilityServices(): List<String> {
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        
        if (TextUtils.isEmpty(enabledServices)) {
            return emptyList()
        }
        
        return enabledServices.split(":").map { it.split("/").last() }
    }
    
    /**
     * Method 3: Get detailed service info (Complete)
     */
    private fun getDetailedAccessibilityServices(): List<Map<String, Any>> {
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_ALL_MASK
        )
        
        return enabledServices.map { serviceInfo ->
            val servicePackageName = serviceInfo.resolveInfo.serviceInfo.packageName
            val serviceName = serviceInfo.resolveInfo.serviceInfo.name
            
            mapOf(
                "packageName" to servicePackageName,
                "serviceName" to serviceName,
                "serviceLabel" to serviceInfo.resolveInfo.loadLabel(packageManager).toString(),
                "description" to (serviceInfo.description ?: "No description"),
                "canRetrieveWindowContent" to 
                    ((serviceInfo.flags and AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS) != 0),
                "canRequestTouchExploration" to 
                    ((serviceInfo.flags and AccessibilityServiceInfo.FLAG_REQUEST_TOUCH_EXPLORATION_MODE) != 0),
                "canRequestEnhancedWebAccessibility" to 
                    ((serviceInfo.flags and AccessibilityServiceInfo.FLAG_REQUEST_ENHANCED_WEB_ACCESSIBILITY) != 0),
                "settingsActivityName" to (serviceInfo.settingsActivityName ?: "")
            )
        }
    }

    // ============ Installed Apps Methods ============
    private fun getAllInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(0)
        }
        
        return packages.mapNotNull { packageInfo ->
            val appInfo = packageInfo.applicationInfo ?: return@mapNotNull null
            
            mapOf(
                "packageName" to packageInfo.packageName,
                "appName" to getAppName(appInfo, pm),
                "versionName" to (packageInfo.versionName ?: "Unknown"),
                "versionCode" to getVersionCode(packageInfo),
                "installerPackageName" to getInstallerPackageName(packageInfo.packageName),
                "isSystemApp" to isSystemApp(appInfo),
                "installTime" to packageInfo.firstInstallTime
            )
        }
    }

    private fun getAppName(appInfo: ApplicationInfo, pm: PackageManager): String {
        return try {
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            appInfo.packageName
        }
    }

    private fun getVersionCode(packageInfo: PackageInfo): Long {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode.toLong()
        }
    }

    private fun getInstallerPackageName(packageName: String): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11+ (API 30+)
                val installSourceInfo = packageManager.getInstallSourceInfo(packageName)
                
                // Coba beberapa sumber installer secara berurutan
                installSourceInfo.installingPackageName
                    ?: installSourceInfo.initiatingPackageName
                    ?: installSourceInfo.originatingPackageName
                    ?: "Unknown"
                    
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // Android 5.0+ sampai Android 10 (API 21-29)
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName) ?: "Unknown"
                
            } else {
                // Android 4.x ke bawah (API < 21)
                @Suppress("DEPRECATION")
                val installer = packageManager.getInstallerPackageName(packageName)
                
                // Jika null, coba cek dari system settings
                installer ?: try {
                    Settings.Secure.getString(
                        contentResolver,
                        "install_non_market_apps"
                    )
                    "Unknown"
                } catch (e: Exception) {
                    "Unknown"
                }
            }
        } catch (e: IllegalArgumentException) {
            // Package tidak ditemukan
            "Package Not Found"
        } catch (e: SecurityException) {
            // Tidak punya permission untuk query package
            "Permission Denied"
        } catch (e: Exception) {
            // Error lainnya
            "Error: ${e.message}"
        }
    }

    private fun isSystemApp(appInfo: ApplicationInfo): Boolean {
        // Cek FLAG_SYSTEM - aplikasi yang terinstall di system partition
        val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
        
        // Cek FLAG_UPDATED_SYSTEM_APP - system app yang sudah di-update
        val isUpdatedSystemApp = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
        
        return isSystem || isUpdatedSystemApp
    }
}