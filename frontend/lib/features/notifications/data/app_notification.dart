import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType { passwordChanged }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final AppNotificationType type;
  final DateTime? createdAt;
  final bool isRead;

  factory AppNotification.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) => AppNotification.fromData(document.id, document.data());

  factory AppNotification.fromData(String id, Map<String, dynamic> data) {
    final type = switch (data['type']) {
      'password_changed' => AppNotificationType.passwordChanged,
      final String value => throw FormatException(
        'Unsupported notification type: $value',
      ),
      _ => throw const FormatException('Notification type is missing.'),
    };
    final timestamp = data['createdAt'];
    if (timestamp != null && timestamp is! Timestamp) {
      throw const FormatException('Notification timestamp is invalid.');
    }
    final isRead = data['isRead'];
    if (isRead is! bool) {
      throw const FormatException('Notification read status is invalid.');
    }
    return AppNotification(
      id: id,
      type: type,
      createdAt: (timestamp as Timestamp?)?.toDate(),
      isRead: isRead,
    );
  }
}
