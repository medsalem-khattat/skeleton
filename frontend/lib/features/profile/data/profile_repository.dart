import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/firestore_retry.dart';
import 'user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

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
        photoUrl: (data?['photoUrl'] as String?) ?? user.photoURL,
        photoStoragePath: data?['photoStoragePath'] as String?,
      );
    });
  }

  Future<void> uploadProfilePhoto(
    User user,
    Uint8List bytes, {
    String? previousStoragePath,
  }) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw ArgumentError('The profile image must be under 5 MB.');
    }
    final storagePath =
        'users/${user.uid}/profile/avatar_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final reference = _storage.ref(storagePath);
    await reference.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'private,max-age=3600',
      ),
    );
    try {
      await _doc(
        user.uid,
      ).set({'photoStoragePath': storagePath}, SetOptions(merge: true));
    } catch (error, stackTrace) {
      Object? cleanupError;
      try {
        await _doc(user.uid).set({
          'photoStoragePath': ?previousStoragePath,
        }, SetOptions(merge: true));
      } catch (rollbackError) {
        cleanupError = rollbackError;
      }
      try {
        await reference.delete();
      } catch (deleteError) {
        cleanupError ??= deleteError;
      }
      if (cleanupError != null) {
        Error.throwWithStackTrace(
          ProfilePhotoSyncException(error, cleanupError),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (previousStoragePath != null && previousStoragePath != storagePath) {
      try {
        await _storage.ref(previousStoragePath).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') {
          throw ProfilePhotoCleanupException(error);
        }
      }
    }
  }

  Future<Uint8List?> loadProfilePhoto(String storagePath) =>
      _storage.ref(storagePath).getData(5 * 1024 * 1024);

  Future<void> removeProfilePhoto(
    User user, {
    required String? storagePath,
  }) async {
    await _doc(user.uid).update({'photoStoragePath': FieldValue.delete()});
    if (storagePath != null) {
      try {
        await _storage.ref(storagePath).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') {
          throw ProfilePhotoRemovalCleanupException(error);
        }
      }
    }
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

class ProfilePhotoSyncException implements Exception {
  const ProfilePhotoSyncException(this.profileError, this.cleanupError);

  final Object profileError;
  final Object cleanupError;
}

class ProfilePhotoCleanupException implements Exception {
  const ProfilePhotoCleanupException(this.cleanupError);

  final Object cleanupError;
}

class ProfilePhotoRemovalCleanupException implements Exception {
  const ProfilePhotoRemovalCleanupException(this.cleanupError);

  final Object cleanupError;
}
