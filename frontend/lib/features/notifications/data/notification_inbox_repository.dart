import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/firebase/firebase_providers.dart';
import 'app_notification.dart';

final notificationInboxRepositoryProvider =
    Provider<NotificationInboxRepository>((ref) {
      return FirestoreNotificationInboxRepository(
        ref.watch(firestoreProvider),
        ref.watch(firebaseAuthProvider),
        ref.watch(firebaseFunctionsProvider),
      );
    });

final notificationInboxProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationInboxRepositoryProvider).watch();
});

final notificationProvider = StreamProvider.family<AppNotification?, String>((
  ref,
  id,
) {
  return ref.watch(notificationInboxRepositoryProvider).watchNotification(id);
});

abstract interface class NotificationInboxRepository {
  Stream<List<AppNotification>> watch();

  Stream<AppNotification?> watchNotification(String notificationId);

  /// Asks the trusted backend to record a password change in the signed-in
  /// user's inbox. Clients cannot create inbox records directly.
  Future<void> recordPasswordChanged({required String languageCode});

  Future<void> markRead(String notificationId);
}

class FirestoreNotificationInboxRepository
    implements NotificationInboxRepository {
  FirestoreNotificationInboxRepository(
    this._firestore,
    this._auth,
    this._functions,
  );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .collection('notifications');

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('A signed-in user is required for notifications.');
    }
    return uid;
  }

  @override
  Stream<List<AppNotification>> watch() {
    final uid = _requireUserId();
    return _notifications(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromDocument)
              .toList(growable: false),
        );
  }

  @override
  Stream<AppNotification?> watchNotification(String notificationId) {
    final uid = _requireUserId();
    return _notifications(uid).doc(notificationId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return AppNotification.fromData(snapshot.id, data);
    });
  }

  @override
  Future<void> recordPasswordChanged({required String languageCode}) async {
    _requireUserId();
    await _functions.httpsCallable('recordPasswordChange').call<void>({
      'languageCode': languageCode,
    });
  }

  @override
  Future<void> markRead(String notificationId) async {
    final uid = _requireUserId();
    await _notifications(uid).doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }
}
