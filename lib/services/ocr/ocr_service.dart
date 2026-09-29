import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../platform/native_bridge.dart';

/// On-device text recognition for screenshots of messages.
///
/// Uses ML Kit's bundled Devanagari model, which also reads Latin text, so
/// English, Hindi and Hinglish screenshots work offline with one pass. No
/// image ever leaves the phone.
class OcrService extends ChangeNotifier {
  TextRecognizer? _recognizer;
  bool _busy = false;
  String? _lastError;

  bool get isBusy => _busy;
  String? get lastError => _lastError;

  TextRecognizer get _engine =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.devanagiri);

  /// Returns the recognised text in reading order, or null when nothing
  /// legible was found.
  Future<String?> recognize(String target) async {
    if (_busy) return null;
    _busy = true;
    _lastError = null;
    notifyListeners();
    String? temp;
    try {
      // ML Kit wants a real file; MediaStore entries arrive as content URIs.
      var path = target;
      if (target.startsWith('content://')) {
        temp = await NativeBridge.instance.copyToCache(target);
        if (temp == null) {
          _lastError = 'Could not read this image.';
          return null;
        }
        path = temp;
      }
      final input = InputImage.fromFilePath(path);
      final result = await _engine.processImage(input);
      final lines = <String>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isNotEmpty) lines.add(text);
        }
      }
      if (lines.isEmpty) return null;
      return lines.join('\n');
    } catch (error) {
      _lastError = 'Could not read text from this image: $error';
      return null;
    } finally {
      if (temp != null) {
        try {
          await File(temp).delete();
        } catch (_) {
          // Cache; harmless if it lingers.
        }
      }
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _recognizer?.close();
    super.dispose();
  }
}
