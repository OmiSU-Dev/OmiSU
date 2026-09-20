import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/models/game_model.dart';
import 'package:omisu/models/system_model.dart';
import 'package:omisu/screens/game_screen/game_settings_dialog/game_settings_play_tab.dart';
import 'package:omisu/services/gamepad/gamepad_navigation_manager.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/gamepad_nav.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Saved per-game tweaks and cheats during embedded play (library Play tab).
class EmbeddedPlaySettingsSheet extends StatefulWidget {
  const EmbeddedPlaySettingsSheet({
    super.key,
    required this.game,
    required this.system,
  });

  final GameModel game;
  final SystemModel system;

  static Future<void> show(
    BuildContext context, {
    required GameModel game,
    required SystemModel system,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) => EmbeddedPlaySettingsSheet(
        game: game,
        system: system,
      ),
    );
  }

  @override
  State<EmbeddedPlaySettingsSheet> createState() =>
      _EmbeddedPlaySettingsSheetState();
}

class _EmbeddedPlaySettingsSheetState extends State<EmbeddedPlaySettingsSheet> {
  final _playTabKey = GlobalKey<GameSettingsPlayTabState>();
  late final GamepadNavigation _gamepadNav;

  @override
  void initState() {
    super.initState();
    _gamepadNav = GamepadNavigation(
      onNavigateUp: () => _playTabKey.currentState?.moveUp(),
      onNavigateDown: () => _playTabKey.currentState?.moveDown(),
      onSelectItem: () => _playTabKey.currentState?.trigger(),
      onBack: () {
        SfxService().playBackSound();
        Navigator.of(context).pop();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _gamepadNav.initialize();
      GamepadNavigationManager.pushLayer(
        'embedded_play_settings',
        modal: true,
        onActivate: () => _gamepadNav.activate(),
        onDeactivate: () => _gamepadNav.deactivate(),
      );
      _playTabKey.currentState?.scrollFocusedItemIntoView();
    });
  }

  @override
  void dispose() {
    GamepadNavigationManager.popLayer('embedded_play_settings');
    _gamepadNav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(top: 24.r),
      child: OmisuRetroPanel(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.r, 12.r, 8.r, 8.r),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocale.gameSettingsPlayCheats.getString(context),
                        style: TextStyle(
                          fontSize: 14.r,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'More',
                      onPressed: () =>
                          _playTabKey.currentState?.showManualCheatActionsMenu(),
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                    IconButton(
                      onPressed: () {
                        SfxService().playBackSound();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GameSettingsPlayTab(
                  key: _playTabKey,
                  game: widget.game,
                  system: widget.system,
                  isAllMode: false,
                  cheatsOnly: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
