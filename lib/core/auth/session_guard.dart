import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Detects a session invalidated on the server (account disabled/deleted,
/// or a revoked refresh token) and forces a local sign-out so the
/// router's existing redirect-to-login (see app_router.dart) kicks in.
///
/// Firebase's authStateChanges() only reacts to sign-in/out on THIS
/// device; it does not notice remote revocation until a token refresh
/// happens to fail on its own. This checks proactively every time the
/// app returns to the foreground.
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
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
      if (invalidated.contains(e.code)) {
        await FirebaseAuth.instance.signOut();
        // The router's own redirect (auth.currentUser == null) sends
        // the user back to the login screen automatically.
      }
    } catch (_) {
      // Network or other transient errors: ignore, re-check next resume.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
