import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/services/embedded/embedded_core_option_allowlist.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';
import 'package:omisu/services/gamepad/gamepad_navigation_manager.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/gamepad_nav.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Per-core libretro options exposed during embedded play.
class EmbeddedCoreOptionsSheet extends StatefulWidget {
  const EmbeddedCoreOptionsSheet({
    super.key,
    required this.systemFolder,
  });

  final String systemFolder;

  static Future<void> show(
    BuildContext context, {
    required String systemFolder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EmbeddedCoreOptionsSheet(systemFolder: systemFolder),
    );
  }

  @override
  State<EmbeddedCoreOptionsSheet> createState() =>
      _EmbeddedCoreOptionsSheetState();
}

class _EmbeddedCoreOptionsSheetState extends State<EmbeddedCoreOptionsSheet> {
  List<EmbeddedCoreVariable> _variables = const [];
  bool _loading = true;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  late final GamepadNavigation _gamepadNav;

  GlobalKey _itemKey(int index) =>
      _itemKeys.putIfAbsent(index, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    _gamepadNav = GamepadNavigation(
      onNavigateUp: _moveUp,
      onNavigateDown: _moveDown,
      onSelectItem: _onSelect,
      onBack: () {
        SfxService().playBackSound();
        Navigator.of(context).pop();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _gamepadNav.initialize();
      GamepadNavigationManager.pushLayer(
        'embedded_core_options',
        modal: true,
        onActivate: () => _gamepadNav.activate(),
        onDeactivate: () => _gamepadNav.deactivate(),
      );
    });
    _load();
  }

  @override
  void dispose() {
    GamepadNavigationManager.popLayer('embedded_core_options');
    _gamepadNav.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _moveUp() {
    if (_variables.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex - 1).clamp(0, _variables.length - 1);
    });
    SfxService().playNavSound();
    _scrollToSelected();
  }

  void _moveDown() {
    if (_variables.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1).clamp(0, _variables.length - 1);
    });
    SfxService().playNavSound();
    _scrollToSelected();
  }

  void _onSelect() {
    if (_variables.isEmpty) return;
    SfxService().playEnterSound();
    unawaited(_cycle(_variables[_selectedIndex]));
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

  Future<void> _load() async {
    final vars = await EmbeddedEmulatorService.getCoreVariables();
    final safe = filterUserFacingCoreOptions(
      systemFolder: widget.systemFolder,
      variables: vars,
    );
    if (mounted) {
      setState(() {
        _variables = safe;
        _loading = false;
        _selectedIndex = 0;
      });
    }
  }

  Future<void> _cycle(EmbeddedCoreVariable variable) async {
    final options = variable.selectableValues;
    if (options.length < 2) return;
    final current = variable.value ?? options.first;
    final index = options.indexOf(current);
    final next = options[(index + 1) % options.length];
    final ok = await EmbeddedEmulatorService.updateCoreVariable(
      key: variable.key,
      value: next,
    );
    if (!mounted) return;
    if (ok) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update option')),
      );
    }
  }

  Widget _buildOptionRow({
    required BuildContext context,
    required EmbeddedCoreVariable variable,
    required bool selected,
    required int index,
  }) {
    final theme = Theme.of(context);
    final options = variable.selectableValues;
    final canCycle = options.length > 1;
    final presentation = variable.presentation;
    final hint = presentation.hint;

    return Material(
      key: _itemKey(index),
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        onTap: canCycle ? () => _cycle(variable) : null,
        borderRadius: BorderRadius.circular(6.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.r, horizontal: 4.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11.r,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.r),
                    Text(
                      presentation.currentValue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hint != null) ...[
                      SizedBox(height: 2.r),
                      Text(
                        hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          fontSize: 10.r,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canCycle) ...[
                SizedBox(width: 8.r),
                Padding(
                  padding: EdgeInsets.only(top: 2.r),
                  child: Icon(Icons.sync_rounded, size: 18.r),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.65;

    return Padding(
      padding: EdgeInsets.only(
        left: 12.r,
        right: 12.r,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 12.r,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: OmisuRetroPanel(
          padding: EdgeInsets.all(12.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Game options',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.r),
              ),
              SizedBox(height: 8.r),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_variables.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.r),
                  child: Text(
                    'No core options for this game.',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: _variables.length,
                    separatorBuilder: (_, __) => Divider(height: 8.r),
                    itemBuilder: (context, index) {
                      return _buildOptionRow(
                        context: context,
                        variable: _variables[index],
                        selected: index == _selectedIndex,
                        index: index,
                      );
                    },
                  ),
                ),
              SizedBox(height: 8.r),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
