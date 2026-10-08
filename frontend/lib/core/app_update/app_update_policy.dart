import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

import '../config/feature_providers.dart';

const _minimumVersionKey = 'minimum_app_version';
const _androidStoreUrlKey = 'android_store_url';
const _iosStoreUrlKey = 'ios_store_url';

class AppUpdateRequirement {
  const AppUpdateRequirement({
    required this.minimumVersion,
    required this.storeUrl,
  });

  final String minimumVersion;
  final Uri storeUrl;
}

bool isAppVersionBelowMinimum({
  required String installedVersion,
  required String minimumVersion,
}) {
  return Version.parse(installedVersion) < Version.parse(minimumVersion);
}

final appUpdateRequirementProvider = FutureProvider<AppUpdateRequirement?>((
  ref,
) async {
  if (!ref.watch(appFeaturesProvider).firebaseEnabled ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return null;
  }

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode
          ? Duration.zero
          : const Duration(hours: 1),
    ),
  );
  await remoteConfig.setDefaults({
    _minimumVersionKey: '0.0.0',
    _androidStoreUrlKey: '',
    _iosStoreUrlKey: '',
  });
  try {
    await remoteConfig.fetchAndActivate();
  } catch (error, stackTrace) {
    debugPrint(
      'Could not refresh Firebase Remote Config for app updates: '
      '$error\n$stackTrace',
    );
  }

  final currentVersion = (await PackageInfo.fromPlatform()).version;
  final minimumVersion = remoteConfig.getString(_minimumVersionKey).trim();
  if (minimumVersion.isEmpty ||
      !isAppVersionBelowMinimum(
        installedVersion: currentVersion,
        minimumVersion: minimumVersion,
      )) {
    return null;
  }

  final storeUrlKey = defaultTargetPlatform == TargetPlatform.android
      ? _androidStoreUrlKey
      : _iosStoreUrlKey;
  final storeUrl = Uri.tryParse(remoteConfig.getString(storeUrlKey).trim());
  if (storeUrl == null || storeUrl.scheme != 'https' || storeUrl.host.isEmpty) {
    throw StateError(
      'Firebase Remote Config must provide a valid HTTPS value for '
      '$storeUrlKey when minimum_app_version exceeds the installed version.',
    );
  }

  return AppUpdateRequirement(
    minimumVersion: minimumVersion,
    storeUrl: storeUrl,
  );
});
