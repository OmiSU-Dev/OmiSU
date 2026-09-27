import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/gamepad/gamepad_navigation_manager.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/gamepad_nav.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Stream options sheet (OmisuRetroPanel) before launching an external Android game.
class ExternalStreamOverlayMenu extends StatefulWidget {
  const ExternalStreamOverlayMenu({
    super.key,
    required this.gameTitle,
    this.preLaunch = true,
    required this.gameAudioEnabled,
    required this.includeMicrophone,
    required this.faceCamEnabled,
    required this.onToggleGameAudio,
    required this.onToggleIncludeMic,
    required this.onToggleFaceCam,
    this.streamOnLaunch = false,
    this.streamConfigured = true,
    this.onToggleStreamOnLaunch,
    this.onLaunch,
    this.onCancel,
  });

  final String gameTitle;
  final bool preLaunch;
  final bool streamOnLaunch;
  final bool streamConfigured;
  final bool gameAudioEnabled;
  final bool includeMicrophone;
  final bool faceCamEnabled;
  final VoidCallback? onLaunch;
  final VoidCallback? onCancel;
  final VoidCallback? onToggleStreamOnLaunch;
  final VoidCallback onToggleGameAudio;
  final VoidCallback onToggleIncludeMic;
  final VoidCallback onToggleFaceCam;

  @override
  State<ExternalStreamOverlayMenu> createState() =>
      _ExternalStreamOverlayMenuState();
}

class _ExternalStreamOverlayMenuState extends State<ExternalStreamOverlayMenu> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  late final GamepadNavigation _gamepadNav;

  static const _layerId = 'external_play_stream_overlay';

  GlobalKey _itemKey(int index) =>
      _itemKeys.putIfAbsent(index, () => GlobalKey());

  List<_Entry> _entries(BuildContext context) {
    final launchLabel =
        '${AppLocale.launch.getString(context)} ${AppLocale.play.getString(context).toLowerCase()}';
    return [
      _Entry(
        label: launchLabel,
        onPressed: widget.onLaunch,
        filled: true,
      ),
      _Entry(label: AppLocale.streaming.getString(context), isSection: true),
      _Entry(
        label: widget.streamOnLaunch
            ? '${AppLocale.streamingStreamOnLaunch.getString(context)}: on'
            : '${AppLocale.streamingStreamOnLaunch.getString(context)}: off',
        onPressed: widget.streamConfigured ? widget.onToggleStreamOnLaunch : null,
        enabled: widget.streamConfigured,
      ),
      _Entry(
        label: widget.gameAudioEnabled
            ? '${AppLocale.streamingGameAudio.getString(context)}: on'
            : '${AppLocale.streamingGameAudio.getString(context)}: off',
        onPressed: widget.onToggleGameAudio,
      ),
      _Entry(
        label: widget.includeMicrophone
            ? '${AppLocale.streamingIncludeMic.getString(context)}: on'
            : '${AppLocale.streamingIncludeMic.getString(context)}: off',
        onPressed: widget.onToggleIncludeMic,
      ),
      _Entry(
        label: widget.faceCamEnabled
            ? '${AppLocale.streamingFaceCam.getString(context)}: on'
            : '${AppLocale.streamingFaceCam.getString(context)}: off',
        onPressed: widget.onToggleFaceCam,
      ),
    ];
  }

  List<_Entry> _focusable(List<_Entry> all) =>
      all.where((e) => !e.isSection && e.onPressed != null).toList();

  @override
  void initState() {
    super.initState();
    _gamepadNav = GamepadNavigation(
      onNavigateUp: _moveUp,
      onNavigateDown: _moveDown,
      onSelectItem: _onSelect,
      onBack: () {
        SfxService().playBackSound();
        widget.onCancel?.call();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _gamepadNav.initialize();
      GamepadNavigationManager.pushLayer(
        _layerId,
        modal: true,
        onActivate: () => _gamepadNav.activate(),
        onDeactivate: () => _gamepadNav.deactivate(),
      );
    });
  }

  @override
  void dispose() {
    GamepadNavigationManager.popLayer(_layerId);
    _gamepadNav.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _moveUp() => _move(-1);
  void _moveDown() => _move(1);

  void _move(int delta) {
    final all = _entries(context);
    final focusable = _focusable(all);
    if (focusable.isEmpty) return;
    var idx = _focusableIndex(all);
    idx = (idx + delta).clamp(0, focusable.length - 1);
    setState(() => _selectedIndex = _entryIndex(all, idx));
    SfxService().playNavSound();
    _scrollToSelected();
  }

  int _focusableIndex(List<_Entry> all) {
    var seen = 0;
    for (var i = 0; i < all.length; i++) {
      if (all[i].isSection || all[i].onPressed == null) continue;
      if (i == _selectedIndex) return seen;
      seen++;
    }
    return 0;
  }

  int _entryIndex(List<_Entry> all, int focusableIndex) {
    var seen = 0;
    for (var i = 0; i < all.length; i++) {
      if (all[i].isSection || all[i].onPressed == null) continue;
      if (seen == focusableIndex) return i;
      seen++;
    }
    return 0;
  }

  void _onSelect() {
    final all = _entries(context);
    final entry = all[_selectedIndex];
    if (entry.isSection || entry.onPressed == null) return;
    SfxService().playEnterSound();
    entry.onPressed!.call();
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
    final entries = _entries(context);

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
                if (!widget.streamConfigured) ...[
                  SizedBox(height: 8.r),
                  Text(
                    AppLocale.streamingSetupRequired.getString(context),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ] else if (widget.streamOnLaunch) ...[
                  SizedBox(height: 8.r),
                  Text(
                    AppLocale.streamingExternalCaptureHint.getString(context),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
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
                      if (entry.isSection) {
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
                      final disabled = entry.onPressed == null;
                      return Padding(
                        key: _itemKey(index),
                        padding: EdgeInsets.only(bottom: 6.r),
                        child: _OverlayMenuButton(
                          label: entry.label,
                          filled: entry.filled,
                          selected: selected,
                          disabled: disabled,
                          onPressed: entry.onPressed ?? () {},
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

class _Entry {
  _Entry({
    required this.label,
    this.onPressed,
    this.filled = false,
    this.isSection = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool isSection;
  final bool enabled;
}

class _OverlayMenuButton extends StatelessWidget {
  const _OverlayMenuButton({
    required this.label,
    required this.onPressed,
    required this.selected,
    this.filled = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final bool filled;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (filled) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.85),
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        onPressed: disabled ? null : onPressed,
        child: Text(label),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      onPressed: disabled ? null : onPressed,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: disabled
              ? theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                )
              : null,
        ),
      ),
    );
  }
}
