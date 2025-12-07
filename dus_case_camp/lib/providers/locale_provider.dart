import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _kLanguageCodeKey = 'language_code';

  LocaleNotifier() : super(const Locale('tr')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_kLanguageCodeKey);

    if (languageCode != null) {
      state = Locale(languageCode);
    } else {
      // Default to Turkish if no preference is saved
      state = const Locale('tr');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;

    state = locale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageCodeKey, locale.languageCode);

    // Optional: Sync to Firestore if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'languageCode': locale.languageCode}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to sync locale to Firestore: $e');
      }
    }
  }
}
