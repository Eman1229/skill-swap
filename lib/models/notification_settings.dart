import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsModel {
  final bool pushEnabled;
  final bool swapProposalEnabled;
  final bool directMessagesEnabled;
  final bool weeklyTipsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool emailNotifications;
  final DateTime lastUpdated;

  NotificationSettingsModel({
    this.pushEnabled = true,
    this.swapProposalEnabled = true,
    this.directMessagesEnabled = true,
    this.weeklyTipsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.emailNotifications = false,
    DateTime? lastUpdated,
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();

  factory NotificationSettingsModel.fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) return NotificationSettingsModel();
    final data = doc.data() as Map<String, dynamic>;
    return NotificationSettingsModel(
      pushEnabled: data['pushEnabled'] ?? true,
      swapProposalEnabled: data['swapProposalEnabled'] ?? true,
      directMessagesEnabled: data['directMessagesEnabled'] ?? true,
      weeklyTipsEnabled: data['weeklyTipsEnabled'] ?? true,
      soundEnabled: data['soundEnabled'] ?? true,
      vibrationEnabled: data['vibrationEnabled'] ?? true,
      emailNotifications: data['emailNotifications'] ?? false,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'swapProposalEnabled': swapProposalEnabled,
      'directMessagesEnabled': directMessagesEnabled,
      'weeklyTipsEnabled': weeklyTipsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'emailNotifications': emailNotifications,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  NotificationSettingsModel copyWith({
    bool? pushEnabled,
    bool? swapProposalEnabled,
    bool? directMessagesEnabled,
    bool? weeklyTipsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? emailNotifications,
  }) {
    return NotificationSettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      swapProposalEnabled: swapProposalEnabled ?? this.swapProposalEnabled,
      directMessagesEnabled: directMessagesEnabled ?? this.directMessagesEnabled,
      weeklyTipsEnabled: weeklyTipsEnabled ?? this.weeklyTipsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      lastUpdated: DateTime.now(),
    );
  }
}
