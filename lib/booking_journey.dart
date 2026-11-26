import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'appearance.dart';
import 'catalog.dart';
import 'domain.dart';
import 'geo_label.dart';

class LaundryPiece {
  final String id, name, asset, wrinkled;
  final int paise;
  final List<String> wears;
  const LaundryPiece(
    this.id,
    this.name,
    this.asset,
    this.wrinkled,
    this.paise,
    this.wears,
  );
}

class WearGroup {
  final String id, label;
  const WearGroup(this.id, this.label);
}

const wearGroups = [
  WearGroup('men', 'Men'),
  WearGroup('women', 'Women'),
  WearGroup('kids', 'Kids'),
  WearGroup('household', 'Household'),
];

const laundryPieces = [
  LaundryPiece(
    'tshirt',
    'T-shirt',
    'assets/laundry/tshirt.png',
    'assets/laundry/wrinkled/tshirt.png',
    3000,
    ['men', 'women', 'kids'],
  ),
  LaundryPiece(
    'polo',
    'Polo',
    'assets/laundry/polo.png',
    'assets/laundry/wrinkled/polo.png',
    3500,
    ['men'],
  ),
  LaundryPiece(
    'shirt',
    'Shirt',
    'assets/laundry/shirt.png',
    'assets/laundry/wrinkled/shirt.png',
    4000,
    ['men', 'women', 'kids'],
  ),
  LaundryPiece(
    'plaid',
    'Checked shirt',
    'assets/laundry/plaid.png',
    'assets/laundry/wrinkled/plaid.png',
    4500,
    ['men'],
  ),
  LaundryPiece(
    'hoodie',
    'Hoodie',
    'assets/laundry/hoodie.png',
    'assets/laundry/wrinkled/hoodie.png',
    7000,
    ['men'],
  ),
  LaundryPiece(
    'jeans',
    'Jeans',
    'assets/laundry/jeans.png',
    'assets/laundry/wrinkled/jeans.png',
    6000,
    ['men', 'women', 'kids'],
  ),
  LaundryPiece(
    'trousers',
    'Trousers',
    'assets/laundry/trousers.png',
    'assets/laundry/wrinkled/trousers.png',
    5000,
    ['men'],
  ),
  LaundryPiece(
    'shorts',
    'Shorts',
    'assets/laundry/shorts.png',
    'assets/laundry/wrinkled/shorts.png',
    3500,
    ['men', 'kids'],
  ),
  LaundryPiece(
    'kurta',
    'Kurta',
    'assets/laundry/kurta.png',
    'assets/laundry/wrinkled/kurta.png',
    5000,
    ['men', 'women'],
  ),
  LaundryPiece(
    'saree',
    'Saree',
    'assets/laundry/saree.png',
    'assets/laundry/wrinkled/saree.png',
    12000,
    ['women'],
  ),
  LaundryPiece(
    'dress',
    'Dress',
    'assets/laundry/dress.png',
    'assets/laundry/wrinkled/dress.png',
    8000,
    ['women', 'kids'],
  ),
  LaundryPiece(
    'towel',
    'Towel',
    'assets/laundry/towel.png',
    'assets/laundry/wrinkled/towel.png',
    2500,
    ['household'],
  ),
  LaundryPiece(
    'blanket',
    'Blanket',
    'assets/laundry/blanket.png',
    'assets/laundry/wrinkled/blanket.png',
    15000,
    ['household'],
  ),
  LaundryPiece(
    'bedsheet',
    'Bedsheet',
    'assets/laundry/bedsheet.png',
    'assets/laundry/wrinkled/bedsheet.png',
    8000,
    ['household'],
  ),
];

class BookingJourney extends StatefulWidget {
  final DateTime? date;
  final String? window;
  final String? savedPlace;
  final Map<String, int> basket;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onWindowChanged;
  final ValueChanged<String> onDropItem;
  final ValueChanged<String> onRemoveItem;
  final VoidCallback onContinue;
  final VoidCallback onOpenRates;
  final VoidCallback? onLocationTap;

  const BookingJourney({
    super.key,
    required this.date,
    required this.window,
    required this.basket,
    required this.onDateChanged,
    required this.onWindowChanged,
    required this.onDropItem,
    required this.onRemoveItem,
    required this.onContinue,
    required this.onOpenRates,
    this.savedPlace,
    this.onLocationTap,
  });

