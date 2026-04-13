import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtelierListGroup extends StatelessWidget {
  final List<Widget> children;
  final String? label;

  const AtelierListGroup({
    super.key,
    required this.children,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              label!.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class AtelierListTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? customLeading;
  final String title;
  final Widget? customTitle;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const AtelierListTile({
    super.key,
    this.icon,
    this.iconColor,
    this.customLeading,
    this.title = '',
    this.customTitle,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildLeading() {
      if (customLeading != null) return customLeading!;
      if (icon != null && iconColor != null) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor!.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        );
      }
      return const SizedBox.shrink();
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: buildLeading(),
      title: customTitle ?? Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class AtelierSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AtelierSwitchTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AtelierListTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: iconColor,
        activeThumbColor: Colors.white,
      ),
    );
  }
}
