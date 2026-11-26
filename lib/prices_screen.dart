import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'appearance.dart';
import 'brand_api.dart';
import 'catalog.dart';
import 'customer_api.dart';

class PricesScreen extends StatefulWidget {
  final List<Branch> branches;
  final CatalogLoader loadCatalogue;
  final Future<void> Function()? refreshBranches;
  const PricesScreen({
    super.key,
    required this.branches,
    required this.loadCatalogue,
    this.refreshBranches,
  });
  @override
  State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen>
    with WidgetsBindingObserver {
  final search = TextEditingController();
  final scroll = ScrollController();
  String? branchId, flippedId, error;
  var wear = 'men';
  List<CatalogItem> items = [];
  bool loading = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    syncBranch();
  }

  @override
  void didUpdateWidget(covariant PricesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.branches.any((b) => b.id == branchId)) syncBranch();
  }

  void syncBranch() {
    final next = widget.branches.isEmpty ? null : widget.branches.first.id;
    branchId = next;
    if (next != null) {
      load(next);
    } else {
      generation++;
      items = [];
      loading = false;
      error = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && branchId != null && !loading) {
      unawaited(refresh());
    }
  }

  Future<void> load(String id) async {
    final request = ++generation;
    setState(() {
      branchId = id;
      loading = true;
      error = null;
      items = [];
      flippedId = null;
    });
    try {
      final result = await widget.loadCatalogue(id);
      if (!mounted || request != generation) return;
      setState(() {
        items = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted || request != generation) return;
      setState(() {
        loading = false;
        error = e is ApiException
            ? e.message
            : 'Prices could not be loaded. Please try again.';
      });
    }
  }

  Future<void> refresh() async {
    if (widget.refreshBranches != null) await widget.refreshBranches!();
    if (!mounted) return;
    if (branchId != null) {
      await load(branchId!);
    }
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = items
        .where((item) => item.listedFor(wear) && item.matches(search.text))
        .toList();
    return RefreshIndicator(
      onRefresh: refresh,
      child: CustomScrollView(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScreenHeader(
                    'Pricing',
                    subtitle: 'Tap any item to flip it and see its prices.',
                    actions: [
                      NeuIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh prices',
                        onPressed: loading ? null : refresh,
                      ),
                    ],
                  ),
                  if (widget.branches.isNotEmpty) ...[
                    _BranchPicker(
                      branches: widget.branches,
                      selectedId: branchId,
                      onSelect: (id) {
                        if (id == branchId) return;
                        search.clear();
                        if (scroll.hasClients) scroll.jumpTo(0);
                        load(id);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _PriceWearBar(
                    selected: wear,
                    onSelect: (id) {
                      if (id == wear) return;
                      setState(() {
                        wear = id;
                        flippedId = null;
                      });
                      if (scroll.hasClients) scroll.jumpTo(0);
                    },
                  ),
                  const SizedBox(height: 14),
                  NeuField(
                    leading: IconChip(
                      Icon(
                        Icons.search_rounded,
                        size: 19,
                        color: mutedText(context),
                      ),
                    ),
                    child: TextField(
                      key: const Key('price-search'),
                      controller: search,
                      onChanged: (_) => setState(() => flippedId = null),
                      decoration: neuBareField.copyWith(
                        hintText: 'Search by item, segment, or service…',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading catalogue prices…'),
                  ],
                ),
              ),
            )
          else if (error != null || branchId == null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                decoration: neuRaised(
                  Theme.of(context).brightness == Brightness.dark,
                  radius: 26,
                  depth: 7,
                ),
                child: Column(
                  children: [
                    IconChip(
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 22,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      size: 48,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      error ??
                          'Branches could not be loaded. Please try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.4, color: mutedText(context)),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: refresh,
                      child: const Text('Retry prices'),
                    ),
                  ],
                ),
              ),
            )
          else if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  items.isEmpty
                      ? 'No catalogue prices are available for this branch yet.'
                      : items.any((item) => item.listedFor(wear))
                      ? 'No matching items. Try another search.'
                      : 'No items in this category.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.crossAxisExtent - 16) / 2;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: math.max(236, width * 1.42),
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filtered[index];
                      return PriceFlipCard(
                        key: ValueKey('$branchId/${item.id}'),
                        item: item,
                        wear: wear,
                        flipped: flippedId == item.id,
                        onTap: () => setState(
                          () =>
                              flippedId = flippedId == item.id ? null : item.id,
                        ),
                      );
                    }, childCount: filtered.length),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

const _priceWears = [
  ('men', 'Men'),
  ('women', 'Women'),
  ('kids', 'Kids'),
  ('household', 'Household'),
];

class _BranchPicker extends StatelessWidget {
  final List<Branch> branches;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  const _BranchPicker({
    required this.branches,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: neuRaised(dark, radius: 22, depth: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Bubbler.yellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 18,
              color: Bubbler.ink,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Branch',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: mutedText(context),
                  ),
                ),
                const SizedBox(height: 2),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final branch in branches)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: InkWell(
                            key: Key('branch-${branch.id}'),
                            onTap: () => onSelect(branch.id),
                            child: _LinkLabel(
                              label: branch.name,
                              selected: branch.id == selectedId,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceWearBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _PriceWearBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final group in _priceWears)
          Expanded(
            child: InkWell(
              key: Key('price-wear-${group.$1}'),
              onTap: () => onSelect(group.$1),
              child: _LinkLabel(
                label: group.$2,
                selected: group.$1 == selected,
                centered: true,
              ),
            ),
          ),
      ],
    );
  }
}

