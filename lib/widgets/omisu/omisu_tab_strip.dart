import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:omisu/providers/sqlite_config_provider.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/themes/omisu_accent.dart';
import 'package:omisu/utils/header_layout.dart';
import 'package:omisu/utils/nav_tabs.dart';
import 'package:omisu/widgets/bumper_glyph.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

export 'package:omisu/widgets/omisu/omisu_shell_layout.dart';

/// Synthwave HUD tab strip — neon slots with a sliding gradient underline.
class OmisuTabStrip extends StatefulWidget {
  const OmisuTabStrip({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.maxWidth,
    this.statusPillWidth = 0,
    this.showBumpers = true,
    this.compact = false,
  });

  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final double maxWidth;
  final double statusPillWidth;
  final bool showBumpers;
  final bool compact;

  @override
  State<OmisuTabStrip> createState() => _OmisuTabStripState();
}

class _OmisuTabStripState extends State<OmisuTabStrip> {
  int _windowStart = 0;
  late final List<FocusNode> _tabFocusNodes;

  static const _slotSize = 34.0;
  static const _compactSlotSize = 28.0;
  static const _underlineHeight = 3.0;
  static const _compactUnderlineHeight = 2.0;

  double get _effectiveSlotSize =>
      widget.compact ? _compactSlotSize : _slotSize;

  double get _effectiveUnderlineHeight =>
      widget.compact ? _compactUnderlineHeight : _underlineHeight;

  double get _underlineGap => widget.compact ? 2.0 : 4.0;

  EdgeInsets get _panelPadding => widget.compact
      ? EdgeInsets.symmetric(horizontal: 3.r, vertical: 2.r)
      : EdgeInsets.symmetric(horizontal: 4.r, vertical: 3.r);

  @override
  void initState() {
    super.initState();
    _tabFocusNodes = List.generate(
      NavTab.values.length,
      (_) => FocusNode(skipTraversal: true),
    );
  }

  @override
  void dispose() {
    for (final node in _tabFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SqliteConfigProvider>(
      builder: (context, configProvider, _) {
        final visibleTabs = visibleNavTabs(configProvider.config);
        final maxSlots = navStripMaxSlots(
          totalWidth: widget.maxWidth,
          statusPillWidth: widget.statusPillWidth,
          slot: _effectiveSlotSize.r,
          shoulder: widget.showBumpers ? 32.r : 36.r,
          pillPadding: 4.r,
          margin: 8.r,
          gutter: 4.r,
          minSlots: minNavTabSlots,
        );

        final selectedSlot = visibleTabs.indexOf(
          NavTab.values[widget.selectedTabIndex],
        );

        final stripBody = SizedBox(
          height: _effectiveSlotSize.r,
          child: Builder(
            builder: (context) {
              final strip = TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  end: (selectedSlot < 0 ? 0 : selectedSlot).toDouble(),
                ),
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeInOutCubic,
                builder: (context, slot, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (index, tab) in visibleTabs.indexed)
                        SizedBox(
                          width: _effectiveSlotSize.r,
                          height: _effectiveSlotSize.r,
                          child: _buildTabButton(
                            context,
                            tab.index,
                            navTabSpec(tab).icon,
                            iconData: navTabSpec(tab).iconData,
                            accent:
                                navTabSpec(tab).accentColor ??
                                Theme.of(context).colorScheme.secondary,
                            coverage: (1.0 - (slot - index).abs()).clamp(
                              0.0,
                              1.0,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );

              if (visibleTabs.length <= maxSlots) {
                _windowStart = 0;
                return strip;
              }

              return _buildScrollingStrip(
                strip,
                visibleTabs.length,
                selectedSlot,
                maxSlots,
              );
            },
          ),
        );

        final dock = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OmisuRetroPanel(
              cornerRadius: 4,
              padding: _panelPadding,
              child: stripBody,
            ),
            SizedBox(height: _underlineGap.r),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                end: (selectedSlot < 0 ? 0 : selectedSlot).toDouble(),
              ),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeInOutCubic,
              builder: (context, slot, _) {
                final tabCount = visibleTabs.length <= maxSlots
                    ? visibleTabs.length
                    : maxSlots;
                final panelWidth =
                    tabCount * _effectiveSlotSize.r +
                    (widget.compact ? 6.r : 8.r);
                final barLeft =
                    (widget.compact ? 3.r : 4.r) + slot * _effectiveSlotSize.r;
                return SizedBox(
                  width: panelWidth,
                  height: _effectiveUnderlineHeight.r,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: barLeft,
                        width: _effectiveSlotSize.r,
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: OmisuAccent.focusRingGradient,
                            borderRadius: BorderRadius.circular(2.r),
                            boxShadow: [
                              BoxShadow(
                                color: OmisuAccent.brandGreen.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 4.r,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );

        if (!widget.showBumpers) return dock;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BumperGlyph(isLeft: true, size: 22.r),
            dock,
            BumperGlyph(isLeft: false, size: 22.r),
          ],
        );
      },
    );
  }

  Widget _buildScrollingStrip(
    Widget strip,
    int tabCount,
    int selectedSlot,
    int maxSlots,
  ) {
    _windowStart = navTabWindowStart(
      windowStart: _windowStart,
      selectedSlot: selectedSlot,
      tabCount: tabCount,
      maxSlots: maxSlots,
    );

    final viewportWidth = maxSlots * _effectiveSlotSize.r;
    final canScrollLeft = _windowStart > 0;
    final canScrollRight = _windowStart < tabCount - maxSlots;
    final fade = 12.r / viewportWidth;

    return SizedBox(
      width: viewportWidth,
      height: _effectiveSlotSize.r,
      child: ClipRect(
        child: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: [
              canScrollLeft ? Colors.transparent : Colors.white,
              Colors.white,
              Colors.white,
              canScrollRight ? Colors.transparent : Colors.white,
            ],
            stops: [0, fade, 1 - fade, 1],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeInOutCubic,
                left: -_windowStart * _effectiveSlotSize.r,
                top: 0,
                bottom: 0,
                width: tabCount * _effectiveSlotSize.r,
                child: strip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    int tabIndex,
    String? icon, {
    IconData? iconData,
    required Color accent,
    required double coverage,
  }) {
    final theme = Theme.of(context);
    final selected = coverage > 0.72;
    final iconTint = selected
        ? accent
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        canRequestFocus: false,
        focusNode: _tabFocusNodes[tabIndex],
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: () {
          SfxService().playNavSound();
          widget.onTabSelected(tabIndex);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: EdgeInsets.all(2.r),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.22),
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.65),
                    ],
                  )
                : null,
            color: selected
                ? null
                : theme.colorScheme.surface.withValues(alpha: 0.35),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.85)
                  : OmisuAccent.focusGradient[2].withValues(alpha: 0.28),
              width: selected ? 1.5.r : 1.r,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 10.r,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (selected)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 2.r,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          OmisuAccent.focusGradient.last.withValues(
                            alpha: 0.85,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Center(
                child: iconData != null
                    ? Icon(iconData, size: 16.r, color: iconTint)
                    : _tabIcon(icon!, iconTint, selected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabIcon(String icon, Color tint, bool selected) {
    final size = selected ? 17.0 : 15.0;
    if (icon.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        icon,
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        fit: BoxFit.contain,
        width: size,
        height: size,
      );
    }
    return Image.asset(icon, color: tint, width: size, height: size);
  }
}
