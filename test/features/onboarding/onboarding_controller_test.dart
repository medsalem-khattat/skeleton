import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeleton/features/onboarding/application/onboarding_controller.dart';
import 'package:skeleton/features/settings/application/theme_controller.dart';

void main() {
  test('onboarding completion persists across controller instances', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(container.read(onboardingControllerProvider), isFalse);
    await container.read(onboardingControllerProvider.notifier).complete();
    expect(container.read(onboardingControllerProvider), isTrue);
    expect(preferences.getBool('onboarding_completed'), isTrue);
  });
}
