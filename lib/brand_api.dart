import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

class Branch {
  final String id, name;
  const Branch(this.id, this.name);
}

class BrandInfo {
  final String name, privacy, terms;
  final List<Branch> branches;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;

  const BrandInfo({
    required this.name,
    required this.privacy,
    required this.terms,
    required this.branches,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
  });

  factory BrandInfo.parse(Map<String, dynamic> json) {
    final targetBrandId = (json['brandId'] ?? json['id'] ?? AppConfig.brandId) as String;
    final branches = <Branch>[];
    for (final item in (json['branches'] as List? ?? [])) {
      if (item is Map &&
          item['id'] is String &&
          item['name'] is String &&
          (item['brandId'] == null || item['brandId'] == targetBrandId)) {
        branches.add(Branch(item['id'] as String, item['name'] as String));
      }
    }
    return BrandInfo(
      name: json['businessName'] as String? ?? json['name'] as String? ?? 'Vclean laundry',
      privacy: json['privacyPolicy'] as String? ?? '',
      terms: json['termsAndConditions'] as String? ?? '',
      branches: branches,
      logoUrl: json['logoUrl'] as String?,
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
    final response = await client
        .get(
          Uri.parse('$base/carousel/public'),
          headers: {
            'X-Brand-Code': AppConfig.brandCode,
            'X-Brand-Id': AppConfig.brandId,
          },
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
    final logoUrl = json['logoUrl'] as String?;

    AppConfig.setBrand(
      slug: slug,
      code: brandCode,
      id: brandId,
      name: businessName,
      logoUrl: logoUrl,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    );

    return BrandInfo.parse(json);
  }
}
