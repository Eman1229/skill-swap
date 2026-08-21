import 'package:flutter/material.dart';

/// SkillSwapX Centralized Theme Colors & Light Mode Visual Enhancements
class AppColors {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF0F5FF);
  static const Color lightCardSurface = Colors.white;
  static const Color lightCardBorder = Color(0xFFEEF2FF);
  static const Color lightChipBorder = Color(0xFFBAE6FD);

  // Primary Accent Gradient Colors
  static const Color primaryStart = Color(0xFF0284C7);
  static const Color primaryEnd = Color(0xFF0EA5E9);

  // AI Gradient Accent Colors
  static const Color aiGradientStart = Color(0xFF0284C7);
  static const Color aiGradientEnd = Color(0xFF8B5CF6);

  // Progress Bar Gradients
  static const Color progressOngoingStart = Color(0xFF0284C7);
  static const Color progressOngoingEnd = Color(0xFF0EA5E9);
  static const Color progressCompleteStart = Color(0xFF10B981);
  static const Color progressCompleteEnd = Color(0xFF059669);

  // Status Badge Colors (Semantic)
  // Completed - Green
  static const Color badgeCompletedBgLight = Color(0xFFD1FAE5);
  static const Color badgeCompletedFgLight = Color(0xFF059669);
  static const Color badgeCompletedBgDark = Color(0x2610B981);
  static const Color badgeCompletedFgDark = Color(0xFF10B981);

  // Ongoing - Blue
  static const Color badgeOngoingBgLight = Color(0xFFE0F2FE);
  static const Color badgeOngoingFgLight = Color(0xFF0284C7);
  static const Color badgeOngoingBgDark = Color(0x260284C7);
  static const Color badgeOngoingFgDark = Color(0xFF38BDF8);

  // Upcoming - Orange
  static const Color badgeUpcomingBgLight = Color(0xFFFFEDD5);
  static const Color badgeUpcomingFgLight = Color(0xFFD97706);
  static const Color badgeUpcomingBgDark = Color(0x26F97316);
  static const Color badgeUpcomingFgDark = Color(0xFFF97316);

  // Shadows
  static const BoxShadow cardShadowLight = BoxShadow(
    color: Color.fromRGBO(15, 23, 60, 0.08),
    blurRadius: 20,
    offset: Offset(0, 4),
  );

  static const BoxShadow buttonShadowLight = BoxShadow(
    color: Color.fromRGBO(2, 132, 199, 0.35),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
}

class AppGradients {
  static const LinearGradient primaryButton = LinearGradient(
    colors: [AppColors.primaryStart, AppColors.primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiTwoTone = LinearGradient(
    colors: [AppColors.aiGradientStart, AppColors.aiGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient progressOngoing = LinearGradient(
    colors: [AppColors.progressOngoingStart, AppColors.progressOngoingEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient progressComplete = LinearGradient(
    colors: [AppColors.progressCompleteStart, AppColors.progressCompleteEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient sectionHeaderBar = LinearGradient(
    colors: [AppColors.primaryStart, AppColors.aiGradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Reusable Section Header with Blue -> Violet Gradient Left Accent Bar
class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final TextStyle? titleStyle;

  const AppSectionHeader({
    Key? key,
    required this.title,
    this.trailing,
    this.titleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppGradients.sectionHeaderBar,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: titleStyle ??
                TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Reusable Status Badge Component using Semantic Color System
class AppStatusBadge extends StatelessWidget {
  final String status; // 'completed', 'ongoing', 'upcoming', etc.
  final String? customLabel;

  const AppStatusBadge({
    Key? key,
    required this.status,
    this.customLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = status.trim().toLowerCase();

    Color bgColor;
    Color fgColor;

    if (normalized == 'completed' || normalized == 'done' || normalized == 'accepted') {
      bgColor = isDark ? AppColors.badgeCompletedBgDark : AppColors.badgeCompletedBgLight;
      fgColor = isDark ? AppColors.badgeCompletedFgDark : AppColors.badgeCompletedFgLight;
    } else if (normalized == 'ongoing' || normalized == 'active' || normalized == 'in_progress') {
      bgColor = isDark ? AppColors.badgeOngoingBgDark : AppColors.badgeOngoingBgLight;
      fgColor = isDark ? AppColors.badgeOngoingFgDark : AppColors.badgeOngoingFgLight;
    } else {
      // Upcoming or pending
      bgColor = isDark ? AppColors.badgeUpcomingBgDark : AppColors.badgeUpcomingBgLight;
      fgColor = isDark ? AppColors.badgeUpcomingFgDark : AppColors.badgeUpcomingFgLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        (customLabel ?? status).toUpperCase(),
        style: TextStyle(
          color: fgColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Reusable Gradient Progress Bar Widget
class AppGradientProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final bool isCompleted;
  final double height;

  const AppGradientProgressBar({
    Key? key,
    required this.value,
    this.isCompleted = false,
    this.height = 6.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedValue = value.clamp(0.0, 1.0);
    final isFullyComplete = isCompleted || clampedValue >= 1.0;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clampedValue,
        child: Container(
          decoration: BoxDecoration(
            gradient: isFullyComplete
                ? AppGradients.progressComplete
                : AppGradients.progressOngoing,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

/// Card Container with Lifted Shadow and Subtle Light Mode Border
class AppCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;

  const AppCardContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final boxDecoration = BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : AppColors.lightCardSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : AppColors.lightCardBorder,
        width: 1,
      ),
      boxShadow: isDark ? [] : [AppColors.cardShadowLight],
    );

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: boxDecoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// AI Smart Match Two-Tone Gradient Border Card Container
class AISmartMatchContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AISmartMatchContainer({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      decoration: BoxDecoration(
        gradient: AppGradients.aiTwoTone,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.aiGradientStart.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(2.0), // Gradient border width
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101827) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
