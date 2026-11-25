import 'dart:convert';
import 'package:flutter/material.dart';
import 'appearance.dart';
import 'brand_api.dart';
import 'configure_url.dart';

class BrandSelectorScreen extends StatefulWidget {
  final Future<List<PublicBrandSummary>> Function() loadBrands;
  final ValueChanged<PublicBrandSummary> onSelectBrand;

  const BrandSelectorScreen({
    super.key,
    required this.loadBrands,
    required this.onSelectBrand,
  });

  @override
  State<BrandSelectorScreen> createState() => _BrandSelectorScreenState();
}

class _BrandSelectorScreenState extends State<BrandSelectorScreen> {
  List<PublicBrandSummary> _allBrands = [];
  List<PublicBrandSummary> _filtered = [];
  bool _loading = true;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final list = await widget.loadBrands();
    if (mounted) {
      setState(() {
        _allBrands = list;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) {
      _filtered = List.from(_allBrands);
    } else {
      _filtered = _allBrands.where((b) {
        return b.name.toLowerCase().contains(query) ||
            b.code.toLowerCase().contains(query) ||
            (b.defaultBranchName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: neuRaised(false, radius: 14, depth: 3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/bubbler-logo.jpg',
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_laundry_service,
                              color: Color(0xFFF59E0B),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'bubblercustomer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5CF6),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Choose Your Laundry',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1640),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: neuPressed(false, radius: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) {
                        setState(() {
                          _search = val;
                          _applyFilter();
                        });
                      },
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Color(0xFF8E8EA8)),
                        hintText: 'Search laundry by name or branch...',
                        hintStyle: TextStyle(fontSize: 14, color: Color(0xFFA0A0BA)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Tile grid
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off,
                                      size: 48, color: Color(0xFFA0A0BA)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No laundry found for "$_search"',
                                    style: const TextStyle(
                                        color: Color(0xFF6B6880), fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.08,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final brand = _filtered[index];
                                return _BrandTile(
                                  brand: brand,
                                  onTap: () => widget.onSelectBrand(brand),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  final PublicBrandSummary brand;
  final VoidCallback onTap;

  const _BrandTile({
    required this.brand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final prim = parseHexColor(brand.primaryColor) ?? const Color(0xFF5C2786);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: neuRaised(false, radius: 20, depth: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: prim.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                    ? Image.network(
                        brand.logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _InitialAvatar(brand: brand, prim: prim),
                      )
                    : _InitialAvatar(brand: brand, prim: prim),
              ),
            ),
            const SizedBox(height: 10),
            // Brand Name
            Text(
              brand.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1640),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            // Branch or subtitle
            Text(
              brand.defaultBranchName != null && brand.defaultBranchName!.isNotEmpty
                  ? '📍 ${brand.defaultBranchName}'
                  : brand.code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8E8EA8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final PublicBrandSummary brand;
  final Color prim;

  const _InitialAvatar({required this.brand, required this.prim});

  @override
  Widget build(BuildContext context) {
    final letter = brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'B';
    return Container(
      color: prim.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: prim,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
