// Web-specific fullscreen and orientation lock
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> enterWebFullscreen() async {
  try {
    final elem = html.document.documentElement;
    if (html.document.fullscreenElement == null && elem != null) {
      elem.requestFullscreen();
    }
  } catch (_) {}
}

Future<void> exitWebFullscreen() async {
  try {
    if (html.document.fullscreenElement != null) {
      html.document.exitFullscreen();
    }
  } catch (_) {}
}

Future<void> lockWebLandscape() async {
  try {
    await enterWebFullscreen();
    final screen = html.window.screen;
    if (screen != null && screen.orientation != null) {
      screen.orientation!.lock('landscape');
    }
  } catch (_) {}
}
