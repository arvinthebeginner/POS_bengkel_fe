import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'neumorphic.dart';

enum AppTab { beranda, kasir, stok, riwayat }

/// Shared bottom navigation bar across Dashboard/Kasir/Stok/Riwayat —
/// a floating raised neumorphic pill with a red pressed-in active tab.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTap,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: NeumorphicBox(
        borderRadius: 28,
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              isActive: currentTab == AppTab.beranda,
              onTap: () => onTap(AppTab.beranda),
            ),
            _NavItem(
              icon: Icons.point_of_sale_rounded,
              label: 'Kasir',
              isActive: currentTab == AppTab.kasir,
              onTap: () => onTap(AppTab.kasir),
            ),
            _NavItem(
              icon: Icons.inventory_2_rounded,
              label: 'Stok',
              isActive: currentTab == AppTab.stok,
              onTap: () => onTap(AppTab.stok),
            ),
            _NavItem(
              icon: Icons.history_rounded,
              label: 'Riwayat',
              isActive: currentTab == AppTab.riwayat,
              onTap: () => onTap(AppTab.riwayat),
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
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : AppColors.secondary,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: isActive ? null : onTap,
        child: isActive
            // Slightly smaller than its neighbours, so the active tab reads as
            // pushed down into the pill rather than merely tinted red. A plain
            // Transform rather than an AnimatedScale because tab switching goes
            // through pushReplacement (see handleAppTabTap), which rebuilds the
            // whole bar — there is never an old value to animate from.
            ? Transform.scale(
                scale: 0.96,
                child: NeumorphicInset(
                  borderRadius: 24,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDim, AppColors.primaryContainer],
                  ),
                  shadows: const [
                    BoxShadow(
                      color: AppColors.primaryInset,
                      offset: Offset(4, 4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Color(0x33FFFFFF),
                      offset: Offset(-4, -4),
                      blurRadius: 6,
                    ),
                  ],
                  child: content,
                ),
              )
            : content,
      ),
    );
  }
}

/// Navigates the bottom nav the same way across every screen: replace the
/// current screen with the target tab so the stack always reflects exactly
/// one "current tab" instead of growing with every tap.
void handleAppTabTap(
  BuildContext context,
  AppTab tapped, {
  required AppTab current,
  required WidgetBuilder dashboard,
  required WidgetBuilder kasir,
  required WidgetBuilder stok,
  required WidgetBuilder riwayat,
}) {
  if (tapped == current) return;

  final builder = switch (tapped) {
    AppTab.beranda => dashboard,
    AppTab.kasir => kasir,
    AppTab.stok => stok,
    AppTab.riwayat => riwayat,
  };

  Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: builder));
}
