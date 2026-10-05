import 'dart:js_interop';
import 'package:flutter/services.dart';

@JS('toggleWebFullscreen')
external JSBoolean _toggleWebFullscreen();

@JS('isWebFullscreen')
external JSBoolean _isWebFullscreen();

class WebFullscreenHelper {
  static void toggleFullscreen(bool shouldBeFullscreen) {
    try {
      _toggleWebFullscreen();
    } catch (_) {
      if (shouldBeFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  static bool isFullscreen() {
    try {
      return _isWebFullscreen().toDart;
    } catch (_) {
      return false;
    }
  }
}
