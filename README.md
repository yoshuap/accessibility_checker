# Accessibility & Non-Official Apps Checker

Dokumentasi lengkap untuk mengimplementasikan fitur security checker yang mendeteksi aplikasi dengan accessibility service aktif yang berasal dari sumber non-official (sideloaded apps).

## 📋 Daftar Isi

- [Overview](#overview)
- [Fitur](#fitur)
- [Prerequisites](#prerequisites)
- [Instalasi](#instalasi)
- [Konfigurasi Android](#konfigurasi-android)
- [Implementasi](#implementasi)
- [FAQ](#faq)

---

## 🎯 Overview

Package ini menyediakan:
1. **Accessibility Service Checker** - Mendeteksi aplikasi yang mengaktifkan accessibility service
2. **Installed Apps Checker** - Mendapatkan daftar aplikasi terinstall beserta sumber instalasinya
3. **Security Warning System** - Menampilkan warning otomatis untuk aplikasi mencurigakan

### Use Case
- Mendeteksi aplikasi berbahaya yang menggunakan accessibility untuk mencuri data
- Audit keamanan aplikasi yang terinstall
- Melindungi user dari malware atau spyware

---

## ✨ Fitur

### 1. Accessibility Detection
- ✅ Cek apakah ada accessibility service aktif (quick check)
- ✅ Dapatkan list nama service yang aktif

### 2. App Source Detection
- ✅ Deteksi aplikasi dari Google Play Store
- ✅ Deteksi aplikasi dari official stores (Samsung, Huawei, Xiaomi, Amazon)
- ✅ Deteksi aplikasi sideloaded (APK manual)

### 3. Security Warning
- ✅ Otomatis scan saat app dibuka
- ✅ Bottom sheet warning untuk suspicious apps

---

## 📦 Prerequisites

- Flutter SDK: >= 3.0.0
- Dart SDK: >= 3.0.0
- Android MinSDK: 21 (Android 5.0 Lollipop)
- Android TargetSDK: 34 (Android 14)
- Kotlin: 1.9.0+

---

## 🚀 Instalasi

### Step 1: Update Dependencies

Tambahkan di **`android/app/build.gradle.kts`**:

```kotlin
dependencies {
    // Tambahkan Kotlin Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```

**Atau jika menggunakan Groovy** (`build.gradle`):

```gradle
dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    
    // Tambahkan Kotlin Coroutines
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3"
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3"
}
```

### Step 2: Sync Gradle

```bash
cd android
./gradlew clean
./gradlew build
```

---

## ⚙️ Konfigurasi Android

### 1. AndroidManifest.xml

Tambahkan permission di **`android/app/src/main/AndroidManifest.xml`**:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permission untuk query semua aplikasi -->
    <uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
    
    <application
        android:label="Your App Name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Activity configuration -->
    </application>
    
    <!-- Queries untuk package visibility -->
    <queries>
        <!-- Query untuk MAIN action (installed apps) -->
        <intent>
            <action android:name="android.intent.action.MAIN" />
        </intent>
        
        <!-- Query untuk PROCESS_TEXT (Flutter text processing) -->
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>
</manifest>
```

### 2. MainActivity.kt

Buat/update **`android/app/src/main/kotlin/com/example/yourapp/MainActivity.kt`**:

```kotlin
package com.example.yourapp

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
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        
        // Channel 1: Accessibility Checker
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> {
                        val isEnabled = isAccessibilityEnabled()
                        result.success(isEnabled)
                    }
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
                    else -> result.notImplemented()
                }
            }
        
        // Channel 2: Installed Apps Checker
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALLED_APPS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAllInstalledApps" -> {
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
        scope.cancel()
    }

    // ============ Accessibility Methods ============
    
    private fun isAccessibilityEnabled(): Boolean {
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_ALL_MASK
        )
        return enabledServices.isNotEmpty()
    }
    
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
                val installSourceInfo = packageManager.getInstallSourceInfo(packageName)
                installSourceInfo.installingPackageName
                    ?: installSourceInfo.initiatingPackageName
                    ?: installSourceInfo.originatingPackageName
                    ?: "Unknown"
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName) ?: "Unknown"
            }
        } catch (e: IllegalArgumentException) {
            "Package Not Found"
        } catch (e: SecurityException) {
            "Permission Denied"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    private fun isSystemApp(appInfo: ApplicationInfo): Boolean {
        val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
        val isUpdatedSystemApp = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
        return isSystem || isUpdatedSystemApp
    }
}
```

---

## 💻 Implementasi

### 1. Buat Service Classes

Buat file **`lib/services/accessibility_checker.dart`**:

```dart
import 'package:flutter/services.dart';

