import 'dart:ui';

import 'package:flutter/material.dart';

/// VClean badge purple, sampled from the brand mark.
Color? parseHexColor(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  var str = hex.replaceAll('#', '').trim();
  if (str.length == 6) str = 'FF$str';
  if (str.length == 8) {
    final val = int.tryParse(str, radix: 16);
    if (val != null) return Color(val);
  }
  return null;
}

abstract class BrandColors {
  static Color purple = const Color(0xFF5C2786);
  static Color purpleDeep = const Color(0xFF3D1468);
  static Color purpleBright = const Color(0xFF7A45B0);
  static Color purpleSoft = const Color(0xFFE7D4F6);
  static const mist = Color(0xFFFFF4DC);
  static const ink = Color(0xFF1E1C2B);
  static const sheetLight = Color(0xFFFDF6F0);
  static const sheetDark = Color(0xFF1E1C2B);
  static const muted = Color(0xFF6E687C);
  static const mutedDark = Color(0xFFC8C2D4);
  static const danger = Color(0xFFD64550);
  static const logo = 'assets/vclean-logo.png';
  static const logoOnPurple = 'assets/vclean-badge-purple.png';

  static void setDynamicColors(String? primaryHex, String? secondaryHex) {
    final prim = parseHexColor(primaryHex);
    final sec = parseHexColor(secondaryHex);
    if (prim != null) {
      purple = prim;
      final hsl = HSLColor.fromColor(prim);
      purpleDeep = hsl
          .withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0))
          .toColor();
      purpleBright = hsl
          .withLightness((hsl.lightness * 1.3).clamp(0.0, 1.0))
          .toColor();
    }
    if (sec != null) {
      purpleSoft = sec;
    } else if (prim != null) {
      final hsl = HSLColor.fromColor(prim);
      purpleSoft = hsl.withLightness(0.92).withSaturation(0.35).toColor();
    }
  }
}

/// Palette sampled from bubbler.tectangle.com: cream page, navy ink, yellow
/// pills, and white cards with a warm hairline.
abstract final class Bubbler {
  static const cream = Color(0xFFFDF6F0);
  static const ink = Color(0xFF1E1C2B);
  static const navy = Color(0xFF242132);
  static const yellow = Color(0xFFFFC20E);
  static const line = Color(0xFFEFE5DA);
  static const card = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF2C2940);
  static const muted = Color(0xFF6E687C);

  static const display = 'Outfit';
  static const text = 'PlusJakartaSans';
}

/// Flat card palette. Surfaces sit on the cream page with one soft shadow.
abstract final class Neu {
  static const light = Bubbler.cream;
  static const dark = Bubbler.ink;

  static Color base(bool dark) => dark ? Neu.dark : Neu.light;

  static Color card(bool dark) => dark ? Bubbler.cardDark : Bubbler.card;

  static List<BoxShadow> raised(bool dark, {double depth = 6}) => [
    BoxShadow(
      color: dark ? const Color(0x66000000) : const Color(0x14242132),
      offset: Offset(0, depth * .45),
      blurRadius: depth * 2.2,
    ),
  ];
}

BoxDecoration neuRaised(
  bool dark, {
  double radius = 20,
  BoxShape shape = BoxShape.rectangle,
  double depth = 6,
}) => BoxDecoration(
  color: Neu.card(dark),
  shape: shape,
  borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
  border: Border.all(
    color: dark ? const Color(0x14FFFFFF) : Bubbler.line,
  ),
  boxShadow: Neu.raised(dark, depth: depth),
);

/// Inset field well: warm fill and a hairline, not a carved shadow.
BoxDecoration neuPressed(bool dark, {double radius = 16}) => BoxDecoration(
  borderRadius: BorderRadius.circular(radius),
  color: dark ? const Color(0xFF241F36) : const Color(0xFFFFFCF8),
  border: Border.all(
    color: dark ? const Color(0x14FFFFFF) : Bubbler.line,
  ),
);

/// Cream page used behind sign-in and every signed-in screen.
BoxDecoration pageBackdrop(bool dark) => BoxDecoration(
  color: dark ? Bubbler.ink : Bubbler.cream,
);

LinearGradient get brandGradient => const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Bubbler.yellow, Color(0xFFFFD24A)],
);

/// Yellow pill used by the sign-in CTA and selected chips.
BoxDecoration brandRaised({
  double radius = 18,
  BoxShape shape = BoxShape.rectangle,
}) => BoxDecoration(
  gradient: brandGradient,
  shape: shape,
  borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
  boxShadow: const [
    BoxShadow(
      color: Color(0x52F2AE00),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ],
);

/// Borderless input decoration for fields placed inside [NeuField].
const neuBareField = InputDecoration(
  filled: false,
  isDense: true,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  contentPadding: EdgeInsets.symmetric(vertical: 18),
);

Color mutedText(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? BrandColors.mutedDark
    : BrandColors.muted;

Widget _gradientButtonLayer(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  final disabled = states.contains(WidgetState.disabled);
  final pressed = states.contains(WidgetState.pressed);
  return AnimatedOpacity(
    opacity: disabled ? .55 : 1,
    duration: const Duration(milliseconds: 200),
    child: DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        gradient: brandGradient,
        shadows: [
          BoxShadow(
            color: const Color(0x52F2AE00).withValues(alpha: pressed ? .7 : 1),
            blurRadius: pressed ? 10 : 22,
            offset: Offset(0, pressed ? 4 : 10),
          ),
        ],
      ),
      child: child,
    ),
  );
}

