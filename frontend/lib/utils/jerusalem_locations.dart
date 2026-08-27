
library;
class JerusalemLocation {
  final String en;
  final String ar;
  const JerusalemLocation({required this.en, required this.ar});

  /// Returns the localized name based on the language code.
  String name(String languageCode) => languageCode == 'ar' ? ar : en;
}

/// Comprehensive list of Jerusalem neighborhoods and nearby cities.
/// Use `JerusalemLocation.name(languageCode)` to display in the correct locale.
const List<JerusalemLocation> kJerusalemLocations = [
  // ── Old City & surrounding ──
  JerusalemLocation(en: 'Old City', ar: 'البلدة القديمة'),
  JerusalemLocation(en: 'Silwan', ar: 'سلوان'),
  JerusalemLocation(en: 'Sheikh Jarrah', ar: 'الشيخ جراح'),
  JerusalemLocation(en: 'Wadi al-Joz', ar: 'وادي الجوز'),
  JerusalemLocation(en: 'At-Tur (Mount of Olives)', ar: 'الطور'),
  JerusalemLocation(en: 'Ras al-Amud', ar: 'رأس العامود'),
  JerusalemLocation(en: 'Jabal al-Mukaber', ar: 'جبل المكبر'),
  JerusalemLocation(en: 'Sur Baher', ar: 'صور باهر'),
  JerusalemLocation(en: 'Um Tuba', ar: 'أم طوبا'),
  JerusalemLocation(en: 'Beit Safafa', ar: 'بيت صفافا'),
  JerusalemLocation(en: 'Sharafat', ar: 'شرفات'),

  // ── Northern neighborhoods ──
  JerusalemLocation(en: 'Shuafat', ar: 'شعفاط'),
  JerusalemLocation(en: 'Shuafat Camp', ar: 'مخيم شعفاط'),
  JerusalemLocation(en: 'Beit Hanina', ar: 'بيت حنينا'),
  JerusalemLocation(en: 'Dahiyat al-Barid', ar: 'ضاحية البريد'),
  JerusalemLocation(en: 'Pisgat Ze\'ev', ar: 'بسغات زئيف'),
  JerusalemLocation(en: 'Neve Ya\'akov', ar: 'نيفي يعقوب'),
  JerusalemLocation(en: 'Kafr Aqab', ar: 'كفر عقب'),
  JerusalemLocation(en: 'Qalandiya', ar: 'قلنديا'),
  JerusalemLocation(en: 'Al-Ram', ar: 'الرام'),
  JerusalemLocation(en: 'Anata', ar: 'عناتا'),

  // ── Eastern neighborhoods ──
  JerusalemLocation(en: 'Issawiya', ar: 'العيسوية'),
  JerusalemLocation(en: 'Abu Dis', ar: 'أبو ديس'),
  JerusalemLocation(en: 'Al-Eizariya (Bethany)', ar: 'العيزرية'),
  JerusalemLocation(en: 'Az-Za\'ayyem', ar: 'الزعيم'),

  // ── Southern neighborhoods ──
  JerusalemLocation(en: 'Beit Jala', ar: 'بيت جالا'),

  // ── Western / Central Jerusalem ──
  JerusalemLocation(en: 'West Jerusalem', ar: 'القدس الغربية'),
  JerusalemLocation(en: 'Musrara', ar: 'المصرارة'),
  JerusalemLocation(en: 'City Center', ar: 'وسط المدينة'),

  // ── Catch-all ──
  JerusalemLocation(en: 'Other', ar: 'أخرى'),
];
