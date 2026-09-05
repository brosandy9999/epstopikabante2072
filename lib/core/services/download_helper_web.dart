import 'dart:html' as html;

/// APK is hosted on GitHub Releases (Firebase Spark plan doesn't allow .apk files)
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
