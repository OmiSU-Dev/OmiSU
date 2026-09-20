import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/models/gamepad_shoulder_style.dart';
import 'package:omisu/providers/sqlite_config_provider.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/adaptive_scroll.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';
import 'package:provider/provider.dart';

import 'settings_title.dart';
import 'widgets/setting_row.dart';

class InputSettingsContent extends StatefulWidget {
  final bool isContentFocused;
  final int selectedContentIndex;

  const InputSettingsContent({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
  });

  @override
  State<InputSettingsContent> createState() => InputSettingsContentState();
}

class InputSettingsContentState extends State<InputSettingsContent> {
  final ScrollController _scrollController = ScrollController();
  final AdaptiveScroller _scroller = AdaptiveScroller();
  final List<GlobalKey> _itemKeys = List.generate(2, (_) => GlobalKey());

  int getItemCount() => 2;

  void scrollToIndex(int index) {
    _scroller.ensureVisibleIndex(
      index,
      keys: _itemKeys,
      controller: _scrollController,
    );
  }

  void selectItem(int index) {
    if (index == 0) {
      final provider = context.read<SqliteConfigProvider>();
      SfxService().playNavSound();
      provider.updateGamepadShoulderStyle(
        provider.config.gamepadShoulderStyle.next,
      );
      return;
    }
    if (index != 1) return;
    SfxService().playNavSound();
  }

  String _shoulderStyleLabel(
    BuildContext context,
    GamepadShoulderStyle style,
  ) {
    return switch (style) {
      GamepadShoulderStyle.bumpers =>
        AppLocale.inputShoulderStyleBumpers.getString(context),
      GamepadShoulderStyle.triggers =>
        AppLocale.inputShoulderStyleTriggers.getString(context),
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsTitle(
          title: AppLocale.input.getString(context),
          subtitle: AppLocale.inputSubtitle.getString(context),
        ),
        SizedBox(height: 12.r),
        OmisuRetroPanel(
          padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Symbols.sports_esports_rounded,
                size: 16.r,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 8.r),
              Expanded(
                child: Text(
                  AppLocale.sfxSoundsSubtitle.getString(context),
                  style: omisuRetroLabelStyle(
                    context,
                    size: 9,
                    weight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.r),
        Expanded(
          child: Consumer<SqliteConfigProvider>(
            builder: (context, provider, _) {
              return SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 24.r),
                child: Column(
                  children: [
                    SettingRow(
                      key: _itemKeys[0],
                      onTap: () => selectItem(0),
                      focused:
                          widget.isContentFocused &&
                          widget.selectedContentIndex == 0,
                      title: AppLocale.inputShoulderStyle.getString(context),
                      subtitle: AppLocale.inputShoulderStyleSubtitle.getString(
                        context,
                      ),
                      trailing: Text(
                        _shoulderStyleLabel(
                          context,
                          provider.config.gamepadShoulderStyle,
                        ),
                        style: omisuRetroLabelStyle(
                          context,
                          size: 10,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.45,
                      child: SettingRow(
                        key: _itemKeys[1],
                        onTap: () => selectItem(1),
                        focused:
                            widget.isContentFocused &&
                            widget.selectedContentIndex == 1,
                        title: AppLocale.inputSwapAbxy.getString(context),
                        subtitle: AppLocale.inputSwapAbxySubtitle.getString(
                          context,
                        ),
                        trailing: Icon(
                          Symbols.lock_rounded,
                          size: 18.r,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
