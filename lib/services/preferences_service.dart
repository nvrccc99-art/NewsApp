import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  // ...existing code...
  static const String _textSizeKey = 'text_size';


  static Future<double> getTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_textSizeKey) ?? 1.0;
  }

  static Future<void> setTextSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, size);
  }

  // ...existing code...

  static String getTextSizeName(double size) {
    if (size <= 0.8) return 'Small';
    if (size <= 1.0) return 'Medium';
    if (size <= 1.2) return 'Large';
    return 'Extra Large';
  }
}
