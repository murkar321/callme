import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Small persistence + broadcast layer for user-configurable app settings
/// (theme, notifications, sound).
///
/// This is a singleton so both `main.dart` (to drive `MaterialApp.themeMode`)
/// and `SettingsPage` (to let the user change values) share the same state
/// without pulling in a full state-management package.
///
/// ─────────────────────────────────────────────────────────────────────
/// WIRE-UP: call `await SettingsController.instance.load()` once at app
/// startup (before `runApp`), then wrap `MaterialApp` in a
/// `ValueListenableBuilder<ThemeMode>` listening to `themeMode` and pass
/// its value as `MaterialApp.themeMode`. See main.dart / CallMeApp.
///
/// Add to pubspec.yaml (if not already present):
/// ```yaml
/// dependencies:
///   shared_preferences: ^2.2.3
/// ```
/// ─────────────────────────────────────────────────────────────────────
class SettingsController {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  static const _kThemeKey = 'settings_theme_mode';
  static const _kNotifKey = 'settings_notifications_enabled';
  static const _kSoundKey = 'settings_sound_enabled';

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> soundEnabled = ValueNotifier<bool>(true);

  bool _loaded = false;

  /// Call once at app startup, before runApp().
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_kThemeKey);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      themeMode.value = ThemeMode.values[themeIndex];
    }

    notificationsEnabled.value = prefs.getBool(_kNotifKey) ?? true;
    soundEnabled.value = prefs.getBool(_kSoundKey) ?? true;
    _loaded = true;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeKey, mode.index);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifKey, value);

    // Mirror to Firestore so the fcm_queue processor / order_service.dart
    // can skip pushing to users who opted out — same dual-write pattern
    // already used for FCM tokens (users/{uid} and users/{email}).
    await _writeNotificationFlagToFirestore(value);
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundKey, value);
  }

  Future<void> _writeNotificationFlagToFirestore(bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final email = (user.email ?? '').trim().toLowerCase();

      final data = {
        'notificationsEnabled': value,
        'notificationsUpdatedAt': FieldValue.serverTimestamp(),
      };

      final futures = <Future>[
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(data, SetOptions(merge: true)),
      ];
      if (email.isNotEmpty) {
        futures.add(
          FirebaseFirestore.instance
              .collection('users')
              .doc(email)
              .set(data, SetOptions(merge: true)),
        );
      }
      await Future.wait(futures);
    } catch (e) {
      debugPrint('SETTINGS: failed to sync notification flag: $e');
    }
  }
}