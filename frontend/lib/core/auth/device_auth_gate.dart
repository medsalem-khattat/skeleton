import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/settings/application/device_auth_controller.dart';
import '../config/feature_providers.dart';
import '../../l10n/app_localizations.dart';

const deviceAuthBackgroundGracePeriod = Duration(minutes: 1);

final verifiedDeviceAuthSessionProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? ref.watch(authRepositoryProvider).currentUser;
  if (user == null || !user.emailVerified) return null;
  return user.uid;
});

class DeviceAuthGate extends ConsumerStatefulWidget {
  const DeviceAuthGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeviceAuthGate> createState() => _DeviceAuthGateState();
}

class _DeviceAuthGateState extends ConsumerState<DeviceAuthGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  bool _initialCheckScheduled = false;
  String? _error;
  String? _observedUserId;
  final Stopwatch _backgroundDuration = Stopwatch();
  Timer? _backgroundGraceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _observedUserId = ref.read(appFeaturesProvider).deviceAuthenticationEnabled
        ? ref.read(verifiedDeviceAuthSessionProvider)
        : null;
  }

  @override
  void dispose() {
    _backgroundGraceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (ref.read(appFeaturesProvider).deviceAuthenticationEnabled &&
          ref.read(deviceAuthEnabledProvider) &&
          ref.read(verifiedDeviceAuthSessionProvider) != null) {
        _startBackgroundGracePeriod();
      }
    } else if (state == AppLifecycleState.resumed) {
      final exceededGracePeriod =
          _backgroundDuration.elapsed >= deviceAuthBackgroundGracePeriod;
      _stopBackgroundGracePeriod();
      if (exceededGracePeriod && !_locked) {
        setState(() {
          _locked = true;
          _error = null;
        });
      }
      if (_locked) _authenticate();
    }
  }

  void _startBackgroundGracePeriod() {
    if (_backgroundDuration.isRunning) return;
    _backgroundDuration
      ..reset()
      ..start();
    _backgroundGraceTimer = Timer(deviceAuthBackgroundGracePeriod, () {
      if (!mounted ||
          !ref.read(appFeaturesProvider).deviceAuthenticationEnabled ||
          !ref.read(deviceAuthEnabledProvider) ||
          ref.read(verifiedDeviceAuthSessionProvider) == null) {
        return;
      }
      setState(() {
        _locked = true;
        _error = null;
      });
    });
  }

  void _stopBackgroundGracePeriod() {
    _backgroundGraceTimer?.cancel();
    _backgroundGraceTimer = null;
    _backgroundDuration
      ..stop()
      ..reset();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    final l10n = AppLocalizations.of(context);
    if (!ref.read(appFeaturesProvider).deviceAuthenticationEnabled ||
        !ref.read(deviceAuthEnabledProvider) ||
        ref.read(verifiedDeviceAuthSessionProvider) == null) {
      if (mounted) setState(() => _locked = false);
      return;
    }

    setState(() {
      _locked = true;
      _authenticating = true;
      _error = null;
    });

    try {
      final supported = await ref
          .read(deviceAuthenticatorProvider)
          .isDeviceSupported();
      if (!supported) {
        if (mounted) {
          setState(() {
            _error = l10n.deviceAuthUnavailable;
          });
        }
        return;
      }

      final authenticated = await ref
          .read(deviceAuthenticatorProvider)
          .authenticate(l10n.deviceAuthReason);
      if (mounted && authenticated) {
        setState(() => _locked = false);
      } else if (mounted) {
        setState(() {
          _error = l10n.deviceAuthFailed;
        });
      }
    } on LocalAuthException {
      if (mounted) {
        setState(() {
          _error = l10n.deviceAuthFailed;
        });
      }
    } finally {
      _authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(appFeaturesProvider).deviceAuthenticationEnabled) {
      return widget.child;
    }
    final enabled = ref.watch(deviceAuthEnabledProvider);
    final verifiedUserId = ref.watch(verifiedDeviceAuthSessionProvider);
    final verifiedUser = verifiedUserId != null;

    ref.listen(verifiedDeviceAuthSessionProvider, (previous, next) {
      final userId = next;
      if (userId == _observedUserId) return;
      _observedUserId = userId;
      if (userId == null) {
        _stopBackgroundGracePeriod();
        setState(() {
          _locked = false;
          _error = null;
        });
      } else if (ref.read(deviceAuthEnabledProvider)) {
        _authenticate();
      }
    });

    if (!_initialCheckScheduled) {
      _initialCheckScheduled = true;
      if (enabled && verifiedUser) {
        _locked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _authenticate();
        });
      }
    }
    if (!enabled || !verifiedUser) {
      _locked = false;
      return widget.child;
    }

    if (!_locked) return widget.child;

    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      l10n.deviceAuthLocked,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _authenticating ? null : _authenticate,
                      child: _authenticating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.deviceAuthUnlock),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