Widget _raisedButtonLayer(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  final disabled = states.contains(WidgetState.disabled);
  final dark = Theme.of(context).brightness == Brightness.dark;
  final border = dark ? Bubbler.cream : Bubbler.ink;
  return AnimatedOpacity(
    opacity: disabled ? .45 : 1,
    duration: const Duration(milliseconds: 200),
    child: DecoratedBox(
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: border, width: 1.5)),
        color: Colors.transparent,
      ),
      child: child,
    ),
  );
}

ThemeData customerTheme(bool dark) {
  final foreground = dark ? Bubbler.cream : Bubbler.ink;
  final muted = dark ? BrandColors.mutedDark : BrandColors.muted;
  final canvas = Neu.base(dark);
  final surface = Neu.card(dark);
  final primary = Bubbler.ink;
  final onPrimary = Bubbler.cream;
  final border = dark ? const Color(0x14FFFFFF) : Bubbler.line;
  final field = dark ? const Color(0xFF241F36) : Colors.white;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Bubbler.yellow,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
        onSurface: foreground,
        outline: border,
        error: dark ? const Color(0xFFFF8A93) : BrandColors.danger,
      );
  return ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: canvas,
    fontFamily: Bubbler.text,
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontFamily: Bubbler.display,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.05,
        color: foreground,
      ),
      titleLarge: TextStyle(
        fontFamily: Bubbler.display,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: foreground,
      ),
      bodyMedium: TextStyle(
        fontFamily: Bubbler.text,
        fontSize: 14,
        color: foreground,
      ),
      bodySmall: TextStyle(
        fontFamily: Bubbler.text,
        fontSize: 12,
        height: 1.4,
        color: muted,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        fontFamily: Bubbler.display,
        color: foreground,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => Container(
        width: 40,
        height: 40,
        decoration: neuRaised(dark, shape: BoxShape.circle, depth: 4),
        child: Icon(Icons.arrow_back_rounded, size: 20, color: foreground),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: field,
      hintStyle: TextStyle(color: muted.withValues(alpha: .8), fontSize: 14),
      labelStyle: TextStyle(color: muted, fontSize: 14),
      floatingLabelStyle: TextStyle(
        color: primary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Bubbler.ink, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      // Same glowing gradient pill as the sign-in "Send OTP" button.
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: Bubbler.ink,
        disabledForegroundColor: Bubbler.ink,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: Bubbler.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        backgroundBuilder: _gradientButtonLayer,
      ),
    ),
    // Raised neumorphic pill, like "Continue as guest" on sign-in.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        foregroundColor: foreground,
        disabledForegroundColor: foreground,
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        elevation: 0,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: Bubbler.text,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        backgroundBuilder: _raisedButtonLayer,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Bubbler.navy,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Bubbler.yellow,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Bubbler.ink
            : (dark ? const Color(0xFF6B6080) : Colors.white),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Bubbler.yellow
            : (dark ? const Color(0xFF241F36) : const Color(0xFFEFE5DA)),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      elevation: 0,
      pressElevation: 0,
      side: BorderSide(color: border),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    dividerColor: border,
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primary
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(onPrimary),
    ),
  );
}

/// Cream wash used behind splash and welcome, with a yellow glow.
class BrandBackdrop extends StatelessWidget {
  final Widget? child;
  const BrandBackdrop({super.key, this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: Bubbler.cream),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          top: -70,
          right: -30,
          child: _GlowOrb(240, Color(0x66FFC20E)),
        ),
        const Positioned(
          top: 220,
          left: -80,
          child: _GlowOrb(200, Color(0x33242132)),
        ),
        const Positioned(
          bottom: 80,
          right: -40,
          child: _GlowOrb(160, Color(0x44FFC20E)),
        ),
        ?child,
      ],
    ),
  );
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb(this.size, this.color);

  @override
  Widget build(BuildContext context) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );
}

/// Frosted surface. Sits on [BrandBackdrop] or the app gradient.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color =
        tint ?? (dark ? const Color(0xCC241433) : const Color(0xD9FFFFFF));
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? .16 : .72),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x14242132),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  final String title, subtitle;
  const PageHeading(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: TextStyle(fontSize: 14, height: 1.4, color: mutedText(context)),
      ),
      const SizedBox(height: 20),
    ],
  );
}

