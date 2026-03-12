import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bingomachine/l10n/app_localizations.dart';
import 'package:bingomachine/ad_banner_widget.dart';
import 'package:bingomachine/ad_manager.dart';
import 'package:bingomachine/const_value.dart';
import 'package:bingomachine/loading_screen.dart';
import 'package:bingomachine/model.dart';
import 'package:bingomachine/text_to_speech.dart';
import 'package:bingomachine/sound_player.dart';
import 'package:bingomachine/theme_color.dart';
import 'package:bingomachine/setting_page.dart';
import 'package:bingomachine/card_page.dart';
import 'package:bingomachine/main.dart';
import 'package:bingomachine/theme_mode_number.dart';
import 'package:bingomachine/parse_locale_tag.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> with TickerProviderStateMixin {
  static const Alignment _ballStartAlignment = Alignment(-0.51, 0.56);
  late AdManager _adManager;
  final SoundPlayer _soundPlayer = SoundPlayer();
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  int? _pendingBallIndex;
  AnimationController? _resultController;
  late final AnimationController _ballController;
  late final Animation<double> _ballScale;
  late final Animation<Alignment> _ballAlignment;
  bool _isSpinning = false;
  bool _videoCompleted = false;
  bool _videoStarted = false;
  bool _secondImageVisible = true;
  List<int> _ballHistory = <int>[];
  Set<int> _ballHistorySet = <int>{};
  int? _currentBall;
  //
  bool _isAutomaticDraw = false;
  Timer? _automaticDrawTimer;
  int _automaticDrawTimeCount = 0;
  double _automaticDrawProgress = 0.0;
  //
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    _resultController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    final CurvedAnimation ballCurve = CurvedAnimation(
      parent: _ballController,
      curve: Curves.easeOut,
    );
    _ballScale = ballCurve;
    _ballAlignment = AlignmentTween(
      begin: _ballStartAlignment,
      end: Alignment.topLeft,
    ).animate(ballCurve);
    _ballController.addListener(_onBallAnimationTick);
    //
    await _setupVideoController();
    _applyBallHistory();
    await TextToSpeech.applyPreferences(Model.ttsVoiceId,Model.ttsVolume);
    _adManager = AdManager();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController
      ?..removeListener(_onVideoFrame)
      ..dispose();
    _resultController?.dispose();
    _ballController.removeListener(_onBallAnimationTick);
    _ballController.dispose();
    _adManager.dispose();
    _soundPlayer.dispose();
    _automaticDrawTimer?.cancel();
    TextToSpeech.stop();
    super.dispose();
  }

  void _applyBallHistory() {
    _ballHistory = _parseHistory(Model.ballHistory);
    _ballHistorySet = _ballHistory.toSet();
    if (_ballHistory.isNotEmpty) {
      _currentBall = _ballHistory.last;
      _resultController?.forward(from: 1);
    } else {
      _currentBall = null;
    }
  }

  void _ttsResult(String text) async {
    if (Model.ttsEnabled && Model.ttsVolume > 0.0) {
      await TextToSpeech.speak(text);
    }
  }

  Future<void> _setupVideoController() async {
    late VideoPlayerController videoController;
    if (Model.colorScheme == 0) {
      videoController = VideoPlayerController.asset(
        'assets/video/bingo.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else if (Model.colorScheme == 1) {
      videoController = VideoPlayerController.asset(
        'assets/video/bingo2.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }
    _videoController = videoController;
    await videoController.initialize();
    await videoController.setLooping(false);
    await videoController.setPlaybackSpeed((Model.quickDraw / 2.0) + 1.0);
    videoController.addListener(_onVideoFrame);
    if (mounted) {
      setState(() {
        _videoReady = true;
      });
    }
  }

  void _onVideoFrame() {
    final videoController = _videoController;
    if (videoController == null ||
        !_isSpinning ||
        _pendingBallIndex == null ||
        _videoCompleted) {
      return;
    }
    final value = videoController.value;
    if (!value.isInitialized) {
      return;
    }
    if (value.isPlaying) {
      _videoStarted = true;
      return;
    }
    if (!_videoStarted) {
      return;
    }
    final bool finished =
        value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 100);
    if (finished) {
      _onSpinCompleted(_pendingBallIndex!);
    }
  }

  void _onBallAnimationTick() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  List<int> _parseHistory(String stored) {
    if (stored.isEmpty) {
      return <int>[];
    }
    final List<int> result = <int>[];
    for (final piece in stored.split(',')) {
      if (piece.isEmpty) continue;
      final value = int.tryParse(piece);
      if (value != null && value >= 0 && value < ConstValue.ballCount) {
        result.add(value);
      }
    }
    return result;
  }

  Future<void> _handleStart() async {
    if (_isSpinning || !_videoReady) {
      return;
    }
    final nextBall = _pickNextBall();
    if (nextBall == null) {
      _automaticDrawCancel();
      _notifyFinished();
      return;
    }
    HapticFeedback.selectionClick();
    _resultController?.reset();
    _ballController.reset();
    setState(() {
      _isSpinning = true;
      _pendingBallIndex = nextBall;
      _videoCompleted = false;
      _currentBall = null;
      _videoStarted = false;
    });
    await _soundPlayer.setSpeed((Model.quickDraw / 2.0) + 1.0);
    unawaited(_soundPlayer.play(Model.machineVolume));
    _videoController?.dispose();
    await _setupVideoController();
    await _videoController?.play();
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _secondImageVisible = false;
        });
      }
    });
  }

  void _automaticDrawStart() {
    _automaticDrawTimeCount = 0;
    _automaticDrawTimer = Timer.periodic(Duration(milliseconds: 100), (timer) async {
      if (_isSpinning || !_videoReady) {
        return;
      }
      _automaticDrawTimeCount += 1;
      setState(() {
        _automaticDrawProgress = (_automaticDrawTimeCount / (Model.automaticDrawInterval * 10)).clamp(0.0,1.0);
      });
      if (_automaticDrawTimeCount >= Model.automaticDrawInterval * 10) {
        _automaticDrawTimeCount = 0;
        await _handleStart();
      }
    });
  }

  void _automaticDrawStop() {
    _automaticDrawTimer?.cancel();
    _automaticDrawTimer = null;
    setState(() {
      _automaticDrawProgress = 0.0;
    });
  }

  void _automaticDrawCancel() {
    _automaticDrawStop();
    setState(() {
      _isAutomaticDraw = false;
    });
  }

  int? _pickNextBall() {
    if (_ballHistory.length >= ConstValue.ballCount) {
      return null;
    }
    final remaining = <int>[];
    for (var i = 0; i < ConstValue.ballCount; i++) {
      if (!_ballHistorySet.contains(i)) {
        remaining.add(i);
      }
    }
    if (remaining.isEmpty) {
      return null;
    }
    remaining.shuffle(Random());
    return remaining.first;
  }

  void _onSpinCompleted(int ballIndex) {
    _videoCompleted = true;
    _pendingBallIndex = null;
    _videoController?.pause();
    _soundPlayer.stop();
    final updated = List<int>.from(_ballHistory)..add(ballIndex);
    _ballHistory = updated;
    _ballHistorySet = updated.toSet();
    _currentBall = ballIndex;
    Model.setBallHistory(updated.join(','));
    _resultController?.forward(from: 0);
    _ttsResult((ballIndex + 1).toString());
    if (mounted) {
      setState(() {
        _isSpinning = false;
      });
    }
    _ballController.forward(from: 0);
    _secondImageVisible = true;
  }

  void _notifyFinished() {
    final l = AppLocalizations.of(context);
    if (l == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.finished)));
  }

  Future<void> _openSettings() async {
    _automaticDrawCancel();
    //
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingPage()),
    );
    if (!mounted) {
      return;
    }
    if (updated == true) {
      final mainState = context.findAncestorStateOfType<MainAppState>();
      if (mainState != null) {
        mainState
          ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
          ..locale = parseLocaleTag(Model.languageCode)
          ..setState(() {});
      }
      _applyBallHistory();
      await TextToSpeech.applyPreferences(Model.ttsVoiceId,Model.ttsVolume);
      _isFirst = true;
    }
    setState(() {});
  }

  Future<void> _openCard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => CardPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady == false) {
      return const LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(context: context);
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _themeColor.mainBackColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool wideLayout = constraints.maxWidth >= 720;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 4, right: 4, top: 0, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildControlButtons(l),
                        _buildVideoSection(l),
                        _buildAutomaticDraw(l),
                        if (wideLayout)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildProgressCard(l),
                              ),
                              Expanded(child: _buildHistoryCard(l)),
                            ],
                          )
                        else ...[
                          _buildProgressCard(l),
                          _buildHistoryCard(l),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildControlButtons(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSpinning ? null : _openCard,
                  icon: const Icon(Icons.grid_view_rounded),
                  label: Text(l.card),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _themeColor.mainButtonColor,
                    side: BorderSide(color: _themeColor.mainButtonColor),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSpinning ? null : _openSettings,
                  icon: const Icon(Icons.settings_rounded),
                  label: Text(l.setting),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _themeColor.mainButtonColor,
                    side: BorderSide(color: _themeColor.mainButtonColor),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection(AppLocalizations l) {
    final videoController = _videoController;
    final videoValue = videoController?.value;
    final bool hasVideo = videoValue?.isInitialized ?? false;
    return Card(
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  final double videoWidth = boxConstraints.maxWidth;
                  final double ballSize = (videoWidth * 0.5 * _ballScale.value)
                      .clamp(0.0, videoWidth);
                  final bool showBall =
                      _currentBall != null &&
                      (_ballController.value > 0 ||
                          _ballController.isAnimating);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildLastFrame(),
                      if (hasVideo && videoController != null)
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: Duration(milliseconds: 200),
                          child: VideoPlayer(videoController),
                        ),
                      AnimatedOpacity(
                        opacity: _secondImageVisible ? 1.0 : 0.0,
                        duration: Duration(milliseconds: 400),
                        child: _buildLastFrame(),
                      ),
                      if (showBall && ballSize > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Align(
                            alignment: _ballAlignment.value,
                            child: SizedBox(
                              width: ballSize,
                              height: ballSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _buildBallImage(ballSize),
                                  Text(
                                    ((_currentBall ?? 0) + 1).toString(),
                                    style: GoogleFonts.ubuntu(
                                      fontSize: ballSize * 0.7 * Model.textSizeRatioBall,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 3),
                          child: ElevatedButton(
                            onPressed: (_isSpinning || !_videoReady)
                                ? null
                                : _handleStart,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              elevation: 0,
                              backgroundColor: _isSpinning
                                  ? Theme.of(context).disabledColor
                                  : _themeColor.mainStartBackColor,
                              foregroundColor: _themeColor.mainStartForeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Text(
                                l.start,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Image _buildLastFrame() {
    if (Model.colorScheme == 1) {
      return Image.asset('assets/image/last_frame2.webp', fit: BoxFit.contain);
    }
    return Image.asset('assets/image/last_frame.webp', fit: BoxFit.contain);
  }

  SvgPicture _buildBallImage(double ballSize) {
    if (Model.colorScheme == 1) {
      return SvgPicture.string(
        ConstValue.ballImage2,
        width: ballSize,
        height: ballSize,
      );
    }
    return SvgPicture.string(
      ConstValue.ballImage,
      width: ballSize,
      height: ballSize,
    );
  }

  Widget _buildAutomaticDraw(AppLocalizations l) {
    return Card(
      color: _themeColor.mainCardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 0),
        child: Column(
          children: [
            Text(l.automaticDraw, textAlign: TextAlign.center),
            Row(children:[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: LinearProgressIndicator(
                    value: _automaticDrawProgress,
                    minHeight: 3,
                  ),
                )
              ),
              Switch(
                value: _isAutomaticDraw,
                onChanged: (value) {
                  setState(() {
                    _isAutomaticDraw = value;
                    if (value) {
                      _automaticDrawStart();
                    } else {
                      _automaticDrawStop();
                    }
                  });
                },
              ),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(AppLocalizations l) {
    return Card(
      color: _themeColor.mainCardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(l.progress, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            _buildProgressHeaderGrid(),
            const SizedBox(height: 4),
            _buildProgressGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(AppLocalizations l) {
    return Card(
      color: _themeColor.mainCardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(l.history, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            _buildHistoryGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeaderGrid() {
    const headers = ['B', 'I', 'N', 'G', 'O'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: 1.6,
      ),
      itemCount: headers.length,
      itemBuilder: (context, index) {
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _themeColor.mainTableCloseColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            headers[index],
            style: TextStyle(
              fontSize: Model.textSizeTable.toDouble(),
              fontWeight: FontWeight.bold,
              color: _themeColor.mainTableTextColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressGrid() {
    const int columns = 5;
    final int rows = (ConstValue.ballCount / columns).ceil();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: 1.6,
      ),
      itemCount: ConstValue.ballCount,
      itemBuilder: (context, index) {
        final int col = index % columns;
        final int row = index ~/ columns;
        final int verticalIndex = row + col * rows;
        final isDrawn = _ballHistorySet.contains(verticalIndex);
        final isLast = _ballHistory.isNotEmpty && _ballHistory.last == verticalIndex;
        final background = isLast
            ? _themeColor.mainTableLastColor
            : (isDrawn ? _themeColor.mainTableOpenColor : _themeColor.mainTableCloseColor);
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            (verticalIndex + 1).toString(),
            style: TextStyle(
              fontSize: Model.textSizeTable.toDouble(),
              fontWeight: FontWeight.bold,
              color: _themeColor.mainTableTextColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: 1.6,
      ),
      itemCount: ConstValue.ballCount,
      itemBuilder: (context, index) {
        if (index >= _ballHistory.length) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _themeColor.mainTableCloseColor,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }
        final ballIndex = _ballHistory[index];
        final isLast = index == _ballHistory.length - 1;
        final background = isLast ? _themeColor.mainTableLastColor : _themeColor.mainTableOpenColor;
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            (ballIndex + 1).toString(),
            style: TextStyle(
              fontSize: Model.textSizeTable.toDouble(),
              fontWeight: FontWeight.bold,
              color: _themeColor.mainTableTextColor,
            ),
          ),
        );
      },
    );
  }

}
