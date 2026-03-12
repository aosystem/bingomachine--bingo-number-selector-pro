import 'package:flutter/material.dart';

import 'package:bingomachine/model.dart';

class ThemeColor {
  final int? themeNumber;
  final BuildContext context;

  ThemeColor({this.themeNumber, required this.context});

  Brightness get _effectiveBrightness {
    switch (themeNumber) {
      case 1:
        return Brightness.light;
      case 2:
        return Brightness.dark;
      default:
        return Theme.of(context).brightness;
    }
  }

  bool get _isLight => _effectiveBrightness == Brightness.light;

  Color get mainBackColor => Model.colorScheme == 1
      ? (_isLight ? Color.fromRGBO(140, 188, 255, 1.0) : Color.fromRGBO(35, 66, 99, 1.0))
      : (_isLight ? Color.fromRGBO(46,255,146,1) : Color.fromRGBO(0,90,10,1));
  Color get mainButtonColor => _isLight ? Color.fromRGBO(0,0,0,0.3) : Color.fromRGBO(255,255,255,0.3);
  Color get mainStartBackColor => _isLight ? Color.fromRGBO(255,255,255,0.3) : Color.fromRGBO(255,255,255,0.3);
  Color get mainStartForeColor => _isLight ? Color.fromRGBO(0,0,0,0.6) : Color.fromRGBO(255,255,255,0.8);
  Color get mainCardColor => _isLight ? Color.fromRGBO(255,255,255,0.5) : Color.fromRGBO(255,255,255,0.2);
  Color get mainTableCloseColor => _isLight ? Color.fromRGBO(255,255,255,0.5) : Color.fromRGBO(0,0,0,0.5);
  Color get mainTableOpenColor => Model.colorScheme == 1
      ? (_isLight ? Color.fromRGBO(130,160,255,0.9) : Color.fromRGBO(0,110,255,0.5))
      : (_isLight ? Color.fromRGBO(30,240,0,0.9) : Color.fromRGBO(20,220,0,0.5));
  Color get mainTableLastColor => Model.colorScheme == 1
      ? (_isLight ? Color.fromRGBO(0,220,200,0.9) : Color.fromRGBO(0,255,200,0.8))
      : (_isLight ? Color.fromRGBO(255,250,0,0.9) : Color.fromRGBO(230,190,0,0.8));
  Color get mainTableTextColor => _isLight ? Color.fromRGBO(0,0,0,1) : Color.fromRGBO(255,255,255,0.7);
  //
  Color get cardBackColor => _isLight ? Color.fromRGBO(255, 244, 204, 1.0) : Color.fromRGBO(62, 42, 0, 1.0);
  Color get cardTitleColor => _isLight ? Color.fromRGBO(0,0,0,0.8) : Color.fromRGBO(255,255,255,0.9);
  Color get cardSubjectBackColor => _isLight ? Color.fromRGBO(255,255,255,0.8) : Color.fromRGBO(0,0,0,0.3);
  Color get cardSubjectForeColor => _isLight ? Color.fromRGBO(0,0,0,0.6) : Color.fromRGBO(255,255,255,0.4);
  Color get cardTableCloseBackColor => _isLight ? Color.fromRGBO(0, 239, 119, 1.0) : Color.fromRGBO(0,0,0,0.4);
  Color get cardTableOpenBackColor => _isLight ? Color.fromRGBO(255, 212, 0, 1.0) : Color.fromRGBO(214, 148, 0, 0.6);
  Color get cardTableCloseForeColor => _isLight ? Color.fromRGBO(0,0,0,1) : Color.fromRGBO(255,255,255,0.9);
  Color get cardTableOpenForeColor => _isLight ? Color.fromRGBO(0,0,0,1) : Color.fromRGBO(255,255,255,1);
  Color get cardTableBingoForeColor => _isLight ? Color.fromRGBO(255, 77, 0, 1.0) : Color.fromRGBO(255, 221, 0, 1.0);
  //
  Color get backColor => _isLight ? Colors.grey[200]! : Colors.grey[900]!;
  Color get cardColor => _isLight ? Colors.white : Colors.grey[800]!;
  Color get appBarForegroundColor => _isLight ? Colors.grey[700]! : Colors.white70;
  Color get dropdownColor => cardColor;
  Color get backColorMono => _isLight ? Colors.white : Colors.black;
  Color get foreColorMono => _isLight ? Colors.black : Colors.white;

}
