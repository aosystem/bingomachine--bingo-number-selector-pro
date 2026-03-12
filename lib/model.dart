import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bingomachine/const_value.dart';
import 'package:bingomachine/l10n/app_localizations.dart';

class Model {
  Model._();

  static const String _prefTtsEnabled = 'ttsEnabled';
  static const String _prefTtsVolume = 'ttsVolume';
  static const String _prefTtsVoiceId = 'ttsVoiceId';
  static const String _prefMachineVolume = 'machineVolume';
  static const String _prefQuickDraw = 'quickDraw';
  static const String _prefAutomaticDrawInterval = 'automaticDrawInterval';
  static const String _prefTextSizeRatioBall = 'textSizeRatioBall';
  static const String _prefTextSizeTable = 'textSizeTable';
  static const String _prefTextSizeCard = 'textSizeCard';
  static const String _prefCardState = 'cardState';
  static const String _prefBallHistory = 'ballHistory';
  static const String _prefFreeText1 = 'freeText1';
  static const String _prefFreeText2 = 'freeText2';
  static const String _prefColorScheme = 'colorScheme';
  static const String _prefThemeNumber = 'themeNumber';
  static const String _prefLanguageCode = 'languageCode';

  static bool _ready = false;
  static bool _ttsEnabled = true;
  static String _ttsVoiceId = '';
  static double _ttsVolume = 1.0;
  static double _machineVolume = 1.0;
  static int _quickDraw = ConstValue.defaultQuickDraw;
  static int _automaticDrawInterval = ConstValue.defaultAutomaticDrawInterval;
  static double _textSizeRatioBall = ConstValue.defaultTextSizeRatioBall;
  static int _textSizeTable = ConstValue.defaultTextSizeTable;
  static int _textSizeCard = ConstValue.defaultTextSizeCard;
  static String _cardState = '';
  static String _freeText1 = 'Reach';
  static String _freeText2 = 'Bingo';
  static String _ballHistory = '';
  static int _colorScheme = 0;
  static int _themeNumber = 0;
  static String _languageCode = '';

  static bool get ttsEnabled => _ttsEnabled;
  static String get ttsVoiceId => _ttsVoiceId;
  static double get ttsVolume => _ttsVolume;
  static double get machineVolume => _machineVolume;
  static int get quickDraw => _quickDraw;
  static int get automaticDrawInterval => _automaticDrawInterval;
  static double get textSizeRatioBall => _textSizeRatioBall;
  static int get textSizeTable => _textSizeTable;
  static int get textSizeCard => _textSizeCard;
  static String get cardState => _cardState;
  static String get freeText1 => _freeText1;
  static String get freeText2 => _freeText2;
  static String get ballHistory => _ballHistory;
  static int get colorScheme => _colorScheme;
  static int get themeNumber => _themeNumber;
  static String get languageCode => _languageCode;

  static Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    //
    _ttsEnabled = prefs.getBool(_prefTtsEnabled) ?? true;
    _ttsVoiceId = prefs.getString(_prefTtsVoiceId) ?? '';
    _ttsVolume = (prefs.getDouble(_prefTtsVolume) ?? 1.0).clamp(0.0,1.0);
    _machineVolume = (prefs.getDouble(_prefMachineVolume) ?? 1.0).clamp(0.0,1.0);
    _quickDraw = (prefs.getInt(_prefQuickDraw) ?? ConstValue.defaultQuickDraw).clamp(
      ConstValue.minQuickDraw,
      ConstValue.maxQuickDraw,
    );
    _automaticDrawInterval = (prefs.getInt(_prefAutomaticDrawInterval) ?? ConstValue.defaultAutomaticDrawInterval).clamp(
      ConstValue.minAutomaticDrawInterval,
      ConstValue.maxAutomaticDrawInterval,
    );
    _textSizeRatioBall = (prefs.getDouble(_prefTextSizeRatioBall) ?? ConstValue.defaultTextSizeRatioBall).clamp(
      ConstValue.minTextSizeRatioBall,
      ConstValue.maxTextSizeRatioBall,
    );
    _textSizeTable = (prefs.getInt(_prefTextSizeTable) ?? ConstValue.defaultTextSizeTable).clamp(
      ConstValue.minTextSizeTable,
      ConstValue.maxTextSizeTable,
    );
    _textSizeCard = (prefs.getInt(_prefTextSizeCard) ?? ConstValue.defaultTextSizeCard).clamp(
      ConstValue.minTextSizeCard,
      ConstValue.maxTextSizeCard,
    );
    _cardState = prefs.getString(_prefCardState) ?? '';
    _freeText1 = prefs.getString(_prefFreeText1) ?? 'Reach';
    _freeText2 = prefs.getString(_prefFreeText2) ?? 'Bingo';
    _ballHistory = prefs.getString(_prefBallHistory) ?? '';
    _colorScheme = (prefs.getInt(_prefColorScheme) ?? 0).clamp(0, 1);
    _themeNumber = (prefs.getInt(_prefThemeNumber) ?? 0).clamp(0, 2);
    _languageCode = prefs.getString(_prefLanguageCode) ?? ui.PlatformDispatcher.instance.locale.languageCode;
    _languageCode = _resolveLanguageCode(_languageCode);
    _ready = true;
  }

  static String _resolveLanguageCode(String code) {
    final supported = AppLocalizations.supportedLocales;
    if (supported.any((l) => l.languageCode == code)) {
      return code;
    } else {
      return '';
    }
  }

  static Future<void> resetMachine() async {
    _ballHistory = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefBallHistory);
  }

  static Future<void> resetCard() async {
    _cardState = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefCardState);
  }

  static Future<void> setTtsEnabled(bool flag) async {
    _ttsEnabled = flag;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTtsEnabled, flag);
  }

  static Future<void> setTtsVoiceId(String value) async {
    _ttsVoiceId = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTtsVoiceId, value);
  }

  static Future<void> setTtsVolume(double value) async {
    _ttsVolume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefTtsVolume, value);
  }

  static Future<void> setMachineVolume(double value) async {
    _machineVolume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefMachineVolume, value);
  }

  static Future<void> setQuickDraw(int value) async {
    _quickDraw = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefQuickDraw, value);
  }

  static Future<void> setAutomaticDrawInterval(int value) async {
    _automaticDrawInterval = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefAutomaticDrawInterval, value);
  }

  static Future<void> setTextSizeRatioBall(double value) async {
    _textSizeRatioBall = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefTextSizeRatioBall, value);
  }

  static Future<void> setTextSizeTable(int value) async {
    _textSizeTable = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefTextSizeTable, value);
  }

  static Future<void> setTextSizeCard(int value) async {
    _textSizeCard = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefTextSizeCard, value);
  }

  static Future<void> setCardState(String value) async {
    _cardState = value;
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      await prefs.remove(_prefCardState);
    } else {
      await prefs.setString(_prefCardState, value);
    }
  }

  static Future<void> setFreeText1(String value) async {
    _freeText1 = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefFreeText1, value);
  }

  static Future<void> setFreeText2(String value) async {
    _freeText2 = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefFreeText2, value);
  }

  static Future<void> setBallHistory(String value) async {
    _ballHistory = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefBallHistory, value);
  }

  static Future<void> setColorScheme(int value) async {
    _colorScheme = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefColorScheme, value);
  }

  static Future<void> setThemeNumber(int value) async {
    _themeNumber = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeNumber, value);
  }

  static Future<void> setLanguageCode(String value) async {
    _languageCode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageCode, value);
  }

}