  @override
  State<BookingJourney> createState() => _BookingJourneyState();
}

class _Drop {
  final String id, asset;
  final Offset from;
  final Offset to;
  const _Drop(this.id, this.asset, this.from, this.to);
}

class _BookingJourneyState extends State<BookingJourney> {
  final stackKey = GlobalKey();
  final basketKey = GlobalKey();
  final pieceKeys = {for (final piece in laundryPieces) piece.id: GlobalKey()};
  String? gpsPlace;
  var popping = false;
  final drops = <_Drop>[];
  var _counts = <String, int>{};

  @override
  void initState() {
    super.initState();
    _absorbBasket();
    if (widget.savedPlace == null) {
      detectCurrentPlace().then((place) {
        if (!mounted || place == null || place.isEmpty) return;
        setState(() => gpsPlace = place);
      });
    }
  }

  @override
  void didUpdateWidget(covariant BookingJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = _counts.values.fold<int>(0, (sum, n) => sum + n);
    _absorbBasket();
    final after = _counts.values.fold<int>(0, (sum, n) => sum + n);
    if (after > before && !MediaQuery.disableAnimationsOf(context)) {
      popping = true;
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => popping = false);
      });
    }
  }

  void _absorbBasket() {
    _counts = Map<String, int>.of(widget.basket);
  }

  int get pieceCount => widget.basket.values.fold<int>(0, (sum, n) => sum + n);

  int get totalPaise => laundryPieces.fold<int>(
    0,
    (sum, piece) => sum + piece.paise * (widget.basket[piece.id] ?? 0),
  );

  DateTime get selected {
    final now = DateUtils.dateOnly(DateTime.now());
    final date = widget.date;
    if (date == null) return now;
    final day = DateUtils.dateOnly(date);
    if (day.isBefore(now)) return now;
    return day;
  }

  void dropPiece(LaundryPiece piece) {
    final skip = MediaQuery.disableAnimationsOf(context);
    final from = _centerOf(pieceKeys[piece.id]);
    final basket = _box(basketKey);
    final stack = _box(stackKey);
    if (skip || from == null || basket == null || stack == null) {
      widget.onDropItem(piece.id);
      return;
    }
    final mouth = basket.localToGlobal(
      Offset(basket.size.width / 2, basket.size.height * .48),
    );
    setState(() {
      drops.add(
        _Drop(
          piece.id,
          piece.wrinkled,
          stack.globalToLocal(from),
          stack.globalToLocal(mouth),
        ),
      );
    });
  }

  Offset? _centerOf(GlobalKey? key) {
    final box = _box(key);
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  RenderBox? _box(GlobalKey? key) {
    final object = key?.currentContext?.findRenderObject();
    return object is RenderBox ? object : null;
  }

  void land(_Drop drop) {
    widget.onDropItem(drop.id);
    if (!mounted) return;
    setState(() => drops.remove(drop));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final strip = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day + index),
    );
    final focus = pieceCount == 0 ? 0 : (widget.window == null ? 1 : 2);
    final place = widget.savedPlace ?? gpsPlace;
    return Stack(
      key: stackKey,
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LocationBar(
              title: 'Current location',
              subtitle: place ?? "We'll pick up from where you are",
              onTap: widget.onLocationTap,
            ),
            const SizedBox(height: 14),
            _WeekCalendar(
              days: strip,
              selected: selected,
              onSelect: widget.onDateChanged,
            ),
            const SizedBox(height: 18),
            _Step(
              index: 1,
              active: focus == 0,
              title: 'Check our rate card',
              child: _RateCard(onOpenRates: widget.onOpenRates),
            ),
            _Step(
              index: 2,
              active: focus == 1,
              title: 'Add what you are sending',
              child: _BasketStep(
                basketKey: basketKey,
                pieceKeys: pieceKeys,
                basket: widget.basket,
                popping: popping,
                totalPaise: totalPaise,
                count: pieceCount,
                onDrop: dropPiece,
                onRemove: widget.onRemoveItem,
              ),
            ),
            _Step(
              index: 3,
              active: focus == 2,
              last: true,
              title: 'Pick a time',
              child: _TimeStep(
                window: widget.window,
                ready: pieceCount > 0,
                onWindowChanged: widget.onWindowChanged,
                onContinue: widget.onContinue,
              ),
            ),
          ],
        ),
        for (final drop in drops)
          _FlyingPiece(
            key: ObjectKey(drop),
            drop: drop,
            onDone: () => land(drop),
          ),
      ],
    );
  }
}

