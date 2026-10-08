import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'feature_config.dart';

final appFeaturesProvider = Provider<AppFeatures>((ref) {
  return AppConfig.features;
});
