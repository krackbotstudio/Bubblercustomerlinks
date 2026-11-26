import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'appearance.dart';

abstract class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://apibubbler.krackbot.com/api',
  );
  static const defaultBrandSlug = String.fromEnvironment(
    'BRAND_SLUG',
    defaultValue: 'Vclean',
  );
  static const defaultBrandCode = String.fromEnvironment(
    'BRAND_CODE',
    defaultValue: 'Vclean',
  );
  static const defaultBrandId = String.fromEnvironment(
    'BRAND_ID',
    defaultValue: '87211d7b-1b57-417f-9762-4a5c4d42945a',
  );
  static const assetOrigin = String.fromEnvironment(
    'ASSET_BASE_URL',
    defaultValue: 'https://apibubbler.krackbot.com',
  );

  static String brandSlug = defaultBrandSlug;
  static String brandCode = defaultBrandCode;
  static String brandId = defaultBrandId;
  static String brandName = 'Vclean laundry';
  static String? brandLogoUrl;
  static String? brandPrimaryColor;
  static String? brandSecondaryColor;

  static void setBrand({
    required String slug,
    required String code,
    required String id,
    String? name,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
  }) {
    brandSlug = slug;
    brandCode = code;
    brandId = id;
    if (name != null && name.isNotEmpty) brandName = name;
    brandLogoUrl = logoUrl;
    brandPrimaryColor = primaryColor;
    brandSecondaryColor = secondaryColor;
  }
}

bool hasExplicitBrandInUrl() {
  if (!kIsWeb) return true;
  try {
    final uri = Uri.base;
    const reservedPaths = {
      '',
      'assets',
      'icons',
      'canvaskit',
      'favicon.png',
      'index.html',
      'manifest.json',
      'flutter.js',
      'flutter_bootstrap.js',
      'flutter_service_worker.js',
      'version.json',
    };
    for (final segment in uri.pathSegments) {
      final clean = segment.trim().toLowerCase();
      if (clean.isNotEmpty && !reservedPaths.contains(clean)) {
        return true;
      }
    }
    if (uri.queryParameters.containsKey('brand') ||
        uri.queryParameters.containsKey('b')) {
      return true;
    }
  } catch (_) {}
  return false;
}

String resolveBrandSlug() {
  if (kIsWeb) {
    try {
      final uri = Uri.base;

      const reservedPaths = {
        '',
        'assets',
        'icons',
        'canvaskit',
        'favicon.png',
        'index.html',
        'manifest.json',
        'flutter.js',
        'flutter_bootstrap.js',
        'flutter_service_worker.js',
        'version.json',
      };

      // 1. Direct path: domain.com/vclean or domain.com/sparkle (domain/brandname)
      for (final segment in uri.pathSegments) {
        final clean = segment.trim().toLowerCase();
        if (clean.isNotEmpty && !reservedPaths.contains(clean)) {
          return segment.trim();
        }
      }

      // 2. Hash / Fragment path: domain.com/#/vclean
      if (uri.hasFragment) {
        final frag = uri.fragment.trim();
        final fragParts = frag.split('/').where((s) => s.isNotEmpty).toList();
        for (final part in fragParts) {
          final clean = part.toLowerCase();
          if (clean != 'brand' && clean != 'b' && !reservedPaths.contains(clean)) {
            return part.trim();
          }
        }
      }

      // 3. Query parameter fallback: ?brand=sparkle or ?b=sparkle
      final queryBrand = uri.queryParameters['brand'] ?? uri.queryParameters['b'];
      if (queryBrand != null && queryBrand.trim().isNotEmpty) {
        return queryBrand.trim();
      }

      // 4. Subdomain: sparkle.domain.com or sparkle.bubbler.in
      final hostParts = uri.host.split('.');
      if (hostParts.length > 2) {
        final sub = hostParts.first.toLowerCase().trim();
        if (sub != 'www' && sub != 'app' && sub != 'localhost' && sub != '127') {
          return sub;
        }
      }
    } catch (_) {}
  }
  return AppConfig.brandSlug;
}

class PublicBrandSummary {
  final String id;
  final String name;
  final String code;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? defaultBranchName;

  const PublicBrandSummary({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.defaultBranchName,
  });

  factory PublicBrandSummary.fromJson(Map<String, dynamic> json) {
    return PublicBrandSummary(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? json['businessName'] ?? '') as String,
      code: (json['code'] ?? '') as String,
      logoUrl:
          resolveMediaUrl(json['logoUrl'] as String?) ??
          resolveMediaUrl(json['appIconUrl'] as String?),
      primaryColor: json['primaryColor'] as String?,
      secondaryColor: json['secondaryColor'] as String?,
      defaultBranchName: json['defaultBranchName'] as String?,
    );
  }
}

class Branch {
  final String id, name;
  final String? logoUrl;
  const Branch(this.id, this.name, {this.logoUrl});
}

/// Turn an admin media path into an absolute https URL.
String? resolveMediaUrl(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final parsed = Uri.tryParse(value);
  if (parsed == null) return null;
  if (parsed.hasScheme) {
    return parsed.scheme == 'https' ? parsed.toString() : null;
  }
  if (!value.startsWith('/')) return null;
  final resolved = Uri.parse(AppConfig.assetOrigin).resolve(value);
  if (resolved.scheme != 'https' || resolved.host.isEmpty) return null;
  return resolved.toString();
}

