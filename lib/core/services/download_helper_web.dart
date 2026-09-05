import 'dart:html' as html;

/// APK is hosted on GitHub Releases (Firebase Spark plan doesn't allow .apk files)
const _apkUrl = 'https://github.com/brosandy9999/ubttest2026/releases/download/v1.0.0/EPS-TOPIK.apk';

void triggerApkDownload() {
  final anchor = html.AnchorElement(href: _apkUrl)
    ..setAttribute('download', 'EPS-TOPIK-UBT-Practice.apk')
    ..setAttribute('target', '_blank')
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}