/// Title row for a tab or pushed page: login-style heading, muted subtitle
/// and optional round actions on the right.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  const ScreenHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.actions = const [],
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            for (final action in actions) ...[
              const SizedBox(width: 10),
              action,
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: mutedText(context),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Pressed-in round well holding an icon, as on the sign-in fields.
class IconChip extends StatelessWidget {
  final Widget child;
  final double size;
  const IconChip(this.child, {super.key, this.size = 38});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: neuPressed(
      Theme.of(context).brightness == Brightness.dark,
      radius: size / 2,
    ),
    child: child,
  );
}

/// Raised input shell matching the sign-in phone field. Pair the field
/// inside with [neuBareField] so it draws no border of its own.
class NeuField extends StatelessWidget {
  final Widget child;
  final Widget? leading;
  final EdgeInsetsGeometry margin;
  const NeuField({
    super.key,
    required this.child,
    this.leading,
    this.margin = EdgeInsets.zero,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: Container(
      padding: EdgeInsets.fromLTRB(leading == null ? 18 : 10, 0, 16, 0),
      decoration: neuRaised(
        Theme.of(context).brightness == Brightness.dark,
        radius: 20,
        depth: 5,
      ),
      child: leading == null
          ? child
          : Row(
              children: [
                leading!,
                const SizedBox(width: 12),
                Expanded(child: child),
              ],
            ),
    ),
  );
}

/// Round raised icon button; [accent] gives it the brand gradient.
class NeuIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool accent;
  final double size;
  const NeuIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accent = false,
    this.size = 44,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onPressed == null ? .55 : 1,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: accent
            ? const BoxDecoration(
                color: Bubbler.yellow,
                shape: BoxShape.circle,
              )
            : const BoxDecoration(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 21),
          style: IconButton.styleFrom(
            foregroundColor: accent
                ? Bubbler.ink
                : Theme.of(context).colorScheme.onSurface,
            disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
            fixedSize: Size(size, size),
          ),
        ),
      ),
    );
  }
}

/// Selectable tile: raised when idle, brand gradient when chosen.
class NeuOption extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  const NeuOption({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.radius = 18,
    this.padding = const EdgeInsets.all(14),
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = selected
        ? Bubbler.ink
        : Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedOpacity(
        opacity: onTap == null ? .55 : 1,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: selected
              ? BoxDecoration(
                  color: Bubbler.yellow,
                  borderRadius: BorderRadius.circular(radius),
                )
              : BoxDecoration(
                  color: dark ? Bubbler.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: dark ? const Color(0x14FFFFFF) : Bubbler.line,
                  ),
                ),
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: padding,
                child: IconTheme.merge(
                  data: IconThemeData(color: ink),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: ink),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scaffold for pushed pages, painted with the sign-in backdrop.
class NeuPage extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget body;
  const NeuPage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: pageBackdrop(Theme.of(context).brightness == Brightness.dark),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        titleSpacing: 4,
        actions: [...actions, const SizedBox(width: 12)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: body,
        ),
      ),
    ),
  );
}

class PreviewNote extends StatelessWidget {
  final String text;
  const PreviewNote({
    super.key,
    this.text =
        'Preview only · sample prices and slots. No pickup will be scheduled.',
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
    ),
  );
}

String serviceAsset(String id) =>
    'assets/service-icons/${switch (id) {
      'daily' => 'wash-and-fold',
      'pressed' => 'wash-and-iron',
      'delicate' => 'dry-cleaning',
      'shoes' => 'shoe-cleaning',
      'iron' => 'steam-iron',
      _ => 'home-linen',
    }}.png';

class ServiceArt extends StatelessWidget {
  final String id;
  final double size;
  const ServiceArt(this.id, {super.key, this.size = 96});
  @override
  Widget build(BuildContext context) => Image.asset(
    serviceAsset(id),
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}

void showDocument(BuildContext context, String title, String body) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * .78,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  body.isEmpty
                      ? 'This document is temporarily unavailable. Please try again after the connection is restored.'
                      : body,
                  style: const TextStyle(height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Store mark from the admin branding payload. A missing or broken logo
/// shows the store's own initials.
class BrandMark extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const BrandMark({
    super.key,
    required this.url,
    required this.name,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    final mark = url?.trim() ?? '';
    final initials = _BrandInitials(name: name, size: size);
    if (mark.isEmpty) return initials;
    return Image.network(
      mark,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: name,
      errorBuilder: (_, _, _) => initials,
    );
  }
}

class _BrandInitials extends StatelessWidget {
  final String name;
  final double size;
  const _BrandInitials({required this.name, required this.size});

  String get letters {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final word = parts.first;
      return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
    }
    return parts.map((part) => part[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Bubbler.cream,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            letters,
            style: TextStyle(
              fontFamily: Bubbler.display,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
              color: Bubbler.ink,
            ),
          ),
        ),
      ),
    );
  }
}
