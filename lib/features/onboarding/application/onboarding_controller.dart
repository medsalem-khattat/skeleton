import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/theme_controller.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends Notifier<bool> {
  static const _preferenceKey = 'onboarding_completed';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_preferenceKey) ?? false;

  Future<void> complete() async {
    final saved = await ref
        .read(sharedPreferencesProvider)
        .setBool(_preferenceKey, true);
    if (!saved) {
      throw StateError('Onboarding completion could not be saved.');
    }
    state = true;
  }
}
