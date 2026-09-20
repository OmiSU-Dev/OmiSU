import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/builtin_player_update_service.dart';
import 'package:omisu/services/game_service.dart';
import 'package:omisu/utils/gamepad_nav.dart';
import 'package:omisu/widgets/core_footer.dart';
import 'package:omisu/widgets/update_changelog_panel.dart';

/// Confirms built-in player OTA (engine + cores) after showing version bumps.
class BuiltinPlayerUpdateDialog extends StatefulWidget {
  final BuiltinPlayerUpdatePreview preview;

  const BuiltinPlayerUpdateDialog({super.key, required this.preview});

  @override
  State<BuiltinPlayerUpdateDialog> createState() =>
      _BuiltinPlayerUpdateDialogState();
}

class _BuiltinPlayerUpdateDialogState extends State<BuiltinPlayerUpdateDialog> {
  late final GamepadNavigation _gamepadNav;

  @override
  void initState() {
    super.initState();
    _gamepadNav = GamepadNavigation(
      onSelectItem: () => Navigator.of(context).pop(true),
      onBack: _closeDialog,
    );
    _gamepadNav.initialize();
    _gamepadNav.activate();
    GamepadNavigationManager.pushLayer(
      'builtin_player_update_dialog',
      onActivate: () => _gamepadNav.activate(),
      onDeactivate: () => _gamepadNav.deactivate(),
      modal: true,
    );
  }

  @override
  void dispose() {
    GamepadNavigationManager.popLayer('builtin_player_update_dialog');
    _gamepadNav.dispose();
    super.dispose();
  }

  void _closeDialog() {
    GamepadNavigationManager.popLayer('builtin_player_update_dialog');
    _gamepadNav.dispose();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = widget.preview;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.r, sigmaY: 5.r),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 420.r,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.r,
                    horizontal: 16.r,
                  ),
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.sports_esports_rounded,
                        color: theme.colorScheme.primary,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.r),
                      Expanded(
                        child: Text(
                          AppLocale.builtinPlayerUpdateAvailable.getString(
                            context,
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (preview.engineUpdateAvailable) ...[
                          _versionLine(
                            context,
                            AppLocale.builtinPlayerEngineLabel.getString(
                              context,
                            ),
                            preview.bundledLibretroDroidVersion,
                            preview.remoteLibretroDroidVersion ?? '—',
                          ),
                          SizedBox(height: 6.r),
                        ],
                        if (preview.coresUpdateAvailable) ...[
                          _versionLine(
                            context,
                            AppLocale.builtinPlayerCoresLabel.getString(
                              context,
                            ),
                            preview.localCoresVersion,
                            preview.remoteCoresTag ?? '—',
                          ),
                          SizedBox(height: 10.r),
                        ],
                        UpdateChangelogPanel(
                          releaseNotes: preview.releaseNotes,
                          maxHeight: 120,
                        ),
                        SizedBox(height: 12.r),
                        Row(
                          children: [
                            Expanded(
                              child: GamepadControl(
                                iconPath:
                                    'assets/images/gamepad/Xbox_B_button.png',
                                label: AppLocale.updateLater.getString(context),
                                onTap: () => Navigator.of(context).pop(false),
                                backgroundColor: theme.colorScheme.tertiary,
                                textColor: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 8.r),
                            Expanded(
                              flex: 2,
                              child: GamepadControl(
                                iconPath:
                                    'assets/images/gamepad/Xbox_A_button.png',
                                label: AppLocale.updateNow.getString(context),
                                onTap: () => Navigator.of(context).pop(true),
                                backgroundColor: theme.colorScheme.primary,
                                textColor: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _versionLine(
    BuildContext context,
    String label,
    String from,
    String to,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Symbols.arrow_forward_rounded,
          size: 12.r,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: 6.r),
        Expanded(
          child: Text(
            AppLocale.builtinPlayerVersionBump
                .getString(context)
                .replaceFirst('{label}', label)
                .replaceFirst('{from}', from)
                .replaceFirst('{to}', to),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