class _LocationBar extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback? onTap;
  const _LocationBar({required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: neuRaised(dark, radius: 22, depth: 4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Bubbler.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Bubbler.ink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: Bubbler.display,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: mutedText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _WeekCalendar({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${months[selected.month - 1]} ${selected.year}',
                  style: const TextStyle(
                    fontFamily: Bubbler.display,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const Icon(Icons.calendar_today_outlined, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var index = 0; index < days.length; index++)
                Expanded(
                  child: _DayChip(
                    key: Key('pickup-day-$index'),
                    day: days[index],
                    label: weekdays[days[index].weekday - 1],
                    selected: DateUtils.isSameDay(days[index], selected),
                    onTap: () => onSelect(days[index]),
                  ),
                ),
            ],
          ),
        ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime day;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DayChip({
    super.key,
    required this.day,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected
        ? Bubbler.ink
        : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4DC) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Bubbler.ink : mutedText(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${day.day}',
              style: TextStyle(
                color: ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int index;
  final bool active, last;
  final String title;
  final Widget child;
  const _Step({
    required this.index,
    required this.active,
    required this.title,
    required this.child,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '$index',
                style: TextStyle(
                  fontFamily: Bubbler.display,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active ? Bubbler.ink : mutedText(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: Bubbler.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: active
                        ? Theme.of(context).colorScheme.onSurface
                        : mutedText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final VoidCallback onOpenRates;
  const _RateCard({required this.onOpenRates});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Starting price for one piece',
          style: TextStyle(fontSize: 12, color: mutedText(context)),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            final dark = Theme.of(context).brightness == Brightness.dark;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final piece in laundryPieces.take(4))
                  SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                      decoration: neuRaised(dark, radius: 18, depth: 3),
                      child: Column(
                        children: [
                          Image.asset(
                            piece.wrinkled,
                            width: 42,
                            height: 42,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            piece.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rupees(piece.paise),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onOpenRates,
            child: const Text('See full rate card'),
          ),
        ),
      ],
    );
  }
}

String _basketArt(int count) {
  if (count <= 0) return 'assets/laundry/basket.png';
  if (count < 4) return 'assets/laundry/basket_half.png';
  return 'assets/laundry/basket_full.png';
}

class _BasketStep extends StatefulWidget {
  final GlobalKey basketKey;
  final Map<String, GlobalKey> pieceKeys;
  final Map<String, int> basket;
  final bool popping;
  final int totalPaise, count;
  final ValueChanged<LaundryPiece> onDrop;
  final ValueChanged<String> onRemove;
  const _BasketStep({
    required this.basketKey,
    required this.pieceKeys,
    required this.basket,
    required this.popping,
    required this.totalPaise,
    required this.count,
    required this.onDrop,
    required this.onRemove,
  });

  @override
  State<_BasketStep> createState() => _BasketStepState();
}

class _BasketStepState extends State<_BasketStep> {
  var wear = 'men';

  @override
  Widget build(BuildContext context) {
    final pieces = [
      for (final piece in laundryPieces)
        if (piece.wears.contains(wear)) piece,
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      decoration: neuRaised(dark, radius: 22, depth: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WearTabs(
            selected: wear,
            onSelect: (id) => setState(() => wear = id),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a piece and watch it drop in',
            style: TextStyle(fontSize: 12, color: mutedText(context)),
          ),
          const SizedBox(height: 8),
          Center(
            child: AnimatedScale(
              scale: widget.popping ? 1.08 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: SizedBox(
                key: widget.basketKey,
                width: 240,
                height: 250,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Image.asset(
                    _basketArt(widget.count),
                    key: ValueKey(_basketArt(widget.count)),
                    width: 240,
                    height: 250,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          if (widget.count > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Laundry total  ${rupees(widget.totalPaise)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: Bubbler.display,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final piece in pieces)
                _PieceChip(
                  key: widget.pieceKeys[piece.id],
                  piece: piece,
                  count: widget.basket[piece.id] ?? 0,
                  onAdd: () => widget.onDrop(piece),
                  onRemove: () => widget.onRemove(piece.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WearTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _WearTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final group in wearGroups)
          Expanded(
            child: InkWell(
              key: Key('wear-${group.id}'),
              onTap: () => onSelect(group.id),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  children: [
                    Text(
                      group.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: group.id == selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: group.id == selected
                            ? Bubbler.ink
                            : mutedText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: group.id == selected
                            ? Bubbler.yellow
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PieceChip extends StatelessWidget {
  final LaundryPiece piece;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _PieceChip({
    super.key,
    required this.piece,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final chosen = count > 0;
    final addKey = Key('laundry-${piece.id}');
    return Material(
      color: chosen ? const Color(0xFFFFF4DC) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: chosen ? Bubbler.yellow : Bubbler.line,
          width: chosen ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        child: Row(
          mainAxisSize: chosen ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Flexible(
              fit: chosen ? FlexFit.tight : FlexFit.loose,
              child: InkWell(
                key: chosen ? null : addKey,
                onTap: onAdd,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        piece.asset,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          piece.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (chosen) ...[
              _QtyButton(
                key: Key('laundry-less-${piece.id}'),
                icon: count == 1 ? Icons.close_rounded : Icons.remove_rounded,
                tooltip: count == 1
                    ? 'Remove ${piece.name}'
                    : 'One less ${piece.name}',
                onTap: onRemove,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              _QtyButton(
                key: addKey,
                icon: Icons.add_rounded,
                tooltip: 'One more ${piece.name}',
                filled: true,
                onTap: onAdd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;
  const _QtyButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? Bubbler.yellow : Colors.white,
        shape: CircleBorder(
          side: BorderSide(color: filled ? Bubbler.yellow : Bubbler.line),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 26,
            height: 26,
            child: Icon(icon, size: 16, color: Bubbler.ink),
          ),
        ),
      ),
    );
  }
}

class _TimeStep extends StatelessWidget {
  final String? window;
  final bool ready;
  final ValueChanged<String> onWindowChanged;
  final VoidCallback onContinue;
  const _TimeStep({
    required this.window,
    required this.ready,
    required this.onWindowChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < sampleWindows.length; index++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == sampleWindows.length - 1 ? 0 : 8,
                  ),
                  child: _TimeCard(
                    key: Key('pickup-window-$index'),
                    label: sampleWindows[index],
                    selected: window == sampleWindows[index],
                    onTap: () => onWindowChanged(sampleWindows[index]),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('home-continue'),
          onPressed: ready && sampleWindows.contains(window)
              ? onContinue
              : null,
          child: const Text('Schedule pickup'),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TimeCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parts = label.split(' – ');
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? const Color(0xFFFFF4DC)
          : (dark ? Bubbler.cardDark : Colors.white),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? Bubbler.yellow : Bubbler.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          child: Column(
            children: [
              Text(
                parts.first,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (parts.length > 1) ...[
                const SizedBox(height: 2),
                Text(
                  parts.last,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: mutedText(context)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FlyingPiece extends StatelessWidget {
  final _Drop drop;
  final VoidCallback onDone;
  const _FlyingPiece({super.key, required this.drop, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeIn,
      onEnd: onDone,
      builder: (context, t, _) {
        final arc = math.sin(t * math.pi) * -36;
        final sink = t < .62 ? 0.0 : ((t - .62) / .38) * 36;
        final pos = Offset.lerp(drop.from, drop.to, t)!;
        final size = 74 - 28 * t;
        final fade = t < .8 ? 1.0 : (1 - (t - .8) / .2).clamp(0.0, 1.0);
        return Positioned(
          left: pos.dx - size / 2,
          top: pos.dy + arc + sink - size / 2,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: math.sin(t * math.pi) * 0.12,
              child: Opacity(
                opacity: fade,
                child: Image.asset(
                  drop.asset,
                  width: size,
                  height: size * 0.72,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
