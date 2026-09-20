import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';
import 'package:omisu/services/gamepad/gamepad_navigation_manager.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/gamepad_nav.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

class EmbeddedSaveSlotInfo {
  const EmbeddedSaveSlotInfo({
    required this.hasSave,
    this.previewBytes,
  });

  final bool hasSave;
  final Uint8List? previewBytes;
}

class _PauseMenuEntry {
  const _PauseMenuEntry({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.isSectionHeader = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool isSectionHeader;
}

/// In-game pause overlay for embedded libretro play (OmiSU skin).
class EmbeddedPauseMenu extends StatefulWidget {
  const EmbeddedPauseMenu({
    super.key,
    required this.gameTitle,
    required this.muted,
    required this.fastForward,
    required this.touchControlsEnabled,
    required this.showFpsCounter,
    required this.hdMode,
    required this.slotInfo,
    required this.autosaveInfo,
    required this.onResume,
    required this.onSendStartButton,
    required this.onReset,
    required this.onToggleMute,
    required this.onToggleFastForward,
    required this.onToggleTouchControls,
    required this.onToggleFpsCounter,
    required this.onToggleHdMode,
    required this.onSaveSlot,
    required this.onLoadSlot,
    required this.onSaveAutosave,
    required this.onLoadAutosave,
    required this.onOpenGameOptions,
    required this.onExitToHome,
    this.showStreamingControls = false,
    this.isStreaming = false,
    this.onToggleStream,
  });

  final String gameTitle;
  final bool muted;
  final bool fastForward;
  final bool touchControlsEnabled;
  final bool showFpsCounter;
  final bool hdMode;
  final Map<int, EmbeddedSaveSlotInfo> slotInfo;
  final EmbeddedSaveSlotInfo autosaveInfo;
  final VoidCallback onResume;
  final VoidCallback onSendStartButton;
  final VoidCallback onReset;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleFastForward;
  final VoidCallback onToggleTouchControls;
  final VoidCallback onToggleFpsCounter;
  final VoidCallback onToggleHdMode;
  final ValueChanged<int> onSaveSlot;
  final ValueChanged<int> onLoadSlot;
  final VoidCallback onSaveAutosave;
  final VoidCallback onLoadAutosave;
  final VoidCallback onOpenGameOptions;
  final VoidCallback onExitToHome;
  final bool showStreamingControls;
  final bool isStreaming;
  final VoidCallback? onToggleStream;

  @override
  State<EmbeddedPauseMenu> createState() => _EmbeddedPauseMenuState();
}

class _EmbeddedPauseMenuState extends State<EmbeddedPauseMenu> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  late final GamepadNavigation _gamepadNav;

  GlobalKey _itemKey(int index) =>
      _itemKeys.putIfAbsent(index, () => GlobalKey());

  List<_PauseMenuEntry> _entries() {
    final entries = <_PauseMenuEntry>[
      _PauseMenuEntry(label: 'Resume', onPressed: widget.onResume, filled: true),
      _PauseMenuEntry(
        label: 'Start game',
        onPressed: widget.onSendStartButton,
      ),
      _PauseMenuEntry(label: 'Reset', onPressed: widget.onReset),
      _PauseMenuEntry(
        label: widget.muted ? 'Unmute' : 'Mute',
        onPressed: widget.onToggleMute,
      ),
      _PauseMenuEntry(
        label: widget.fastForward ? 'Normal speed' : 'Fast-forward',
        onPressed: widget.onToggleFastForward,
      ),
      _PauseMenuEntry(
        label: widget.touchControlsEnabled
            ? 'Hide touch controls'
            : 'Show touch controls',
        onPressed: widget.onToggleTouchControls,
      ),
      _PauseMenuEntry(
        label: widget.showFpsCounter ? 'Hide FPS counter' : 'Show FPS counter',
        onPressed: widget.onToggleFpsCounter,
      ),
      _PauseMenuEntry(
        label: widget.hdMode ? 'HD mode on' : 'HD mode off',
        onPressed: widget.onToggleHdMode,
      ),
    ];
    if (widget.showStreamingControls && widget.onToggleStream != null) {
      entries.add(
        _PauseMenuEntry(
          label: widget.isStreaming ? 'Stop stream' : 'Start stream',
          onPressed: widget.onToggleStream!,
          filled: widget.isStreaming,
        ),
      );
    }
    entries.add(
      _PauseMenuEntry(
        label: 'Game options',
        onPressed: widget.onOpenGameOptions,
      ),
    );
    entries.add(
      _PauseMenuEntry(
        label: 'Autosave',
        onPressed: () {},
        isSectionHeader: true,
      ),
    );
    entries.add(
      _PauseMenuEntry(
        label: widget.autosaveInfo.hasSave ? 'Save auto •' : 'Save auto',
        onPressed: widget.onSaveAutosave,
      ),
    );
    entries.add(
      _PauseMenuEntry(
        label: widget.autosaveInfo.hasSave ? 'Load auto •' : 'Load auto',
        onPressed: widget.onLoadAutosave,
      ),
    );
    entries.add(
      _PauseMenuEntry(
        label: 'Save state',
        onPressed: () {},
        isSectionHeader: true,
      ),
    );
    for (var slot = 1; slot <= 4; slot++) {
      final info =
          widget.slotInfo[slot] ?? const EmbeddedSaveSlotInfo(hasSave: false);
      entries.add(
        _PauseMenuEntry(
          label: 'Save slot $slot${info.hasSave ? ' •' : ''}',
          onPressed: () => widget.onSaveSlot(slot),
        ),
      );
    }
    entries.add(
      _PauseMenuEntry(
        label: 'Load state',
        onPressed: () {},
        isSectionHeader: true,
      ),
    );
    for (var slot = 1; slot <= 4; slot++) {
      final info =
          widget.slotInfo[slot] ?? const EmbeddedSaveSlotInfo(hasSave: false);
      entries.add(
        _PauseMenuEntry(
          label: 'Load slot $slot${info.hasSave ? ' •' : ''}',
          onPressed: () => widget.onLoadSlot(slot),
        ),
      );
    }
    entries.add(
      _PauseMenuEntry(
        label: 'Exit to home',
        onPressed: widget.onExitToHome,
        filled: true,
      ),
    );
    return entries;
  }

  List<_PauseMenuEntry> _focusableEntries(List<_PauseMenuEntry> all) =>
      all.where((e) => !e.isSectionHeader).toList();

  int _focusableIndexFor(int selectedIndex, List<_PauseMenuEntry> all) {
    var focusable = 0;
    for (var i = 0; i < all.length; i++) {
      if (all[i].isSectionHeader) continue;
      if (i == selectedIndex) return focusable;
      focusable++;
    }
    return 0;
  }

  int _entryIndexForFocusable(int focusableIndex, List<_PauseMenuEntry> all) {
    var seen = 0;
    for (var i = 0; i < all.length; i++) {
      if (all[i].isSectionHeader) continue;
      if (seen == focusableIndex) return i;
      seen++;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _gamepadNav = GamepadNavigation(
      onNavigateUp: _moveUp,
      onNavigateDown: _moveDown,
      onSelectItem: _onSelect,
      onBack: () {
        SfxService().playBackSound();
        widget.onResume();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await EmbeddedEmulatorService.setRouteGamepadToCore(false);
      _gamepadNav.initialize();
      GamepadNavigationManager.pushLayer(
        'embedded_pause_menu',
        modal: true,
        onActivate: () => _gamepadNav.activate(),
        onDeactivate: () => _gamepadNav.deactivate(),
      );
    });
  }

  @override
  void dispose() {
    GamepadNavigationManager.popLayer('embedded_pause_menu');
    _gamepadNav.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _moveUp() {
    final all = _entries();
    final focusable = _focusableEntries(all);
    if (focusable.isEmpty) return;
    final current = _focusableIndexFor(_selectedIndex, all);
    final next = (current - 1).clamp(0, focusable.length - 1);
    setState(() => _selectedIndex = _entryIndexForFocusable(next, all));
    SfxService().playNavSound();
    _scrollToSelected();
  }

  void _moveDown() {
    final all = _entries();
    final focusable = _focusableEntries(all);
    if (focusable.isEmpty) return;
    final current = _focusableIndexFor(_selectedIndex, all);
    final next = (current + 1).clamp(0, focusable.length - 1);
    setState(() => _selectedIndex = _entryIndexForFocusable(next, all));
    SfxService().playNavSound();
    _scrollToSelected();
  }

  void _onSelect() {
    final all = _entries();
    final entry = all[_selectedIndex];
    if (entry.isSectionHeader) return;
    SfxService().playEnterSound();
    entry.onPressed();
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[_selectedIndex];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.45,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _entries();

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480.r),
          child: OmisuRetroPanel(
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.gameTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 16.r),
                ),
                SizedBox(height: 12.r),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      if (entry.isSectionHeader) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8.r, bottom: 4.r),
                          child: Text(
                            entry.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }
                      final selected = index == _selectedIndex;
                      return Padding(
                        key: _itemKey(index),
                        padding: EdgeInsets.only(bottom: 6.r),
                        child: _MenuButton(
                          label: entry.label,
                          filled: entry.filled,
                          selected: selected,
                          onPressed: entry.onPressed,
                        ),
                      );
                    },
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


class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.onPressed,
    required this.selected,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.18)
        : Colors.transparent;

    if (filled) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.85),
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        onPressed: onPressed,
        child: Text(label),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: highlight,
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.5),
          width: selected ? 2 : 1,
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
