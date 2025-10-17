import 'package:accessibility_checker/models/installed_apps_checker.dart';

class SuspiciousApp {
  final InstalledApp app;
  final bool hasAccessibility;

  SuspiciousApp({required this.app, required this.hasAccessibility});
}