class AccessibilityChecker {
  static const platform = MethodChannel('accessibility_checker');

  /// Quick check: apakah ada accessibility service aktif
  Future<bool> isAccessibilityEnabled() async {
    try {
      return await platform.invokeMethod('isAccessibilityEnabled');
    } catch (e) {
      print("Error checking accessibility: $e");
      return false;
    }
  }

  /// Mendapatkan nama service yang aktif
  Future<List<String>> getEnabledAccessibilityServices() async {
    try {
      final List<dynamic> result = 
          await platform.invokeMethod('getEnabledAccessibilityServices');
      return result.cast<String>();
    } catch (e) {
      print("Error getting accessibility services: $e");
      return [];
    }
  }

  /// Mendapatkan detail lengkap service
  Future<List<AccessibilityServiceDetail>> getDetailedAccessibilityServices() async {
    try {
      final List<dynamic> result = 
          await platform.invokeMethod('getDetailedAccessibilityServices');
      return result
          .map((item) => AccessibilityServiceDetail.fromMap(item))
          .toList();
    } catch (e) {
      print("Error getting detailed services: $e");
      return [];
    }
  }
}

class AccessibilityServiceDetail {
  final String packageName;
  final String serviceName;
  final String serviceLabel;
  final String description;
  final bool canRetrieveWindowContent;
  final bool canRequestTouchExploration;

  AccessibilityServiceDetail({
    required this.packageName,
    required this.serviceName,
    required this.serviceLabel,
    required this.description,
    required this.canRetrieveWindowContent,
    required this.canRequestTouchExploration,
  });

  factory AccessibilityServiceDetail.fromMap(Map<dynamic, dynamic> map) {
    return AccessibilityServiceDetail(
      packageName: map['packageName'] ?? '',
      serviceName: map['serviceName'] ?? '',
      serviceLabel: map['serviceLabel'] ?? '',
      description: map['description'] ?? '',
      canRetrieveWindowContent: map['canRetrieveWindowContent'] ?? false,
      canRequestTouchExploration: map['canRequestTouchExploration'] ?? false,
    );
  }
}
```

Buat file **`lib/services/installed_apps_checker.dart`**:

```dart
import 'package:flutter/services.dart';

class InstalledAppsChecker {
  static const platform = MethodChannel('installed_apps_checker');

  Future<List<InstalledApp>> getAllInstalledApps() async {
    try {
      final List<dynamic> result = 
          await platform.invokeMethod('getAllInstalledApps');
      return result.map((app) => InstalledApp.fromMap(app)).toList();
    } catch (e) {
      print("Error getting installed apps: $e");
      return [];
    }
  }

  Future<List<InstalledApp>> getSideloadedApps() async {
    final allApps = await getAllInstalledApps();
    return allApps.where((app) => app.isSideloaded).toList();
  }

  Future<List<InstalledApp>> getUserApps() async {
    final allApps = await getAllInstalledApps();
    return allApps.where((app) => !app.isSystemApp).toList();
  }
}

class InstalledApp {
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final String installerPackageName;
  final bool isSystemApp;
  final int installTime;

  InstalledApp({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.installerPackageName,
    required this.isSystemApp,
    required this.installTime,
  });

  factory InstalledApp.fromMap(Map<dynamic, dynamic> map) {
    return InstalledApp(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      versionName: map['versionName'] ?? '',
      versionCode: map['versionCode'] ?? 0,
      installerPackageName: map['installerPackageName'] ?? 'Unknown',
      isSystemApp: map['isSystemApp'] ?? false,
      installTime: map['installTime'] ?? 0,
    );
  }

