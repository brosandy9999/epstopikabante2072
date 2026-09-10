import 'dart:html' as html;

/// APK download helper for Web clients
void triggerApkDownload() {
  try {
    final href = html.window.location.href.toLowerCase();
    String apkPath;

    if (href.contains('github.io')) {
      apkPath = 'https://brosandy9999.github.io/epstopikabante2072/apk/eps_topik_ubt_2026.apk';
    } else if (href.contains('firebaseapp.com') || href.contains('web.app')) {
      apkPath = 'https://topik-abante.web.app/apk/eps_topik_ubt_2026.apk';
    } else {
      apkPath = 'apk/eps_topik_ubt_2026.apk';
    }

    final anchor = html.AnchorElement(href: apkPath)
      ..setAttribute('download', 'eps_topik_ubt_2026.apk')
      ..setAttribute('target', '_blank')
      ..setAttribute('rel', 'noopener noreferrer')
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  } catch (e) {
    html.window.open('apk/eps_topik_ubt_2026.apk', '_blank');
  }
}

void tryLaunchInstalledAndroidApp() {
  try {
    html.window.location.href =
        'intent://open#Intent;scheme=epstopik;package=com.example.eps_topik_app;end';
  } catch (_) {
    triggerApkDownload();
  }
}

void triggerJsonFileDownload(String filename, String content) {
  try {
    final blob = html.Blob([content], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } catch (_) {}
}
