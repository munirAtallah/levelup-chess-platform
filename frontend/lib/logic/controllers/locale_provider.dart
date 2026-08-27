import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app-wide locale (language) state.
///
/// Persists the selected language code to [SharedPreferences] under [_key]
/// so the user's choice survives app restarts. The provider exposes a single
/// [toggle] convenience method for the locale toggle button in the UI.
///
/// Supported locales: 'en' (English, LTR) and 'ar' (Arabic, RTL).
/// The app rebuilds all locale-aware widgets whenever [notifyListeners] fires.
class LocaleProvider extends ChangeNotifier {
  // SharedPreferences key used to persist the language code across sessions
  static const _key = 'app_locale';
  Locale _locale = const Locale('en'); // default to English before load() runs

  Locale get locale => _locale;

  // Convenience getter used by widgets that need to apply RTL-specific layout logic
  bool get isArabic => _locale.languageCode == 'ar';

  /// Called once at startup (in main.dart) to restore the persisted locale.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  /// Updates the locale, notifies listeners immediately, then persists the new
  /// code. Notifying before the async write keeps the UI responsive.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  /// Flips between English and Arabic — wired to the locale toggle button.
  void toggle() =>
      setLocale(isArabic ? const Locale('en') : const Locale('ar'));
}
