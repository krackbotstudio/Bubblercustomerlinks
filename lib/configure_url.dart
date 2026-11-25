export 'configure_non_web_url.dart'
    if (dart.library.html) 'configure_web_url.dart'
    if (dart.library.js_interop) 'configure_web_url.dart';
