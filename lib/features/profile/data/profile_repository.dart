import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/firestore_retry.dart';
import 'user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(AppConfig.usersCollection).doc(uid);

  /// Live profile. Falls back to Auth data if the Firestore document is missing.
  /// Left un-retried: this is a .snapshots() stream, and the Firestore SDK
  /// already reconnects it automatically after a transient failure.
  Stream<UserProfile> watch(User user) {
    return _doc(user.uid).snapshots().map((snap) {
      final data = snap.data();
      return UserProfile(
        name: (data?['name'] as String?) ?? user.displayName ?? '',
        email: user.email ?? (data?['email'] as String?) ?? '',
      );
    });
  }

  Future<void> updateName(User user, String name) async {
    final previousDisplayName = user.displayName;
    await updateProfileNameWithRollback(
      updateAuthName: () => user.updateDisplayName(name),
      persistProfile: () => firestoreRetry(
        () => _doc(
          user.uid,
        ).set({'name': name, 'email': user.email}, SetOptions(merge: true)),
      ),
      rollbackAuthName: () => user.updateDisplayName(previousDisplayName),
    );
  }
}

Future<void> updateProfileNameWithRollback({
  required Future<void> Function() updateAuthName,
  required Future<void> Function() persistProfile,
  required Future<void> Function() rollbackAuthName,
}) async {
  await updateAuthName();
  try {
    await persistProfile();
  } catch (error, stackTrace) {
    try {
      await rollbackAuthName();
    } catch (rollbackError, rollbackStackTrace) {
      Error.throwWithStackTrace(
        ProfileNameSyncException(error, rollbackError),
        rollbackStackTrace,
      );
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}

class ProfileNameSyncException implements Exception {
  const ProfileNameSyncException(this.profileError, this.rollbackError);

  final Object profileError;
  final Object rollbackError;
}
