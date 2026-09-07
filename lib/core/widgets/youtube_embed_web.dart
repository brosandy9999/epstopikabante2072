// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

final Set<String> _registeredViewKeys = <String>{};

Widget buildYouTubeIFrame({
  required String videoId,
  required String viewKey,
  bool autoPlay = true,
}) {
  // YouTube distraction-free embed parameters:
  // - rel=0: No outside recommended videos
  // - modestbranding=1: Minimal YouTube branding
  // - iv_load_policy=3: Disables annotations
  // - playsinline=1: Plays directly within player
  // - controls=1: Full player control bar
  final autoPlayParam = autoPlay ? '1' : '0';
  final embedUrl =
      'https://www.youtube-nocookie.com/embed/$videoId?autoplay=$autoPlayParam&rel=0&modestbranding=1&iv_load_policy=3&controls=1&showinfo=0&disablekb=0&playsinline=1&enablejsapi=1';

  if (!_registeredViewKeys.contains(viewKey)) {
    _registeredViewKeys.add(viewKey);
    ui_web.platformViewRegistry.registerViewFactory(
      viewKey,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = embedUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow =
              'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
          ..allowFullscreen = true;
        return iframe;
      },
    );
  }

  return HtmlElementView(viewType: viewKey);
}
