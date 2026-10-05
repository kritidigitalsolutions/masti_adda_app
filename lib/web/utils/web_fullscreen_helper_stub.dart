import 'package:flutter/services.dart';

class WebFullscreenHelper {
  static void toggleFullscreen(bool shouldBeFullscreen) {
    if (shouldBeFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  static bool isFullscreen() {
    return false;
  }
}
