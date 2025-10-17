class AccessibilityServiceDetail {
  final String packageName;
  final String serviceName;
  final String serviceLabel;
  final String description;
  final bool canRetrieveWindowContent;
  final bool canRequestTouchExploration;
  final bool canRequestEnhancedWebAccessibility;
  final String settingsActivityName;

  AccessibilityServiceDetail({
    required this.packageName,
    required this.serviceName,
    required this.serviceLabel,
    required this.description,
    required this.canRetrieveWindowContent,
    required this.canRequestTouchExploration,
    required this.canRequestEnhancedWebAccessibility,
    required this.settingsActivityName,
  });

  factory AccessibilityServiceDetail.fromMap(Map<dynamic, dynamic> map) {
    return AccessibilityServiceDetail(
      packageName: map['packageName'] ?? '',
      serviceName: map['serviceName'] ?? '',
      serviceLabel: map['serviceLabel'] ?? '',
      description: map['description'] ?? '',
      canRetrieveWindowContent: map['canRetrieveWindowContent'] ?? false,
      canRequestTouchExploration: map['canRequestTouchExploration'] ?? false,
      canRequestEnhancedWebAccessibility:
          map['canRequestEnhancedWebAccessibility'] ?? false,
      settingsActivityName: map['settingsActivityName'] ?? '',
    );
  }
}
