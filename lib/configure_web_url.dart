import 'package:flutter_web_plugins/url_strategy.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void configureAppUrl() {
  usePathUrlStrategy();
}

void updateBrowserUrl(String path) {
  try {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    html.window.history.pushState(null, '', cleanPath);
  } catch (_) {}
}
