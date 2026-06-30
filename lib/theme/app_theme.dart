// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/theme/app_theme.dart
// FIX: CardTheme() → CardThemeData() (required in Flutter 3.16+)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Primary Palette ────────────────────────────────────────────────────────
  static const primary       = Color(0xFF2D6BFF); // vibrant medical blue
  static const primaryDark   = Color(0xFF1A4FCC);
  static const primaryLight  = Color(0xFFEEF3FF);

  // ── Secondary / Accent ──────────────────────────────────────────────────────
  static const secondary = Color(0xFF00C9A7); // health teal / mint
  static const accent    = Color(0xFF00C9A7);

  // ── Role Colors ────────────────────────────────────────────────────────────
  static const doctor  = Color(0xFF0A84FF);
  static const patient = Color(0xFF00C9A7);
  static const admin   = Color(0xFF7B5EA7);

  // ── Status ──────────────────────────────────────────────────────────────────
  static const success = Color(0xFF00B87C);
  static const warning = Color(0xFFFF9500);
  static const error   = Color(0xFFFF3B5C);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const background    = Color(0xFFF5F7FB); // soft off-white
  static const surface       = Color(0xFFFFFFFF);
  static const card          = Color(0xFFFFFFFF);
  static const border        = Color(0xFFE8ECF4);
  static const textPrimary   = Color(0xFF0D1B3E); // deep navy
  static const textSecondary = Color(0xFF6B7A99);
  static const textHint      = Color(0xFFA0AABB);
}

/// Centralised gradients used on headers and hero sections.
class AppGradients {
  static const patientHeader = LinearGradient(
    colors: [Color(0xFF2D6BFF), Color(0xFF00C9A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const doctorHeader = LinearGradient(
    colors: [Color(0xFF0A84FF), Color(0xFF0055CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const adminHeader = LinearGradient(
    colors: [Color(0xFF7B5EA7), Color(0xFF4A3580)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const loginHero = LinearGradient(
    colors: [Color(0xFF0D1B3E), Color(0xFF2D6BFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const greenHeader = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF00B87C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const purpleHeader = LinearGradient(
    colors: [Color(0xFF7B5EA7), Color(0xFF4A3580)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const button = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const logo = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Reusable elevation shadows.
class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> button(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.30),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];
}

/// Border-radius tokens.
class AppRadius {
  static const card = 20.0;
  static const button = 14.0;
  static const input = 14.0;
  static const chip = 20.0;
  static const nav = 24.0;
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        background: AppColors.background,
      ).copyWith(secondary: AppColors.secondary),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.poppins(
            color: AppColors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.poppins(
            color: AppColors.textHint, fontSize: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Logo
// ─────────────────────────────────────────────────────────────────────────────

enum AppLogoSize { small, medium, large }

/// Rounded-square gradient logo with a monitor-heart (pulse) icon.
class AppLogo extends StatelessWidget {
  final AppLogoSize size;
  final bool glow;

  const AppLogo({super.key, this.size = AppLogoSize.medium, this.glow = true});

  double get _box {
    switch (size) {
      case AppLogoSize.large:
        return 80;
      case AppLogoSize.small:
        return 32;
      case AppLogoSize.medium:
        return 48;
    }
  }

  double get _radius {
    switch (size) {
      case AppLogoSize.large:
        return 22;
      case AppLogoSize.small:
        return 12;
      case AppLogoSize.medium:
        return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _box,
      height: _box,
      decoration: BoxDecoration(
        gradient: AppGradients.logo,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.35),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.monitor_heart_rounded,
        color: Colors.white,
        size: _box * 0.6,
      ),
    );
  }
}

/// "Smart" + "Care" wordmark. Set [onDark] for white "Smart" on dark headers.
class AppLogoText extends StatelessWidget {
  final double fontSize;
  final bool onDark;
  final String? subtitle;

  const AppLogoText({
    super.key,
    this.fontSize = 28,
    this.onDark = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final smartColor = onDark ? Colors.white : AppColors.textPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.1),
            children: [
              TextSpan(text: 'Smart', style: TextStyle(color: smartColor)),
              const TextSpan(
                  text: 'Care', style: TextStyle(color: AppColors.secondary)),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(
              fontSize: fontSize * 0.45,
              color: (onDark ? Colors.white : AppColors.textSecondary)
                  .withOpacity(0.6),
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact logo + wordmark for app bars (medium logo + "SmartCare").
class AppBarLogo extends StatelessWidget {
  final bool onDark;
  const AppBarLogo({super.key, this.onDark = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(size: AppLogoSize.small, glow: false),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                fontSize: 19, fontWeight: FontWeight.w700),
            children: [
              TextSpan(
                  text: 'Smart',
                  style: TextStyle(
                      color: onDark ? Colors.white : AppColors.textPrimary)),
              const TextSpan(
                  text: 'Care', style: TextStyle(color: AppColors.secondary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-width gradient button with shadow and tap-scale animation.
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Gradient gradient;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient = AppGradients.button,
    this.height = 54,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: enabled
                ? widget.gradient
                : LinearGradient(colors: [
                    AppColors.textHint.withOpacity(0.5),
                    AppColors.textHint.withOpacity(0.5)
                  ]),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: enabled ? AppShadows.button(AppColors.primary) : null,
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

/// Right-to-left slide page route to use for navigation transitions.
class SlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  SlideRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Gradient header used on all dashboards
class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;
  final Color startColor;
  final Color endColor;
  final List<Widget>? chips;
  final IconData? illustration;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    this.startColor = AppColors.primary,
    this.endColor = AppColors.secondary,
    this.chips,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w400)),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 13)),
                if (chips != null) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: chips!),
                ],
              ],
            ),
          ),
          if (illustration != null)
            Icon(illustration,
                size: 64, color: Colors.white.withOpacity(0.4)),
        ],
      ),
    );
  }
}

/// Stat card for dashboards
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section title with optional action
class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!,
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: onButton,
                  child: Text(buttonLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Role badge chip shown in dashboard headers
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (role.toLowerCase()) {
      case 'doctor':
        icon = Icons.medical_services_outlined;
        break;
      case 'admin':
        icon = Icons.admin_panel_settings_outlined;
        break;
      default:
        icon = Icons.person_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(role.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}