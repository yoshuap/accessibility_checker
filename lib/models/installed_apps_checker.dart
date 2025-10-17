import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class InstalledApp extends Equatable {
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final String installerPackageName;
  final bool isSystemApp;
  final int installTime;

  const InstalledApp({
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
    // Google Play Store
    if (installerPackageName == 'com.android.vending') return true;

    // Samsung Galaxy Store
    if (installerPackageName == 'com.sec.android.app.samsungapps') return true;

    // Amazon Appstore
    if (installerPackageName == 'com.amazon.venezia') return true;

    // Huawei AppGallery
    if (installerPackageName == 'com.huawei.appmarket') return true;

    // Xiaomi GetApps
    if (installerPackageName == 'com.xiaomi.mipicks') return true;

    return false;
  }

  String get appType {
    if (isSystemApp) return 'System App';
    if (isFromOfficialStore) return 'Official Store';
    if (isSideloaded) return 'Sideloaded';
    return 'Unknown';
  }

  bool get isPackageNotFound {
    return installerPackageName == 'Package Not Found';
  }

  bool get hasPermissionDenied {
    return installerPackageName == 'Permission Denied';
  }

  bool get hasError {
    return installerPackageName.startsWith('Error:');
  }

  bool get isSideloaded {
    if (isPackageNotFound || hasPermissionDenied || hasError) {
      return false; // Cannot determine
    }

    if (!isSystemApp && !isFromOfficialStore) return true;
    if (installerPackageName == 'Unknown' || installerPackageName.isEmpty) {
      return !isSystemApp;
    }

    return false;
  }

  @override
  List<Object?> get props => [
    packageName,
    appName,
    versionName,
    versionCode,
    installerPackageName,
    isSystemApp,
    installTime,
  ];
}

class InstalledAppsChecker {
  static const platform = MethodChannel('installed_apps_checker');

  Future<List<InstalledApp>> getAllInstalledApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod(
        'getAllInstalledApps',
      );
      return result.map((app) => InstalledApp.fromMap(app)).toList();
    } catch (e) {
      debugPrint("Error getting installed apps: $e");
      return [];
    }
  }

  Future<List<InstalledApp>> getSideloadedApps() async {
    final allApps = await getAllInstalledApps();
    return allApps.where((app) => app.isSideloaded).toList();
  }
}