class _LinkLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final bool centered;
  const _LinkLabel({
    required this.label,
    required this.selected,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontFamily: selected ? Bubbler.display : null,
        fontSize: centered ? 13 : (selected ? 16 : 14),
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected
            ? Theme.of(context).colorScheme.onSurface
            : mutedText(context),
      ),
    );
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        centered ? SizedBox(width: double.infinity, child: text) : text,
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 3,
          width: selected ? 18 : 0,
          decoration: BoxDecoration(
            color: Bubbler.yellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class PriceFlipCard extends StatelessWidget {
  final CatalogItem item;
  final String wear;
  final bool flipped;
  final VoidCallback onTap;
  const PriceFlipCard({
    super.key,
    required this.item,
    required this.wear,
    required this.flipped,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${item.name}, tap to ${flipped ? 'see image' : 'see prices'}',
    child: InkWell(
      key: Key('price-${item.id}'),
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: flipped ? 1 : 0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        builder: (context, value, _) {
          final back = value >= .5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateY(value * math.pi),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(back ? math.pi : 0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: neuRaised(
                  Theme.of(context).brightness == Brightness.dark,
                  radius: 22,
                  depth: 4,
                ),
                child: back ? backFace(context) : frontFace(context),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget fromPrice(BuildContext context) {
    final amount = item.startingPrice;
    if (amount == null) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'From ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: mutedText(context),
              ),
            ),
            TextSpan(
              text: rupees(amount),
              style: TextStyle(
                fontFamily: Bubbler.display,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget frontFace(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF242132) : const Color(0xFFFFF6EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CatalogArt(item: item, wear: wear),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              fromPrice(context),
            ],
          ),
        ),
      ],
    );
  }
  Widget backFace(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        fromPrice(context),
        const Divider(height: 18),
        Expanded(
          child: item.prices.isEmpty
              ? const Text(
                  'No prices listed yet.',
                  style: TextStyle(fontSize: 11),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final price in item.prices)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      price.segment,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      price.service,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    rupees(price.paise),
                                    style: TextStyle(
                                      fontFamily: Bubbler.display,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to return',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    ),
  );
}

/// Garment from the latest clothes sheet, when the catalogue name matches.
String? garmentAssetFor(String name, {String wear = ''}) {
  final text = name.toLowerCase();
  const root = 'assets/laundry/catalog';
  final kids = wear == 'kids';
  if (text.contains('t-shirt') ||
      text.contains('tshirt') ||
      text.contains('t shirt') ||
      text.contains('tee shirt')) {
    return kids ? '$root/kidstee.png' : '$root/tshirt.png';
  }
  if (text.contains('polo')) return '$root/polo.png';
  if (text.contains('hoodie') || text.contains('sweat')) {
    return kids ? '$root/kidhoodie.png' : '$root/hoodie.png';
  }
  if (text.contains('blazer') ||
      text.contains('suit') ||
      text.contains('jacket')) {
    return '$root/blazer.png';
  }
  if (text.contains('kurti')) return '$root/kurti.png';
  if (text.contains('kurta')) return '$root/kurta.png';
  if (text.contains('salwar') || text.contains('kameez')) {
    return '$root/salwar.png';
  }
  if (text.contains('lehenga') || text.contains('skirt')) {
    return kids ? '$root/kidskirt.png' : '$root/skirt.png';
  }
  if (text.contains('saree') || text.contains('sari')) return '$root/saree.png';
  if (text.contains('uniform')) return '$root/uniform.png';
  if (text.contains('jean')) {
    return kids ? '$root/kidpants.png' : '$root/trousers.png';
  }
  if (text.contains('trouser') || text.contains('pant')) {
    return kids ? '$root/kidpants.png' : '$root/trousers.png';
  }
  if (text.contains('short')) {
    return kids ? '$root/kidshorts.png' : '$root/shorts.png';
  }
  if (text.contains('dress') || text.contains('gown')) {
    return kids ? '$root/kiddress.png' : '$root/dress.png';
  }
  if (text.contains('curtain') || text.contains('drape')) {
    return '$root/curtain.png';
  }
  if (text.contains('towel')) return '$root/towel.png';
  if (text.contains('blanket') ||
      text.contains('quilt') ||
      text.contains('comforter')) {
    return '$root/blanket.png';
  }
  if (text.contains('pillow') || text.contains('cushion')) {
    return '$root/pillow.png';
  }
  if (text.contains('bedsheet') ||
      text.contains('bed sheet') ||
      text.contains('linen')) {
    return '$root/bedsheet.png';
  }
  if (text.contains('shirt')) return '$root/shirt.png';
  return null;
}

class CatalogArt extends StatelessWidget {
  final CatalogItem item;
  final String wear;
  const CatalogArt({super.key, required this.item, this.wear = ''});
  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Icon(
        switch (item.icon) {
          'human-male' => Icons.man,
          'human-female' => Icons.woman,
          'human-child' => Icons.child_care,
          'washing-machine' ||
          'tumble-dryer' => Icons.local_laundry_service_outlined,
          'coat-rack' => Icons.checkroom,
          'plus-circle' => Icons.add_circle_outline,
          _ => Icons.checkroom,
        },
        size: 52,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    final local = garmentAssetFor(item.name, wear: wear);
    final image = item.imageUri;
    if (image == null && local != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
        child: Image.asset(local, fit: BoxFit.contain),
      );
    }
    return image == null
        ? fallback
        : Image.network(
            image.toString(),
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => fallback,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : fallback,
          );
  }
}
