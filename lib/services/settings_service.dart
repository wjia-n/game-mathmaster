import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/chalk_themes.dart';

/// Persisted settings + stats for Math Master. Survives app restarts.
///
/// The player profile is stored as ONE JSON string. Android's
/// SharedPreferences stores StringLists as an unordered StringSet, so ordered
/// data must NEVER use setStringList — this was the classic name-scrambling
/// bug on Android.
class MathSettings extends ChangeNotifier {
  static const _kMusic = 'mm_music_on';
  static const _kSfx = 'mm_sfx_on';
  static const _kVolume = 'mm_volume';
  static const _kProfile = 'mathmaster_player_names_json';
  static const _kLegacyProfileJson = 'mm_profile_json';
  static const _kIsPro = 'mm_is_pro';
  static const _kGames = 'mm_games_played';
  static const _kBestBlitz = 'mm_best_blitz';
  static const _kBestZen = 'mm_best_zen';
  static const _kBestStreak = 'mm_best_streak_all';
  static const _kTotalCorrect = 'mm_total_correct';
  static const _kLastReviewPrompt = 'mm_last_review_prompt';
  static const _kCustomPrefix = 'mm_custom_';

  /// Order-safe profile storage: a single JSON string.
  static String encodeProfile(Map<String, dynamic> p) => jsonEncode(p);

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String playerName = 'Scholar';
  String themeId = 'classic';
  int digitStyle = 0;
  int difficulty = 1;
  int lastMode = 0;
  bool isPro = false;

  int gamesPlayed = 0;
  int bestBlitz = 0;
  int bestZen = 0;
  int bestStreakAll = 0;
  int totalCorrect = 0;

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Chalkboard.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'wood': 0xFF7A4E2D,
    'woodDeep': 0xFF3B2417,
    'board': 0xFF2B3A33,
    'boardDeep': 0xFF161F1B,
    'chalk': 0xFFF6F1E3,
    'chalkSoft': 0xFFB9B2A0,
    'accent': 0xFFD9A441,
    'accentLight': 0xFFF2D38A,
    'keyBg': 0xFF3A4A41,
    'keyBorder': 0xFFD9A441,
  };

  ChalkThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return ChalkThemeDef(
      id: 'custom',
      name: 'My Classroom',
      wood: c('wood'),
      woodDeep: c('woodDeep'),
      board: c('board'),
      boardDeep: c('boardDeep'),
      chalk: c('chalk'),
      chalkSoft: c('chalkSoft'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      keyBg: c('keyBg'),
      keyBorder: c('keyBorder'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    isPro = p.getBool(_kIsPro) ?? false;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestStreakAll = p.getInt(_kBestStreak) ?? 0;
    totalCorrect = p.getInt(_kTotalCorrect) ?? 0;

    // Profile: prefer the order-safe JSON key, migrate legacy keys once.
    final raw = p.getString(_kProfile) ?? p.getString(_kLegacyProfileJson);
    if (raw != null) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) {
          final n = (d['name'] as String?)?.trim() ?? '';
          playerName = n.isEmpty ? 'Scholar' : n;
          themeId = (d['theme'] as String?) ?? 'classic';
          digitStyle = (d['digitStyle'] as int?)?.clamp(0, 8) ?? 0;
          difficulty = (d['difficulty'] as int?)?.clamp(0, 2) ?? 1;
          lastMode = (d['lastMode'] as int?)?.clamp(0, 2) ?? 0;
        }
      } catch (_) {}
    } else {
      // Legacy migration: old builds stored the best score and (via the
      // shared core) player names in an unordered StringList. Pull whatever
      // survives into the new JSON profile, then drop the legacy keys.
      bestBlitz = p.getInt('mathmaster_best') ?? 0;
      final legacyNames = p.getStringList('mathmaster_names') ??
          p.getStringList('mathmaster_player_names');
      if (legacyNames != null && legacyNames.isNotEmpty) {
        final n = legacyNames.first.trim();
        if (n.isNotEmpty) playerName = n;
      }
    }
    bestBlitz = p.getInt(_kBestBlitz) ?? bestBlitz;
    bestZen = p.getInt(_kBestZen) ?? 0;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestBlitz, bestBlitz);
    await p.setInt(_kBestZen, bestZen);
    await p.setInt(_kBestStreak, bestStreakAll);
    await p.setInt(_kTotalCorrect, totalCorrect);
    await p.setString(
        _kProfile,
        encodeProfile({
          'name': playerName,
          'theme': themeId,
          'digitStyle': digitStyle,
          'difficulty': difficulty,
          'lastMode': lastMode,
        }));
    // Drop legacy keys for good.
    await p.remove('mathmaster_best');
    await p.remove('mathmaster_names');
    await p.remove('mathmaster_player_names');
    await p.remove(_kLegacyProfileJson);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Daily best for [day] (keyed by calendar date).
  int dailyBest(DateTime day) =>
      _prefs?.getInt(_dailyKey(day)) ?? 0;

  Future<void> recordDaily(DateTime day, int score) async {
    final k = _dailyKey(day);
    final prev = _prefs?.getInt(k) ?? 0;
    if (score > prev) {
      await _prefs?.setInt(k, score);
      notifyListeners();
    }
  }

  String _dailyKey(DateTime d) =>
      'mm_daily_${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || ChalkThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (DigitStyles.isPro(digitStyle)) {
      digitStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  /// Live per-keystroke save: stores the name untrimmed so clearing the
  /// field never fights the user's typing. Focus loss / keyboard-done
  /// commits the final value through [setPlayerName].
  Future<void> setPlayerNameLive(String v) async {
    playerName = v.length > 24 ? v.substring(0, 24) : v;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String v) async {
    final n = v.trim();
    playerName = n.isEmpty ? 'Scholar' : n;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || ChalkThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setDigitStyle(int v) async {
    v = v.clamp(0, DigitStyles.names.length - 1);
    if (!isPro && DigitStyles.isPro(v)) return;
    digitStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return;
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setLastMode(int v) async {
    lastMode = v.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return;
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  /// Record a finished game; returns true if a new best was set.
  Future<bool> recordGame({
    required int mode, // 0 blitz, 1 zen, 2 daily
    required int score,
    required int bestStreak,
    required int correctCount,
  }) async {
    gamesPlayed++;
    var newBest = false;
    if (mode == 0 && score > bestBlitz) {
      bestBlitz = score;
      newBest = true;
    }
    if (mode == 1 && score > bestZen) {
      bestZen = score;
      newBest = true;
    }
    if (bestStreak > bestStreakAll) bestStreakAll = bestStreak;
    totalCorrect += correctCount;
    notifyListeners();
    await _save();
    return newBest;
  }

  String get lastReviewPromptRaw => _prefs?.getString(_kLastReviewPrompt) ?? '';

  Future<void> markReviewPrompted() async {
    await _prefs?.setString(_kLastReviewPrompt, DateTime.now().toIso8601String());
  }
}