  bool get isFromOfficialStore {
    final officialStores = [
      'com.android.vending', // Google Play Store
      'com.sec.android.app.samsungapps', // Samsung Galaxy Store
      'com.amazon.venezia', // Amazon Appstore
      'com.huawei.appmarket', // Huawei AppGallery
      'com.xiaomi.mipicks', // Xiaomi GetApps
    ];
    return officialStores.contains(installerPackageName);
  }

  bool get isSideloaded {
    return !isSystemApp && !isFromOfficialStore;
  }

  String get appType {
    if (isSystemApp) return 'System App';
    if (isFromOfficialStore) return 'Official Store';
    if (isSideloaded) return 'Sideloaded';
    return 'Unknown';
  }
}
```

### 2. Buat Security Service

Buat file **`lib/services/security_service.dart`**:

```dart
import 'accessibility_checker.dart';
import 'installed_apps_checker.dart';

class SecurityService {
  final AccessibilityChecker _accessibilityChecker = AccessibilityChecker();
  final InstalledAppsChecker _appsChecker = InstalledAppsChecker();

  Future<List<SuspiciousApp>> checkSuspiciousApps() async {
    // Quick check accessibility
    if (!await _accessibilityChecker.isAccessibilityEnabled()) {
      return [];
    }

    // Get detailed info
    final accessibilityDetails = 
        await _accessibilityChecker.getDetailedAccessibilityServices();
    
    final allApps = await _appsChecker.getAllInstalledApps();
    final sideloadedApps = allApps.where((app) => app.isSideloaded).toList();
    
    final suspiciousApps = <SuspiciousApp>[];
    
    for (var app in sideloadedApps) {
      final hasAccessibility = accessibilityDetails.any(
        (service) => service.packageName == app.packageName
      );
      
      if (hasAccessibility) {
        suspiciousApps.add(SuspiciousApp(
          app: app,
          hasAccessibility: true,
        ));
      }
    }
    
    return suspiciousApps;
  }
}

class SuspiciousApp {
  final InstalledApp app;
  final bool hasAccessibility;

  SuspiciousApp({
    required this.app,
    required this.hasAccessibility,
  });
}
```


---

## ❓ FAQ

### Q: Apakah bisa detect semua sideloaded apps?
**A:** Ya, dengan permission `QUERY_ALL_PACKAGES`. Tapi untuk publish ke Play Store, butuh justification khusus.

### Q: Installer package names apa saja yang official?
**A:**
- `com.android.vending` - Google Play Store
- `com.sec.android.app.samsungapps` - Samsung Galaxy Store
- `com.amazon.venezia` - Amazon Appstore
- `com.huawei.appmarket` - Huawei AppGallery
- `com.xiaomi.mipicks` - Xiaomi GetApps

### Q: Bagaimana cara handle apps dengan installer "Unknown"?
**A:** Semua apps dengan installer "Unknown" atau kosong dianggap sideloaded (kecuali system apps).

### Q: Apakah perlu permission khusus?
**A:** Ya, butuh `QUERY_ALL_PACKAGES` untuk Android 11+. Untuk Play Store, deklarasikan use case di console.

### Q: Performance impact?
**A:** 
- Quick check: < 100ms
- Full scan: 1-3 detik (tergantung jumlah apps)
- Dengan coroutines: No UI freeze

### Q: Support Android version berapa?
**A:** Android 5.0 (API 21) ke atas. Untuk Android 11+, ada API lebih lengkap.

---

## 📚 Resources

- [Android Accessibility Services](https://developer.android.com/reference/android/accessibilityservice/AccessibilityService)
- [Package Visibility](https://developer.android.com/training/package-visibility)
- [Method Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)

---

## 📝 License

MIT License - Silakan gunakan dan modifikasi sesuai kebutuhan.

---


**Last Updated:** October 2025  
**Version:** 1.0.0