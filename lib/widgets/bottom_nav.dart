import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final String currentTab;
  final void Function(String tab) onChange;

  const BottomNav({
    super.key,
    required this.currentTab,
    required this.onChange,
  });

  static const _tabs = [
    _NavTab(id: 'beranda', label: 'BERANDA', icon: Icons.home_rounded),
    _NavTab(id: 'kendali', label: 'KENDALI', icon: Icons.settings_rounded),
    _NavTab(id: 'aturan', label: 'ATURAN', icon: Icons.tune_rounded),
    _NavTab(id: 'riwayat', label: 'RIWAYAT', icon: Icons.access_time_rounded),
    _NavTab(id: 'profil', label: 'PROFIL', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.map((tab) {
              final isActive = currentTab == tab.id;
              return _NavButton(
                tab: tab,
                isActive: isActive,
                onTap: () => onChange(tab.id),
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

  const _NavButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 32,
                height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 7),
            Icon(
              tab.icon,
              size: 24,
              color: isActive ? const Color(0xFF059669) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isActive ? const Color(0xFF047857) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
