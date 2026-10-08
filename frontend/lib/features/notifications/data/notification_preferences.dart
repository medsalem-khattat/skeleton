import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/firebase/firebase_providers.dart';

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
      return FirestoreNotificationPreferencesRepository(
        ref.watch(firestoreProvider),
      );
    });

final userNotificationsEnabledProvider = StreamProvider.family<bool, String>((
  ref,
  userId,
) {
  return ref
      .watch(notificationPreferencesRepositoryProvider)
      .watchEnabled(userId);
});

abstract interface class NotificationPreferencesRepository {
  Stream<bool> watchEnabled(String userId);

  Future<void> setEnabled(String userId, bool enabled);
}

class FirestoreNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  FirestoreNotificationPreferencesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDocument(String userId) =>
      _firestore.collection(AppConfig.usersCollection).doc(userId);

  @override
  Stream<bool> watchEnabled(String userId) {
    return _userDocument(userId).snapshots().map((snapshot) {
      final value = snapshot.data()?['notificationsEnabled'];
      if (value == null) return true;
      if (value is! bool) {
        throw const FormatException(
          'Notification preference must be a boolean.',
        );
      }
      return value;
    });
  }

  @override
  Future<void> setEnabled(String userId, bool enabled) {
    return _userDocument(
      userId,
    ).set({'notificationsEnabled': enabled}, SetOptions(merge: true));
  }
}
