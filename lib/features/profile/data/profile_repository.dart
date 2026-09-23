import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/config/app_config.dart';
import 'user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(AppConfig.usersCollection).doc(uid);

  /// Live profile. Falls back to Auth data if the Firestore document is missing.
  Stream<UserProfile> watch(User user) {
    return _doc(user.uid).snapshots().map((snap) {
      final data = snap.data();
      return UserProfile(
        name: (data?['name'] as String?) ?? user.displayName ?? '',
        email: (data?['email'] as String?) ?? user.email ?? '',
      );
    });
  }

  Future<void> updateName(User user, String name) async {
    await user.updateDisplayName(name);
    await _doc(user.uid).set(
      {'name': name, 'email': user.email},
      SetOptions(merge: true),
    );
  }
}
