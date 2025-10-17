import 'package:accessibility_checker/models/suspicious_app.dart';
import 'package:flutter/material.dart';

class SecurityWarningBottomSheet extends StatelessWidget {
  final List<SuspiciousApp> suspiciousApps;
  final VoidCallback onDismiss;
  final VoidCallback onReview;

  const SecurityWarningBottomSheet({
    super.key,
    required this.suspiciousApps,
    required this.onDismiss,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_rounded, size: 48, color: Colors.red),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Security Warning!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'Detected ${suspiciousApps.length} suspicious app(s) with accessibility access from unknown sources.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              SizedBox(height: 24),

              // List of suspicious apps
              Container(
                constraints: BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: suspiciousApps.map((suspiciousApp) {
                      return _buildSuspiciousAppCard(suspiciousApp);
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Warning message
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These apps can read and control your screen. Please review carefully.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey),
                      ),
                      child: Text(
                        'I Understand',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Review Apps'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuspiciousAppCard(SuspiciousApp suspiciousApp) {
    final app = suspiciousApp.app;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shield_outlined, color: Colors.red),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  app.packageName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.warning, size: 12, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      'Accessibility Enabled',
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.file_download, size: 12, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Sideloaded',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
