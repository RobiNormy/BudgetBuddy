import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidGlassNavBarItem {
  const LiquidGlassNavBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class LiquidGlassNavBar extends StatelessWidget {
  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<LiquidGlassNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withValues(
      alpha: isDark ? 0.72 : 0.55,
    );
    final glassColor = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.24);
    final outerBorderColor = isDark
        ? Colors.transparent
        : colorScheme.outlineVariant.withValues(alpha: 0.5);
    final indicatorBorderColor = isDark
        ? activeColor.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.75);
    final indicatorGlowColor = isDark
        ? activeColor.withValues(alpha: 0.22)
        : activeColor.withValues(alpha: 0.18);
    final highlightColor = isDark
        ? colorScheme.surface.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.92);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: -6,
                  ),
                ],
              ),
            ),
          ),
          LiquidGlass.withOwnLayer(
            shape: const LiquidRoundedRectangle(borderRadius: 40),
            settings: LiquidGlassSettings(
              ambientStrength: 0.0,
              thickness: 0.0,
              refractiveIndex: 1.0,
              lightIntensity: 0.0,
              blur: 0.0,
              glassColor: glassColor,
            ),
            child: Container(
              height: 80,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: outerBorderColor,
                  width: outerBorderColor == Colors.transparent ? 0 : 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / items.length;
                  const indicatorHorizontalInset = 6.0;
                  const indicatorHeight = 50.0;
                  final indicatorWidth =
                      itemWidth - (indicatorHorizontalInset * 2);
                  final indicatorTop =
                      (constraints.maxHeight - indicatorHeight) / 2;
                  final indicatorLeft =
                      (currentIndex * itemWidth) + indicatorHorizontalInset;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutQuad,
                        left: indicatorLeft,
                        top: indicatorTop,
                        child: Container(
                          width: indicatorWidth,
                          height: indicatorHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                activeColor.withValues(
                                  alpha: isDark ? 0.16 : 0.12,
                                ),
                                highlightColor,
                                Colors.white.withValues(
                                  alpha: isDark ? 0.04 : 0.18,
                                ),
                              ],
                              stops: const [0.0, 0.42, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: indicatorBorderColor,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: indicatorGlowColor,
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: indicatorWidth,
                                  child: _NavBarItem(
                                    item: items[i],
                                    isSelected: currentIndex == i,
                                    activeColor: activeColor,
                                    inactiveColor: inactiveColor,
                                    onTap: () => onTap(i),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final LiquidGlassNavBarItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.12 : 1,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    item.icon,
                    key: ValueKey<bool>(isSelected),
                    size: 24,
                    color: foregroundColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutQuad,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: foregroundColor,
                  height: 1.2,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
