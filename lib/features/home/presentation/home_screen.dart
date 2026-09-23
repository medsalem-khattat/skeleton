import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../profile/application/profile_providers.dart';

/// Placeholder home screen. Replace the body with your app's real content.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider).value?.name ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.appName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            name.isEmpty ? 'Welcome' : 'Welcome, $name',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Your app content goes here.'),
            ),
          ),
        ],
      ),
    );
  }
}
