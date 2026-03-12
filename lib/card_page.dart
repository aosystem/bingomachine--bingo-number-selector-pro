import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bingomachine/ad_banner_widget.dart';
import 'package:bingomachine/ad_manager.dart';
import 'package:bingomachine/l10n/app_localizations.dart';
import 'package:bingomachine/loading_screen.dart';
import 'package:bingomachine/model.dart';
import 'package:bingomachine/text_to_speech.dart';
import 'package:bingomachine/theme_color.dart';

class CardPage extends StatefulWidget {
  const CardPage({super.key});
  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  static const int _gridSize = 5;
  static final Random _random = Random();

  late final AdManager _adManager;
  final TextEditingController _freeText1Controller = TextEditingController();
  final TextEditingController _freeText2Controller = TextEditingController();

  late List<List<_CardCell>> _grid;
  final Set<int> _highlighted = <int>{};
  late ThemeColor _themeColor;
  bool _ready = false;
  bool _isFirst = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _adManager = AdManager();
    _grid = List.generate(
      _gridSize,
          (_) => List.generate(_gridSize, (_) => _CardCell(number: 0)),
    );
    await Model.ensureReady();
    _freeText1Controller.text = Model.freeText1;
    _freeText2Controller.text = Model.freeText2;
    await TextToSpeech.applyPreferences(Model.ttsVoiceId,Model.ttsVolume);
    final stored = Model.cardState;
    final bool restored = _loadStoredState(stored);
    if (!restored) {
      _generateNewCard();
      unawaited(_saveCardState());
    }
    _updateHighlights();
    if (mounted) {
      setState(() {
        _ready = true;
      });
    }
  }

  @override
  void dispose() {
    unawaited(TextToSpeech.stop());
    _adManager.dispose();
    _freeText1Controller.dispose();
    _freeText2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(context: context);
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _themeColor.cardBackColor,
      appBar: AppBar(
        title: Text(l.participantMode),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: _themeColor.cardTitleColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderRow(),
                      const SizedBox(height: 12),
                      _buildGrid(),
                      const SizedBox(height: 24),
                      _buildFreeTextRow(
                        controller: _freeText1Controller,
                        onChanged: (value) => _onFreeTextChanged(1, value),
                        onSpeak: () => _speakText(_freeText1Controller.text),
                      ),
                      const SizedBox(height: 12),
                      _buildFreeTextRow(
                        controller: _freeText2Controller,
                        onChanged: (value) => _onFreeTextChanged(2, value),
                        onSpeak: () => _speakText(_freeText2Controller.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        )
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildHeaderRow() {
    const letters = ['B', 'I', 'N', 'G', 'O'];
    return Row(
      children: List.generate(
        _gridSize,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _themeColor.cardSubjectBackColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              letters[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _themeColor.cardSubjectForeColor,
                fontSize: Model.textSizeCard.toDouble(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _gridSize * _gridSize,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridSize,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ _gridSize;
          final col = index % _gridSize;
          return _buildCell(row, col);
        },
      )
    );
  }

  Widget _buildCell(int row, int col) {
    final cell = _grid[row][col];
    final bool isCenter = row == 2 && col == 2;
    final bool isOpen = cell.open || isCenter;
    final int index = _indexOf(row, col);
    final bool highlighted = _highlighted.contains(index);
    final Color background = isOpen ? _themeColor.cardTableOpenBackColor : _themeColor.cardTableCloseBackColor;
    final Color baseTextColor = isOpen ? _themeColor.cardTableOpenForeColor : _themeColor.cardTableCloseForeColor;
    final Color textColor = highlighted ? _themeColor.cardTableBingoForeColor : baseTextColor;
    final String label = isCenter ? 'F' : cell.number.toString();
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: Model.textSizeCard.toDouble(),
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );

    if (isCenter) {
      return child;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _toggleCell(row, col),
      child: child,
    );
  }

  Widget _buildFreeTextRow({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required VoidCallback onSpeak,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              onChanged(value);
              setState(() {});
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: controller.text.trim().isEmpty ? null : onSpeak,
        ),
      ],
    );
  }

  void _toggleCell(int row, int col) {
    HapticFeedback.selectionClick();
    setState(() {
      final cell = _grid[row][col];
      cell.open = !cell.open;
      _updateHighlights();
    });
    unawaited(_saveCardState());
  }

  void _updateHighlights() {
    _highlighted.clear();
    for (int row = 0; row < _gridSize; row++) {
      bool allOpen = true;
      for (int col = 0; col < _gridSize; col++) {
        if (!_grid[row][col].open && !(row == 2 && col == 2)) {
          allOpen = false;
          break;
        }
      }
      if (allOpen) {
        for (int col = 0; col < _gridSize; col++) {
          _highlighted.add(_indexOf(row, col));
        }
      }
    }

    for (int col = 0; col < _gridSize; col++) {
      bool allOpen = true;
      for (int row = 0; row < _gridSize; row++) {
        if (!_grid[row][col].open && !(row == 2 && col == 2)) {
          allOpen = false;
          break;
        }
      }
      if (allOpen) {
        for (int row = 0; row < _gridSize; row++) {
          _highlighted.add(_indexOf(row, col));
        }
      }
    }

    bool diag1 = true;
    for (int i = 0; i < _gridSize; i++) {
      if (!_grid[i][i].open && !(i == 2 && i == 2)) {
        diag1 = false;
        break;
      }
    }
    if (diag1) {
      for (int i = 0; i < _gridSize; i++) {
        _highlighted.add(_indexOf(i, i));
      }
    }

    bool diag2 = true;
    for (int i = 0; i < _gridSize; i++) {
      final int row = i;
      final int col = _gridSize - 1 - i;
      if (!_grid[row][col].open && !(row == 2 && col == 2)) {
        diag2 = false;
        break;
      }
    }
    if (diag2) {
      for (int i = 0; i < _gridSize; i++) {
        _highlighted.add(_indexOf(i, _gridSize - 1 - i));
      }
    }
  }

  void _generateNewCard() {
    for (int col = 0; col < _gridSize; col++) {
      final int base = col * 15;
      final numbers = List<int>.generate(15, (index) => base + index + 1);
      numbers.shuffle(_random);
      for (int row = 0; row < _gridSize; row++) {
        _grid[row][col]
          ..number = numbers[row]
          ..open = false;
      }
    }
    _grid[2][2].open = true;
  }

  bool _loadStoredState(String stored) {
    if (stored.isEmpty) {
      return false;
    }
    final entries = stored
        .split(',')
        .where((element) => element.isNotEmpty)
        .toList();
    if (entries.length < _gridSize * _gridSize) {
      return false;
    }
    int index = 0;
    for (int col = 0; col < _gridSize; col++) {
      for (int row = 0; row < _gridSize; row++) {
        final parts = entries[index].split(':');
        final number = int.tryParse(parts[0]) ?? _defaultNumberFor(row, col);
        final isOpen = parts.length > 1 && parts[1].toLowerCase() == 'true';
        _grid[row][col]
          ..number = number
          ..open = isOpen;
        index++;
      }
    }
    _grid[2][2].open = true;
    return true;
  }

  Future<void> _saveCardState() async {
    final buffer = StringBuffer();
    for (int col = 0; col < _gridSize; col++) {
      for (int row = 0; row < _gridSize; row++) {
        final cell = _grid[row][col];
        buffer
          ..write(cell.number)
          ..write(':')
          ..write(cell.open)
          ..write(',');
      }
    }
    await Model.setCardState(buffer.toString());
  }

  void _onFreeTextChanged(int slot, String value) {
    if (slot == 1) {
      unawaited(Model.setFreeText1(value));
    } else {
      unawaited(Model.setFreeText2(value));
    }
  }

  Future<void> _speakText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      await TextToSpeech.stop();
    } catch (_) {
      // Ignore stop errors.
    }
    await TextToSpeech.speak(trimmed);
  }

  int _defaultNumberFor(int row, int col) {
    return col * 15 + row + 1;
  }

  int _indexOf(int row, int col) => col * _gridSize + row;

}

class _CardCell {
  _CardCell({required this.number});
  int number;
  bool open = false;
}