class BrandInfo {
  final String name, privacy, terms;
  final List<Branch> branches;
  final String? logoUrl;
  final String? appIconUrl;
  final String? primaryColor;
  final String? secondaryColor;

  const BrandInfo({
    required this.name,
    required this.privacy,
    required this.terms,
    required this.branches,
    this.logoUrl,
    this.appIconUrl,
    this.primaryColor,
    this.secondaryColor,
  });

  /// Logo uploaded in the admin app, then the app icon, then a branch logo.
  String? get displayLogo {
    final own = resolveMediaUrl(logoUrl) ?? resolveMediaUrl(appIconUrl);
    if (own != null) return own;
    for (final branch in branches) {
      final mark = branch.logoUrl;
      if (mark != null && mark.isNotEmpty) return mark;
    }
    return null;
  }

  factory BrandInfo.parse(Map<String, dynamic> json) {
    final targetBrandId = (json['brandId'] ?? json['id'] ?? AppConfig.brandId) as String;
    final branches = <Branch>[];
    for (final item in (json['branches'] as List? ?? [])) {
      if (item is Map &&
          item['id'] is String &&
          item['name'] is String &&
          (item['brandId'] == null || item['brandId'] == targetBrandId)) {
        branches.add(
          Branch(
            item['id'] as String,
            item['name'] as String,
            logoUrl: resolveMediaUrl(item['logoUrl'] as String?),
          ),
        );
      }
    }
    return BrandInfo(
      name: json['businessName'] as String? ?? json['name'] as String? ?? 'Vclean laundry',
      privacy: json['privacyPolicy'] as String? ?? '',
      terms: json['termsAndConditions'] as String? ?? '',
      branches: branches,
      logoUrl: json['logoUrl'] as String?,
      appIconUrl: json['appIconUrl'] as String?,
      primaryColor: json['primaryColor'] as String?,
      secondaryColor: json['secondaryColor'] as String?,
    );
  }
}

class BrandApi {
  final http.Client client;
  BrandApi(this.client);

  Future<List<String>> loadBanners() async {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/+$'), '');
    final headers = <String, String>{
      if (kIsWeb)
        'x-portal-slug': AppConfig.brandCode
      else ...{
        'X-Brand-Code': AppConfig.brandCode,
        'X-Brand-Id': AppConfig.brandId,
        'x-portal-slug': AppConfig.brandCode,
      },
    };
    final response = await client
        .get(
          Uri.parse('$base/carousel/public'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException('Banners unavailable');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['imageUrls'] as List? ?? [])
        .whereType<String>()
        .map(
          (value) => Uri.parse(AppConfig.assetOrigin).resolve(value).toString(),
        )
        .where((value) => Uri.parse(value).scheme == 'https')
        .toList();
  }

  Future<BrandInfo> load() async {
    final slug = resolveBrandSlug();
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/+$'), '');
    final response = await client
        .get(
          Uri.parse(
            '$base/branding/public/${Uri.encodeComponent(slug)}',
          ),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException('Brand information unavailable');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final brandId = (json['brandId'] ?? json['id'] ?? AppConfig.brandId) as String;
    final brandCode = (json['code'] ?? slug) as String;
    final businessName = (json['businessName'] ?? json['name'] ?? slug) as String;
    final primaryColor = json['primaryColor'] as String?;
    final secondaryColor = json['secondaryColor'] as String?;
    final info = BrandInfo.parse(json);

    AppConfig.setBrand(
      slug: slug,
      code: brandCode,
      id: brandId,
      name: businessName,
      logoUrl: info.displayLogo,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    );
    BrandColors.setDynamicColors(primaryColor, secondaryColor);

    return info;
  }

  Future<List<PublicBrandSummary>> loadAllBrands() async {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/+$'), '');
    try {
      final response = await client
          .get(Uri.parse('$base/branding/public'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['brands'] as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((m) => PublicBrandSummary.fromJson(m))
          .where((b) => b.code.isNotEmpty && b.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<BrandInfo> loadForSlug(String customSlug) async {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/+$'), '');
    final response = await client
        .get(
          Uri.parse(
            '$base/branding/public/${Uri.encodeComponent(customSlug)}',
          ),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException('Brand information unavailable');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final brandId = (json['brandId'] ?? json['id'] ?? AppConfig.brandId) as String;
    final brandCode = (json['code'] ?? customSlug) as String;
    final businessName = (json['businessName'] ?? json['name'] ?? customSlug) as String;
    final primaryColor = json['primaryColor'] as String?;
    final secondaryColor = json['secondaryColor'] as String?;
    final info = BrandInfo.parse(json);

    AppConfig.setBrand(
      slug: customSlug,
      code: brandCode,
      id: brandId,
      name: businessName,
      logoUrl: info.displayLogo,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    );
    BrandColors.setDynamicColors(primaryColor, secondaryColor);

    return info;
  }
}
