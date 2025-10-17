import 'package:accessibility_checker/models/suspicious_app.dart';
import 'package:accessibility_checker/services/accessibility_service.dart';
import 'package:accessibility_checker/models/installed_apps_checker.dart';
import 'package:accessibility_checker/services/security_service.dart';
import 'package:accessibility_checker/widgets/security_warning_bottomsheet.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _accessibilityList = [];
  var _nonOfficialAppsInstalledList = <InstalledApp>[];
  final _accessiblityChecker = AccessibilityChecker();
  final _appsChecker = InstalledAppsChecker();
  final _securityService = SecurityService();
  var _accessibilityEnable = false;

  @override
  void initState() {
    super.initState();
    // Otomatis check suspicious apps saat pertama kali buka
    Future.delayed(Duration(milliseconds: 500), () {
      _checkSuspiciousApp();
    });
  }

  Future<void> init() async {
    setState(() {
      _checkAccessibility();
      _checkInstalledApps();
      _isAccessibilityEnabled();
    });
  }

  Future<void> _checkInstalledApps() async {
    _nonOfficialAppsInstalledList = <InstalledApp>[];

    final data = await _appsChecker.getSideloadedApps();

    for (var e in data) {
      if (!_nonOfficialAppsInstalledList.contains(e)) {
        _nonOfficialAppsInstalledList.add(e);
      }
    }
  }

  Future<void> _checkAccessibility() async {
    _accessibilityList = [];
    final data = await _accessiblityChecker.getEnabledAccessibilityServices();

    for (var e in data) {
      if (!_accessibilityList.contains(e)) {
        _accessibilityList.add(e);
      }
    }
  }

  Future<void> _isAccessibilityEnabled() async {
    if (await _accessiblityChecker.isAccessibilityEnabled()) {
      _accessibilityEnable = true;
    } else {
      _accessibilityEnable = false;
    }
  }

  Future<void> _checkSuspiciousApp() async {
    final data = await _securityService.checkSuspiciousApps();

    // Jika ada suspicious apps, tampilkan bottom sheet
    if (data.isNotEmpty && mounted) {
      _showSecurityWarning(data);
    }
  }

  void _showSecurityWarning(List<SuspiciousApp> suspiciousApps) {
    showModalBottomSheet(
      context: context,
      isDismissible: false, // User harus klik button untuk close
      enableDrag: false, // Tidak bisa di-drag untuk close
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SecurityWarningBottomSheet(
        suspiciousApps: suspiciousApps,
        onDismiss: () => Navigator.pop(context),
        onReview: () {
          Navigator.pop(context);
          // Refresh data
          init();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title, style: TextStyle(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  FutureBuilder(
                    future: _isAccessibilityEnabled(),
                    builder: (context, asyncSnapshot) {
                      final isDone =
                          asyncSnapshot.connectionState == ConnectionState.done;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Accessibility ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isDone)
                            _accessibilityEnable
                                ? Text(
                                    'ON',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Text(
                                    'OFF',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 18),
                  FutureBuilder(
                    future: _checkAccessibility(),
                    builder: (context, asyncSnapshot) {
                      if (asyncSnapshot.connectionState ==
                          ConnectionState.done) {
                        return Expanded(
                          child: _accessibilityList.isEmpty
                              ? Text('None')
                              : ListView.builder(
                                  itemCount: _accessibilityList.length,
                                  itemBuilder: (context, index) {
                                    return Text(
                                      '${index + 1}. ${_accessibilityList[index]}',
                                      style: TextStyle(),
                                    );
                                  },
                                ),
                        );
                      }

                      return CircularProgressIndicator();
                    },
                  ),
                ],
              ),
            ),
            VerticalDivider(color: Colors.black, thickness: 2, width: 20),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Non-Official Apps',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 18),
                  FutureBuilder(
                    future: _checkInstalledApps(),
                    builder: (context, asyncSnapshot) {
                      if (asyncSnapshot.connectionState ==
                          ConnectionState.done) {
                        return Expanded(
                          child: _nonOfficialAppsInstalledList.isEmpty
                              ? Text('None')
                              : ListView.builder(
                                  itemCount:
                                      _nonOfficialAppsInstalledList.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        _nonOfficialAppsInstalledList[index];
                                    return Text(
                                      '${index + 1}. ${item.appName} : ${item.installerPackageName}',
                                      style: TextStyle(),
                                    );
                                  },
                                ),
                        );
                      }

                      return CircularProgressIndicator();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refresh',
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: init,
            child: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'check',
            backgroundColor: Colors.orange,
            onPressed: _checkSuspiciousApp,
            icon: Icon(Icons.security, color: Colors.white),
            label: Text(
              'Check Security',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
