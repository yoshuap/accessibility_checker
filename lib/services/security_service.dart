import 'package:accessibility_checker/models/suspicious_app.dart';
import 'package:accessibility_checker/services/accessibility_service.dart';
import 'package:accessibility_checker/models/installed_apps_checker.dart';

class SecurityService {
  final AccessibilityChecker _accessibilityChecker = AccessibilityChecker();
  final InstalledAppsChecker _appsChecker = InstalledAppsChecker();

  Future<List<SuspiciousApp>> checkSuspiciousApps() async {
    // Quick check dulu
    if (!await _accessibilityChecker.isAccessibilityEnabled()) {
      return []; // Tidak ada accessibility aktif
    }

    // Ambil detailed info
    final accessibilityDetails = await _accessibilityChecker
        .getDetailedAccessibilityServices();

    final allApps = await _appsChecker.getAllInstalledApps();
    final sideloadedApps = allApps.where((app) => app.isSideloaded).toList();

    final suspiciousApps = <SuspiciousApp>[];

    for (var app in sideloadedApps) {
      // Match dengan detailed info
      final hasAccessibility = accessibilityDetails.any(
        (service) => service.packageName == app.packageName,
      );

      if (hasAccessibility) {
        suspiciousApps.add(SuspiciousApp(app: app, hasAccessibility: true));
      }
    }

    return suspiciousApps;
  }
}
