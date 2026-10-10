import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed app version, read from the platform package metadata.
///
/// `pubspec.yaml` `version:` is the single source; release builds pass only
/// `--build-number`, so the displayed and store versions cannot drift.
final appVersionProvider = FutureProvider<String>((ref) async {
  return (await PackageInfo.fromPlatform()).version;
});
