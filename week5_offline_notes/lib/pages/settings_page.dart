import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs.dart';
import '../data/providers.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());
final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle(bool value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(value);
      return value;
    });
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(forceOfflineProvider);
    final darkMode = ref.watch(darkModeProvider);
    return ListView(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.wifi_off),
          title: const Text('Paksa mode offline'),
          subtitle: const Text(
            'Blokir refresh API dan simulasi sinkronisasi untuk demo.',
          ),
          value: offline,
          onChanged: (value) {
            ref.read(forceOfflineProvider.notifier).setOffline(value);
            if (!value) {
              ref.read(postsRefreshControllerProvider).refreshInBackground();
            }
          },
        ),
        const Divider(),
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('Mode gelap'),
          value: darkMode.value ?? false,
          onChanged: darkMode.isLoading
              ? null
              : (value) => ref.read(darkModeProvider.notifier).toggle(value),
        ),
      ],
    );
  }
}
