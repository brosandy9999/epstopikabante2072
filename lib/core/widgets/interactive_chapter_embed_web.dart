// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

final Set<String> _registeredChapterKeys = <String>{};

Widget buildInteractiveChapterIFrame({
  required String chapterUrl,
  required String viewKey,
}) {
  var effectiveUrl = chapterUrl.trim();
  if (effectiveUrl.isEmpty) {
    effectiveUrl = 'about:blank';
  }

  if (!_registeredChapterKeys.contains(viewKey)) {
    _registeredChapterKeys.add(viewKey);
    ui_web.platformViewRegistry.registerViewFactory(
      viewKey,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = effectiveUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#202124'
          ..allow = 'autoplay; fullscreen; clipboard-read; clipboard-write'
          ..allowFullscreen = true;
        return iframe;
      },
    );
  }

  return HtmlElementView(viewType: viewKey);
}
