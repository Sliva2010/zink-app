import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'network/gigachat_client.dart';
import 'storage/settings_keys.dart';
import 'storage/storage_service.dart';

/// Текущий профиль пользователя (или null если онбординг не пройден).
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(_load());

  static UserProfile? _load() {
    final raw = StorageService.user.get('profile');
    if (raw is Map) {
      return UserProfile.fromJson(raw);
    }
    return null;
  }

  Future<void> save(UserProfile profile) async {
    await StorageService.user.put('profile', profile.toJson());
    await StorageService.settings.put(SettingsKeys.onboardingCompleted, true);
    state = profile;
  }

  Future<void> update(UserProfile profile) => save(profile);

  Future<void> clear() async {
    await StorageService.user.delete('profile');
    await StorageService.settings.put(SettingsKeys.onboardingCompleted, false);
    state = null;
  }
}

/// GigaChat клиент (singleton).
final gigaChatClientProvider = FutureProvider<GigaChatClient>((ref) async {
  return GigaChatClient.create();
});

/// Включен ли inverse mode (тёмная инверсная тема).
final inverseModeProvider =
    StateNotifierProvider<InverseModeNotifier, bool>((ref) {
  return InverseModeNotifier();
});

class InverseModeNotifier extends StateNotifier<bool> {
  InverseModeNotifier()
      : super(StorageService.settings
            .get(SettingsKeys.inverseMode, defaultValue: false) as bool);

  Future<void> toggle() async {
    state = !state;
    await StorageService.settings.put(SettingsKeys.inverseMode, state);
  }

  Future<void> set(bool value) async {
    state = value;
    await StorageService.settings.put(SettingsKeys.inverseMode, value);
  }
}

/// Текущий стрик (для отображения в UI).
final streakProvider = StateProvider<int>((ref) {
  return StorageService.settings.get(SettingsKeys.streakCurrent, defaultValue: 0) as int;
});

/// Текущий суммарный XP.
final totalXpProvider = StateProvider<int>((ref) {
  return StorageService.settings.get(SettingsKeys.totalXp, defaultValue: 0) as int;
});

/// Завершён ли онбординг.
final onboardingDoneProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile != null;
});
