import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../profile/profile_screen.dart';
import '../report/report_form_screen.dart';
import '../reports/my_reports_screen.dart';
import '../reports/reports_screen.dart';
import 'home_screen.dart';

/// The student's main frame: 4 tabs + the blue "+" button.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  void _openTab(int index) => setState(() => _index = index);

  void _openReportForm() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenTab: _openTab, onReport: _openReportForm),
          const ReportsScreen(),
          MyReportsScreen(onReport: _openReportForm),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Report an issue',
        onPressed: _openReportForm,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 72,
        padding: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              selected: _index == 0,
              onTap: () => _openTab(0),
            ),
            _NavItem(
              icon: Icons.list_alt_outlined,
              activeIcon: Icons.list_alt_rounded,
              label: 'Reports',
              selected: _index == 1,
              onTap: () => _openTab(1),
            ),
            const SizedBox(width: 72),
            _NavItem(
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
              label: 'My reports',
              selected: _index == 2,
              onTap: () => _openTab(2),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              selected: _index == 3,
              onTap: () => _openTab(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
