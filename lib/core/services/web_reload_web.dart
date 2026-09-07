import 'dart:html' as html;

void reloadBrowserPage() {
  html.window.location.reload();
}

void openBrowserUrl(String url) {
  html.window.open(url, '_blank');
}
