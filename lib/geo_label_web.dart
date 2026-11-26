import 'dart:convert';

import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Browser GPS, then a short place name when the lookup succeeds.
Future<String?> detectCurrentPlace() async {
  try {
    final position = await html.window.navigator.geolocation.getCurrentPosition(
      enableHighAccuracy: false,
      timeout: const Duration(seconds: 8),
    );
    final lat = position.coords?.latitude;
    final lng = position.coords?.longitude;
    if (lat == null || lng == null) return null;
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
    );
    final response = await http
        .get(uri, headers: {'User-Agent': 'BubblerCustomer/1.0'})
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return 'Current location';
    final data = jsonDecode(response.body);
    if (data is! Map || data['address'] is! Map) return 'Current location';
    final address = data['address'] as Map;
    final area =
        address['suburb'] ??
        address['neighbourhood'] ??
        address['road'] ??
        address['city_district'];
    final city =
        address['city'] ?? address['town'] ?? address['village'] ?? address['state'];
    final parts = [area, city].whereType<Object>().map((part) => '$part'.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'Current location';
    return parts.take(2).join(', ');
  } catch (_) {
    return null;
  }
}
