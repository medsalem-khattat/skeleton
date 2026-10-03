import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import 'push_notification_service.dart';

final pushTokenRegistrarProvider = Provider<PushTokenRegistrarClient>((ref) {
  final registrar = PushTokenRegistrar(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(pushNotificationClientProvider),
  );
  registrar.start();
  ref.onDispose(registrar.dispose);
  return registrar;
});

abstract interface class PushTokenRegistrarClient {
  Future<void> syncForCurrentUser();

  Future<void> unregisterCurrentToken();
}

class PushTokenRegistrar implements PushTokenRegistrarClient {
  PushTokenRegistrar(this._auth, this._firestore, this._pushClient);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final PushNotificationClient _pushClient;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  String? _registeredUserId;
  String? _registeredToken;

  void start() {
    _authSubscription ??= _auth.authStateChanges().listen((user) {
      if (user != null) _syncAutomatically(user.uid);
    });
    _tokenSubscription ??= _pushClient.onTokenRefresh.listen((_) {
      final user = _auth.currentUser;
      if (user != null) _syncAutomatically(user.uid);
    });
    final user = _auth.currentUser;
    if (user != null) _syncAutomatically(user.uid);
  }

  void _syncAutomatically(String userId) {
    unawaited(
      _syncForUser(userId).catchError((Object error, StackTrace stackTrace) {
        debugPrint('Could not register push token: $error\n$stackTrace');
      }),
    );
  }

  @override
  Future<void> syncForCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) await _syncForUser(user.uid);
  }

  @override
  Future<void> unregisterCurrentToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final token = _registeredUserId == user.uid
        ? _registeredToken
        : await _pushClient.getToken();
    if (token == null || token.isEmpty || token.contains("/")) return;
    await _tokenCollection(user.uid).doc(token).delete();
    _registeredUserId = null;
    _registeredToken = null;
  }

  Future<void> _syncForUser(String userId) async {
    final userSnapshot = await _firestore.collection('users').doc(userId).get();
    final preference = userSnapshot.data()?['notificationsEnabled'];
    if (preference != null && preference is! bool) {
      throw const FormatException('Notification preference must be a boolean.');
    }
    final notificationsEnabled = preference as bool? ?? true;
    if (!notificationsEnabled) return;

    final authorization = await _pushClient.authorizationStatus();
    if (authorization != PushAuthorizationStatus.authorized &&
        authorization != PushAuthorizationStatus.provisional) {
      return;
    }
    final token = await _pushClient.getToken();
    if (token == null || token.isEmpty || token.contains("/")) return;

    await _tokenCollection(userId).doc(token).set({
      'platform': switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        _ => throw UnsupportedError(
          'Push token registration is supported only on Android and iOS.',
        ),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _registeredUserId = userId;
    _registeredToken = token;
  }

  CollectionReference<Map<String, dynamic>> _tokenCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('fcmTokens');

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}
