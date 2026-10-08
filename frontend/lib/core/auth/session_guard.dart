import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Detects a session invalidated on the server (account disabled/deleted,
/// or a revoked refresh token) and forces a local sign-out so the
/// router's existing redirect-to-login (see app_router.dart) kicks in.
///
/// Firebase's authStateChanges() only reacts to sign-in/out on THIS
/// device; it does not notice remote revocation until a token refresh
/// happens to fail on its own. This checks on launch and when the app
/// returns to the foreground, with a short throttle to avoid excess requests.
///
/// Wrap the app's root widget with this, e.g. in app.dart:
///   SessionGuard(child: MaterialApp.router(...))
class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard>
    with WidgetsBindingObserver {
  static const _minimumCheckInterval = Duration(minutes: 1);

  bool _checkInProgress = false;
  DateTime? _lastCheckAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
    if (_checkInProgress) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final lastCheckAt = _lastCheckAt;
    if (lastCheckAt != null &&
        now.difference(lastCheckAt) < _minimumCheckInterval) {
      return;
    }
    _checkInProgress = true;
    _lastCheckAt = now;
    try {
      await user.reload();
      // Forces a fresh token; throws if the account was disabled/deleted
      // or the session was revoked server-side.
      await user.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      const invalidated = {
        'user-disabled',
        'user-not-found',
        'user-token-expired',
        'invalid-user-token',
      };
      if (invalidated.contains(e.code) &&
          FirebaseAuth.instance.currentUser?.uid == user.uid) {
        await FirebaseAuth.instance.signOut();
        // The router's own redirect (auth.currentUser == null) sends
        // the user back to the login screen automatically.
      } else {
        debugPrint(
          'Could not validate the current Firebase session: ${e.code}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Unexpected error while validating the session: '
        '$error\n$stackTrace',
      );
    } finally {
      _checkInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
