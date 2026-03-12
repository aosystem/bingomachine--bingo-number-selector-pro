import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;
import 'package:collection/collection.dart';

class TtsOption {
  final String locale;
  final String name;
  const TtsOption(this.locale, this.name);
  String get id => '$locale|$name';
  String get label => '$locale $name';
}

class TextToSpeech {
  static late FlutterTts _tts;
  static final List<TtsOption> ttsVoices = [];
  static String ttsVoiceId = '';

  static TextToSpeech? _instance;
  static bool _initialized = false;

  TextToSpeech._internal();

  static Future<TextToSpeech> getInstance() async {
    _instance ??= TextToSpeech._internal();
    if (!_initialized) {
      await _instance!._initial();
      _initialized = true;
    }
    return _instance!;
  }

  Future<void> _initial() async {
    _tts = FlutterTts();
    try {
      List<dynamic>? vs;
      for (int i = 0; i < 10; i++) {
        vs = await _tts.getVoices;
        if (vs != null) {
          break;
        }
        await Future.delayed(Duration(seconds: 1));
      }
      if (vs is List) {
        ttsVoices.clear();
        for (final v in vs) {
          if (v is Map && v['name'] is String && v['locale'] is String) {
            ttsVoices.add(TtsOption(v['locale']!, v['name']!));
          }
        }
      }
      ttsVoices.sort((a, b) => a.label.compareTo(b.label));
      ttsVoices.insert(0, TtsOption("Default", ""));
      ttsVoiceId = ttsVoices.first.id;
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  static Future<void> setTtsVoiceId(String newTtsVoiceId) async {
    final exists = ttsVoices.any((o) => o.id == newTtsVoiceId);
    if (exists) {
      ttsVoiceId = newTtsVoiceId;
    } else {
      ttsVoiceId = ttsVoices.first.id;
    }
    await _setSpeechVoiceFromId();
  }

  static Future<void> _setSpeechVoiceFromId() async {
    if (ttsVoices.isEmpty || ttsVoiceId.isEmpty) {
      return;
    }
    final idx = ttsVoiceId.indexOf('|');
    String selLocale = '';
    String selName = ttsVoiceId;
    if (idx >= 0) {
      selLocale = ttsVoiceId.substring(0, idx);
      selName = ttsVoiceId.substring(idx + 1);
    }
    TtsOption? match;
    if (selLocale.isNotEmpty) {
      match = ttsVoices.firstWhereOrNull(
            (e) => e.name == selName && e.locale == selLocale,
      );
    }
    match ??= ttsVoices.firstWhereOrNull((e) => e.name == selName);
    if (match != null) {
      final locale = match.locale;
      final name = match.name;
      try {
        if (Platform.isAndroid) {
          try {
            await _tts.setEngine('com.google.android.tts');
          } catch (_) {}
          if (locale.isNotEmpty) {
            await _tts.setLanguage(locale);
          }
          await _tts.setVoice({'name': name, 'locale': locale});
        } else if (Platform.isIOS) {
          await _tts.setVoice({'name': name, 'locale': locale});
        } else {
          if (locale.isNotEmpty) {
            await _tts.setLanguage(locale);
          }
          await _tts.setVoice({'name': name, 'locale': locale});
        }
      } catch (_) {}
    }
  }

  static Future<void> applyPreferences(String ttsVoiceId, double ttsVolume) async {
    await TextToSpeech.getInstance();
    await TextToSpeech.setTtsVoiceId(ttsVoiceId);
    await TextToSpeech.setVolume(ttsVolume);
  }

  static Future<void> speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static Future<void> setVolume(double volume) async {
    try {
      await _tts.setVolume(volume);
    } catch (_) {}
  }

  static Future<void> setPitch(double pitch) async {
    try {
      await _tts.setPitch(pitch);
    } catch (_) {}
  }

  static Future<void> setSpeechRate(double speechRate) async {
    try {
      await _tts.setSpeechRate(speechRate);
    } catch (_) {}
  }

}
