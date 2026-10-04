import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/config/app_config.dart';

class UserDataExportRepository {
  UserDataExportRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<String> createJson(User user) async {
    final userRef = _firestore
        .collection(AppConfig.usersCollection)
        .doc(user.uid);
    final profileSnapshot = await userRef.get();
    final notificationSnapshot = await userRef
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .get();

    final account = <String, Object?>{
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'phoneNumber': user.phoneNumber,
      'emailVerified': user.emailVerified,
      'createdAt': user.metadata.creationTime?.toUtc().toIso8601String(),
      'lastSignInAt': user.metadata.lastSignInTime?.toUtc().toIso8601String(),
    };
    final profile =
        _jsonSafe(profileSnapshot.data() ?? const <String, dynamic>{})
            as Map<String, Object?>;
    final notifications = notificationSnapshot.docs
        .map(
          (document) => {
            'id': document.id,
            ..._jsonSafe(document.data()) as Map<String, Object?>,
          },
        )
        .toList(growable: false);

    return serializeUserDataExport(
      account: account,
      profile: profile,
      notifications: notifications,
      generatedAt: DateTime.now().toUtc(),
    );
  }
}

String serializeUserDataExport({
  required Map<String, Object?> account,
  required Map<String, Object?> profile,
  required List<Map<String, Object?>> notifications,
  required DateTime generatedAt,
}) {
  final export = <String, Object?>{
    'format': 'skeleton-account-export-v1',
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'account': _jsonSafe(account),
    'profile': _jsonSafe(profile),
    'notifications': _jsonSafe(notifications),
  };
  return const JsonEncoder.withIndent('  ').convert(export);
}

Object? _jsonSafe(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(key.toString(), _jsonSafe(nestedValue)),
    );
  }
  if (value is Iterable) return value.map(_jsonSafe).toList(growable: false);
  return value;
}
