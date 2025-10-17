import 'package:accessibility_checker/models/accessibility_service_detail.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class AccessibilityChecker {
  static const platform = MethodChannel('accessibility_checker');

  /// Method 1: Quick check (boolean)
  Future<bool> isAccessibilityEnabled() async {
    try {
      return await platform.invokeMethod('isAccessibilityEnabled');
    } catch (e) {
      debugPrint("Error: $e");
      return false;
    }
  }

  /// Method 2: Get service names (lightweight)
  Future<List<String>> getEnabledAccessibilityServices() async {
    try {
      final List<dynamic> result = await platform.invokeMethod(
        'getEnabledAccessibilityServices',
      );
      return result.cast<String>();
    } catch (e) {
      debugPrint("Error: $e");
      return [];
    }
  }

  /// Method 3: Get detailed info (complete)
  Future<List<AccessibilityServiceDetail>>
  getDetailedAccessibilityServices() async {
    try {
      final List<dynamic> result = await platform.invokeMethod(
        'getDetailedAccessibilityServices',
      );
      return result
          .map((item) => AccessibilityServiceDetail.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint("Error: $e");
      return [];
    }
  }
}
