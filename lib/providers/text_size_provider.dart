import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class TextSizeProvider extends ChangeNotifier {
  double _textScale = 1.0;
  double get textScale => _textScale;

  TextSizeProvider() {
    _loadTextSize();
  }

  Future<void> _loadTextSize() async {
    _textScale = await PreferencesService.getTextSize();
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    await PreferencesService.setTextSize(scale);
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadTextSize();
  }
}
