import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import 'staff_dashboard_screen.dart';

/// The staff member's main frame: Dashboard, All reports, Profile.
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  void _openTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          StaffDashboardScreen(onOpenTab: _openTab),
          const ReportsScreen(title: 'All reports'),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Material(
        color: scheme.surface,
        child: SafeArea(
          top: false,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outline)),
            ),
            child: Row(
              children: [
                _StaffNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  selected: _index == 0,
                  onTap: () => _openTab(0),
                ),
                _StaffNavItem(
                  icon: Icons.list_alt_outlined,
                  activeIcon: Icons.list_alt_rounded,
                  label: 'All reports',
                  selected: _index == 1,
                  onTap: () => _openTab(1),
                ),
                _StaffNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  selected: _index == 2,
                  onTap: () => _openTab(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffNavItem extends StatelessWidget {
  const _StaffNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
