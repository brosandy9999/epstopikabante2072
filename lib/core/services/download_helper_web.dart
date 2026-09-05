import 'dart:html' as html;

/// APK is hosted on GitHub Releases & raw master repo
const _apkUrl = 'https://raw.githubusercontent.com/brosandy9999/epstopikabante2072/main/apk/eps_topik_ubt_2026.apk';

void triggerApkDownload() {
  final anchor = html.AnchorElement(href: _apkUrl)
    ..setAttribute('download', 'eps_topik_ubt_2026.apk')
    ..setAttribute('target', '_blank')
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}

void tryLaunchInstalledAndroidApp() {
  try {
    // Android Intent URI to launch installed app package directly from browser
    html.window.location.href = 'intent://open#Intent;scheme=epstopik;package=com.example.eps_topik_app;end';
  } catch (_) {
    triggerApkDownload();
  }
}
