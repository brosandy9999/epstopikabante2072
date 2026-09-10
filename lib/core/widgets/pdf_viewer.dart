/// Cross-platform PDF viewer helper.
/// On web: renders an iframe using HtmlElementView.
/// On mobile/desktop: shows a placeholder.
export 'pdf_viewer_stub.dart'
    if (dart.library.html) 'pdf_viewer_web.dart';
