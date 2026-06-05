import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_colors.dart';

class BottomNav extends StatelessWidget {
  final String currentTab;
  final void Function(String tab) onChange;

  const BottomNav({
    super.key,
    required this.currentTab,
    required this.onChange,
  });

  static const _tabs = [
    _NavTab(id: 'beranda', label: 'Beranda', icon: Icons.home_rounded),
    _NavTab(id: 'kendali', label: 'Kendali', icon: Icons.tune_rounded),
    _NavTab(id: 'aturan', label: 'Aturan', icon: Icons.auto_mode_rounded),
    _NavTab(id: 'riwayat', label: 'Riwayat', icon: Icons.history_rounded),
    _NavTab(id: 'profil', label: 'Profil', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(isDark),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.map((tab) {
              final isActive = currentTab == tab.id;
              return _NavButton(
                tab: tab,
                isActive: isActive,
                onTap: () => onChange(tab.id),
                isDark: isDark,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final String id;
  final String label;
  final IconData icon;

  const _NavTab({required this.id, required this.label, required this.icon});
}

class _NavButton extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _NavButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding:
            EdgeInsets.symmetric(horizontal: isActive ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? AppColors.primaryLight.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 24,
              color: isActive
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : AppColors.textHint(isDark),
            ),
            // Only show the label if this tab is active
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
