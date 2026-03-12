import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:bingomachine/l10n/app_localizations.dart';
import 'package:bingomachine/ad_banner_widget.dart';
import 'package:bingomachine/ad_manager.dart';
import 'package:bingomachine/ad_ump_status.dart';
import 'package:bingomachine/const_value.dart';
import 'package:bingomachine/loading_screen.dart';
import 'package:bingomachine/model.dart';
import 'package:bingomachine/text_to_speech.dart';
import 'package:bingomachine/theme_color.dart';


class SettingPage extends StatefulWidget {
  const SettingPage({super.key});
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late AdManager _adManager;
  late UmpConsentController _adUmp;
  AdUmpState _adUmpState = AdUmpState.initial;
  int _themeNumber = 0;
  String _languageCode = '';
  late ThemeColor _themeColor;
  final _inAppReview = InAppReview.instance;
  bool _isReady = false;
  bool _isFirst = true;
  //
  bool _resetMachine = false;
  bool _resetCard = false;
  int _quickDraw = ConstValue.defaultQuickDraw;
  int _automaticDrawInterval = ConstValue.defaultAutomaticDrawInterval;
  double _textSizeRatioBall = ConstValue.defaultTextSizeRatioBall;
  int _textSizeTable = ConstValue.defaultTextSizeTable;
  int _textSizeCard = ConstValue.defaultTextSizeCard;
  late List<TtsOption> _ttsVoices;
  bool _ttsEnabled = true;
  String _ttsVoiceId = '';
  double _ttsVolume = 1.0;
  double _machineVolume = 1.0;
  int _colorScheme = 0;
  //
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _adManager = AdManager();
    _themeNumber = Model.themeNumber;
    _languageCode = Model.languageCode;
    //
    _adUmp = UmpConsentController();
    _refreshConsentInfo();
    //
    _ttsEnabled = Model.ttsEnabled;
    _ttsVolume = Model.ttsVolume;
    _ttsVoiceId = Model.ttsVoiceId;
    _machineVolume = Model.machineVolume;
    _quickDraw = Model.quickDraw;
    _automaticDrawInterval = Model.automaticDrawInterval;
    _themeNumber = Model.themeNumber;
    _textSizeRatioBall = Model.textSizeRatioBall;
    _textSizeTable = Model.textSizeTable;
    _textSizeCard = Model.textSizeCard;
    _colorScheme = Model.colorScheme;
    //speech
    await TextToSpeech.getInstance();
    _ttsVoices = TextToSpeech.ttsVoices;
    TextToSpeech.setVolume(_ttsVolume);
    TextToSpeech.setTtsVoiceId(_ttsVoiceId);
    //
    setState(() {
      _isReady = true;
    });
  }

  @override
  void dispose() {
    _adManager.dispose();
    unawaited(TextToSpeech.stop());
    super.dispose();
  }

  Future<void> _refreshConsentInfo() async {
    _adUmpState = await _adUmp.updateConsentInfo(current: _adUmpState);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onTapPrivacyOptions() async {
    final err = await _adUmp.showPrivacyOptions();
    await _refreshConsentInfo();
    if (err != null && mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.cmpErrorOpeningSettings} ${err.message}')),
      );
    }
  }

  Future<void> _onApply() async {
    FocusScope.of(context).unfocus();
    if (_resetMachine) {
      await Model.resetMachine();
    }
    if (_resetCard) {
      await Model.resetCard();
    }
    await Model.setMachineVolume(_machineVolume);
    await Model.setQuickDraw(_quickDraw);
    await Model.setAutomaticDrawInterval(_automaticDrawInterval);
    await Model.setTextSizeRatioBall(_textSizeRatioBall);
    await Model.setTextSizeTable(_textSizeTable);
    await Model.setTextSizeCard(_textSizeCard);
    await Model.setTtsEnabled(_ttsEnabled);
    await Model.setTtsVoiceId(_ttsVoiceId);
    await Model.setTtsVolume(_ttsVolume);
    await Model.setColorScheme(_colorScheme);
    await Model.setThemeNumber(_themeNumber);
    await Model.setLanguageCode(_languageCode);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: _themeNumber, context: context);
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _themeColor.backColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(l.setting),
        foregroundColor: _themeColor.appBarForegroundColor,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(icon: const Icon(Icons.check), onPressed: _onApply)
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 100),
                  child: Column(
                    children: [
                      _buildReset(l),
                      _buildTextSize(l),
                      _buildQuickDraw(l),
                      _buildAutomaticDrawInterval(l),
                      _buildVolumeSection(l),
                      _buildSpeechSettings(l),
                      _buildColorScheme(l),
                      _buildTheme(l),
                      _buildLanguage(l),
                      _buildReview(l),
                      _buildCmp(l),
                      _buildUsage(l),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildReset(AppLocalizations l) {
    return Column(children:[
      Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l.resetMachine,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  l.resetMachineNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: _resetMachine,
                onChanged: (value) {
                  setState(() {
                    _resetMachine = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      Card(
        margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l.resetCard,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  l.resetCardNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: _resetCard,
                onChanged: (value) {
                  setState(() {
                    _resetCard = value;
                  });
                },
              ),
            ],
          ),
        ),
      )
    ]);
  }

  Widget _buildTextSize(AppLocalizations l) {
    return Column(children:[
      Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.textSizeRatioBall),
              Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      _textSizeRatioBall.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _textSizeRatioBall,
                      min: ConstValue.minTextSizeRatioBall.toDouble(),
                      max: ConstValue.maxTextSizeRatioBall.toDouble(),
                      divisions: 19,
                      label: _textSizeRatioBall.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _textSizeRatioBall = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      Card(
        margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.textSizeTable),
              Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      _textSizeTable.toStringAsFixed(0),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _textSizeTable.toDouble(),
                      min: ConstValue.minTextSizeTable.toDouble(),
                      max: ConstValue.maxTextSizeTable.toDouble(),
                      divisions: 46,
                      label: _textSizeTable.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          _textSizeTable = value.toInt();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      Card(
        margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.textSizeCard),
              Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      _textSizeCard.toStringAsFixed(0),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _textSizeCard.toDouble(),
                      min: ConstValue.minTextSizeCard.toDouble(),
                      max: ConstValue.maxTextSizeCard.toDouble(),
                      divisions: 46,
                      label: _textSizeCard.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          _textSizeCard = value.toInt();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
    ]);
  }

  Widget _buildQuickDraw(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.quickDraw),
            Row(
              children: [
                Text(
                  _quickDraw.toString(),
                  textAlign: TextAlign.right,
                ),
                Expanded(
                  child: Slider(
                    value: _quickDraw.toDouble(),
                    min: ConstValue.minQuickDraw.toDouble(),
                    max: ConstValue.maxQuickDraw.toDouble(),
                    divisions: 10,
                    label: _quickDraw.toString(),
                    onChanged: (value) {
                      setState(() {
                        _quickDraw = value.toInt();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomaticDrawInterval(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.automaticDrawInterval),
            Row(
              children: [
                Text(
                  _automaticDrawInterval.toString(),
                  textAlign: TextAlign.right,
                ),
                Expanded(
                  child: Slider(
                    value: _automaticDrawInterval.toDouble(),
                    min: ConstValue.minAutomaticDrawInterval.toDouble(),
                    max: ConstValue.maxAutomaticDrawInterval.toDouble(),
                    divisions: ConstValue.maxAutomaticDrawInterval - ConstValue.minAutomaticDrawInterval,
                    label: _automaticDrawInterval.toString(),
                    onChanged: (value) {
                      setState(() {
                        _automaticDrawInterval = value.toInt();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSection(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.machineVolume),
                Row(
                  children: [
                    Text(
                      _machineVolume.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                    ),
                    Expanded(
                      child: Slider(
                        value: _machineVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: _machineVolume.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _machineVolume = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechSettings(AppLocalizations l) {
    if (_ttsVoices.isEmpty) {
      return SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    return Column(children:[
      Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.ttsEnabled,
                    ),
                  ),
                  Switch(
                    value: _ttsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _ttsEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        )
      ),
      Card(
        margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: Row(
                children: [
                  Text(
                    l.ttsVolume,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                children: <Widget>[
                  Text(_ttsVolume.toStringAsFixed(1)),
                  Expanded(
                    child: Slider(
                      value: _ttsVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: _ttsVolume.toStringAsFixed(1),
                      onChanged: _ttsEnabled
                        ? (double value) {
                          setState(() {
                            _ttsVolume = double.parse(
                              value.toStringAsFixed(1),
                            );
                          });
                        }
                        : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ),
      Card(
        margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 16),
              child: DropdownButtonFormField<String>(
                initialValue: () {
                  if (_ttsVoiceId.isNotEmpty && _ttsVoices.any((o) => o.id == _ttsVoiceId)) {
                    return _ttsVoiceId;
                  }
                  return _ttsVoices.first.id;
                }(),
                items: _ttsVoices
                  .map((o) => DropdownMenuItem<String>(value: o.id, child: Text(o.label)))
                  .toList(),
                onChanged: (v) {
                  if (v == null) {
                    return;
                  }
                  setState(() => _ttsVoiceId = v);
                },
              ),
            ),
          ],
        )
      )
    ]);
  }

  Widget _buildColorScheme(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.colorScheme,
                style: t.bodyMedium,
              ),
            ),
            DropdownButton<int>(
              value: _colorScheme,
              items: [
                DropdownMenuItem(value: 0, child: Text('Green')),
                DropdownMenuItem(value: 1, child: Text('Blue')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _colorScheme = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTheme(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.theme,
                style: t.bodyMedium,
              ),
            ),
            DropdownButton<int>(
              value: _themeNumber,
              items: [
                DropdownMenuItem(value: 0, child: Text(l.systemSetting)),
                DropdownMenuItem(value: 1, child: Text(l.lightTheme)),
                DropdownMenuItem(value: 2, child: Text(l.darkTheme)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _themeNumber = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguage(AppLocalizations l) {
    final Map<String,String> languageNames = {
      'af': 'af: Afrikaans',
      'ar': 'ar: العربية',
      'bg': 'bg: Български',
      'bn': 'bn: বাংলা',
      'bs': 'bs: Bosanski',
      'ca': 'ca: Català',
      'cs': 'cs: Čeština',
      'da': 'da: Dansk',
      'de': 'de: Deutsch',
      'el': 'el: Ελληνικά',
      'en': 'en: English',
      'es': 'es: Español',
      'et': 'et: Eesti',
      'fa': 'fa: فارسی',
      'fi': 'fi: Suomi',
      'fil': 'fil: Filipino',
      'fr': 'fr: Français',
      'gu': 'gu: ગુજરાતી',
      'he': 'he: עברית',
      'hi': 'hi: हिन्दी',
      'hr': 'hr: Hrvatski',
      'hu': 'hu: Magyar',
      'id': 'id: Bahasa Indonesia',
      'it': 'it: Italiano',
      'ja': 'ja: 日本語',
      'km': 'km: ខ្មែរ',
      'kn': 'kn: ಕನ್ನಡ',
      'ko': 'ko: 한국어',
      'lt': 'lt: Lietuvių',
      'lv': 'lv: Latviešu',
      'ml': 'ml: മലയാളം',
      'mr': 'mr: मराठी',
      'ms': 'ms: Bahasa Melayu',
      'my': 'my: မြန်မာ',
      'ne': 'ne: नेपाली',
      'nl': 'nl: Nederlands',
      'or': 'or: ଓଡ଼ିଆ',
      'pa': 'pa: ਪੰਜਾਬੀ',
      'pl': 'pl: Polski',
      'pt': 'pt: Português',
      'ro': 'ro: Română',
      'ru': 'ru: Русский',
      'si': 'si: සිංහල',
      'sk': 'sk: Slovenčina',
      'sr': 'sr: Српски',
      'sv': 'sv: Svenska',
      'sw': 'sw: Kiswahili',
      'ta': 'ta: தமிழ்',
      'te': 'te: తెలుగు',
      'th': 'th: ไทย',
      'tl': 'tl: Tagalog',
      'tr': 'tr: Türkçe',
      'uk': 'uk: Українська',
      'ur': 'ur: اردو',
      'uz': 'uz: Oʻzbekcha',
      'vi': 'vi: Tiếng Việt',
      'zh': 'zh: 中文',
      'zu': 'zu: isiZulu',
    };
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.language,
                style: t.bodyMedium,
              ),
            ),
            DropdownButton<String?>(
              value: _languageCode,
              items: [
                DropdownMenuItem(value: '', child: Text('Default')),
                ...languageNames.entries.map((entry) => DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                )),
              ],
              onChanged: (String? value) {
                setState(() {
                  _languageCode = value ?? '';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.reviewApp, style: t.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.open_in_new, size: 16),
                  label: Text(l.reviewStore, style: t.bodySmall),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await _inAppReview.openStoreListing(
                      appStoreId: 'YOUR_APP_STORE_ID',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCmp(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    final showButton = _adUmpState.privacyStatus == PrivacyOptionsRequirementStatus.required;
    String statusLabel = l.cmpCheckingRegion;
    IconData statusIcon = Icons.help_outline;
    switch (_adUmpState.privacyStatus) {
      case PrivacyOptionsRequirementStatus.required:
        statusLabel = l.cmpRegionRequiresSettings;
        statusIcon = Icons.privacy_tip_outlined;
        break;
      case PrivacyOptionsRequirementStatus.notRequired:
        statusLabel = l.cmpRegionNoSettingsRequired;
        statusIcon = Icons.check_circle_outline;
        break;
      case PrivacyOptionsRequirementStatus.unknown:
        statusLabel = l.cmpRegionCheckFailed;
        statusIcon = Icons.error_outline;
        break;
    }
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.cmpSettingsTitle,
              style: t.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.cmpConsentDescription,
              style: t.bodySmall,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Chip(
                    avatar: Icon(statusIcon, size: 18),
                    label: Text(statusLabel),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l.cmpConsentStatusLabel} ${_adUmpState.consentStatus.localized(context)}',
                    style: t.bodySmall,
                  ),
                  if (showButton) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _adUmpState.isChecking
                          ? null
                          : _onTapPrivacyOptions,
                      icon: const Icon(Icons.settings),
                      label: Text(
                        _adUmpState.isChecking
                            ? l.cmpConsentStatusChecking
                            : l.cmpOpenConsentSettings,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _adUmpState.isChecking
                          ? null
                          : _refreshConsentInfo,
                      icon: const Icon(Icons.refresh),
                      label: Text(l.cmpRefreshStatus),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final message = l.cmpResetStatusDone;
                        await ConsentInformation.instance.reset();
                        await _refreshConsentInfo();
                        if (!mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: Text(l.cmpResetStatus),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsage(AppLocalizations l) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final noteStyle = Theme.of(context).textTheme.bodySmall;
    return SizedBox(
        width: double.infinity,
        child: Card(
          margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
          color: _themeColor.cardColor,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.usageTitle, style: bodyStyle),
                const SizedBox(height: 8),
                Text(l.usageDescription, style: noteStyle),
                const SizedBox(height: 16),
                Text(l.usageNote, style: noteStyle),
                const SizedBox(height: 16),
                Text(l.usageHostTitle, style: bodyStyle),
                const SizedBox(height: 8),
                Text(l.usageHostDescription, style: noteStyle),
                const SizedBox(height: 16),
                Text(l.usagePlayerTitle, style: bodyStyle),
                const SizedBox(height: 8),
                Text(l.usagePlayerDescription, style: noteStyle),
              ],
            ),
          ),
        )
    );
  }

}
