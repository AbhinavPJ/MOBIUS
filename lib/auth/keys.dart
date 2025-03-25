import 'dart:convert';
import 'package:flutter/services.dart';

class Secrets {
  static Map<String, dynamic>? _secrets;

  /// Load secrets.json file
  static Future<void> loadSecrets() async {
    final String secretsJson =
        await rootBundle.loadString('assets/secrets.json');
    _secrets = json.decode(secretsJson);
  }

  /// Get the Groq API key
  static String get groqApiKey {
    if (_secrets == null) {
      throw Exception(
          "Secrets not loaded. Call `Secrets.loadSecrets()` first.");
    }
    return _secrets!['GROQ_API_KEY'] ?? '';
  }
}
