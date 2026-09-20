import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/models/embedded_rom_cheat.dart';
import 'package:omisu/models/game_model.dart';
import 'package:omisu/models/system_model.dart';
import 'package:omisu/providers/retro_achievements_provider.dart';
import 'package:omisu/repositories/game_repository.dart';
import 'package:omisu/services/embedded/embedded_core_option_catalog.dart';
import 'package:omisu/services/embedded/embedded_core_option_presentation.dart';
import 'package:omisu/services/embedded/retroarch_cheat_file.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/widgets/custom_toggle_switch.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:omisu/services/embedded/embedded_emulator_service.dart';

/// Built-in player tweaks and cheats for a single game.
class GameSettingsPlayTab extends StatefulWidget {
  final GameModel game;
  final SystemModel system;
  final bool isAllMode;

  /// In-game pause sheet: cheat list only (database auto-sync; import in menu).
  final bool cheatsOnly;

  const GameSettingsPlayTab({
    super.key,
    required this.game,
    required this.system,
    required this.isAllMode,
    this.cheatsOnly = false,
  });

  @override
  State<GameSettingsPlayTab> createState() => GameSettingsPlayTabState();
}

class GameSettingsPlayTabState extends State<GameSettingsPlayTab> {
  List<EmbeddedCoreVariable> _tweaks = const [];
  Map<String, String> _savedVars = {};
  List<EmbeddedRomCheat> _cheats = const [];
  bool _loading = true;
  int _selectedIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  int get _tweakCount => _tweaks.length;

  bool get _showManualActions => !widget.cheatsOnly;

  int get _cheatSectionStart =>
      widget.cheatsOnly ? 0 : _tweakCount + (_tweaks.isNotEmpty ? 1 : 0);

  int? get _resetRowIndex =>
      !widget.cheatsOnly && _tweaks.isNotEmpty ? _tweakCount : null;

  int get _firstCheatIndex => _cheatSectionStart;

  int get _importChtIndex => _cheatSectionStart + _cheats.length;

  int get _importLibretroIndex => _importChtIndex + 1;

  int get _addCheatIndex => _importLibretroIndex + 1;

  int get _totalItems {
    final base = _cheatSectionStart + _cheats.length;
    return _showManualActions ? _addCheatIndex + 1 : base;
  }

  String get _systemFolder =>
      widget.game.systemFolderName ?? widget.system.folderName;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final displayName = widget.game.name.isNotEmpty
          ? widget.game.name
          : widget.game.realname;
      await GameRepository.syncCheatsFromSources(
        systemFolderName: _systemFolder,
        romname: widget.game.romname,
        romPath: widget.game.romPath,
        displayName: displayName,
        titleName: widget.game.titleName ?? widget.game.realname,
      );
      final saved = await GameRepository.getEmbeddedCoreVariables(
        _systemFolder,
        widget.game.romname,
      );
      final cheats = await GameRepository.getRomCheats(
        _systemFolder,
        widget.game.romname,
      );
      if (!mounted) return;
      setState(() {
        _savedVars = saved;
        _tweaks = catalogCoreOptionsForSystem(
          systemFolder: _systemFolder,
          savedValues: saved,
        );
        _cheats = cheats;
        _loading = false;
        _selectedIndex = 0;
      });
    } catch (e, st) {
      debugPrint('GameSettingsPlayTab._load failed: $e\n$st');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  GlobalKey _itemKey(int index) =>
      _itemKeys.putIfAbsent(index, () => GlobalKey());

  void scrollFocusedItemIntoView() => _scrollToSelected();

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

  bool moveUp() {
    if (_totalItems == 0) return false;
    final next = (_selectedIndex - 1).clamp(0, _totalItems - 1);
    if (next == _selectedIndex) return false;
    setState(() => _selectedIndex = next);
    _scrollToSelected();
    return true;
  }

  bool moveDown() {
    if (_totalItems == 0) return false;
    final next = (_selectedIndex + 1).clamp(0, _totalItems - 1);
    if (next == _selectedIndex) return false;
    setState(() => _selectedIndex = next);
    _scrollToSelected();
    return true;
  }

  void trigger() {
    if (_loading || _totalItems == 0) return;
    SfxService().playEnterSound();
    if (_selectedIndex < _tweakCount) {
      unawaited(_cycleTweak(_tweaks[_selectedIndex]));
      return;
    }
    if (_resetRowIndex != null && _selectedIndex == _resetRowIndex) {
      unawaited(_resetTweaks());
      return;
    }
    if (_selectedIndex >= _firstCheatIndex &&
        _selectedIndex < _firstCheatIndex + _cheats.length) {
      final cheat = _cheats[_selectedIndex - _firstCheatIndex];
      unawaited(_toggleCheat(cheat));
      return;
    }
    if (_showManualActions) {
      if (_selectedIndex == _importChtIndex) {
        unawaited(_importChtBesideRom());
        return;
      }
      if (_selectedIndex == _importLibretroIndex) {
        unawaited(_importFromLibretroDatabase());
        return;
      }
      if (_selectedIndex == _addCheatIndex) {
        unawaited(_showAddCheatDialog());
      }
    }
  }

  Future<void> showManualCheatActionsMenu() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_open_rounded),
                title: Text(AppLocale.gameSettingsImportCht.getString(ctx)),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_importChtBesideRom());
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_rounded),
                title: Text(AppLocale.gameSettingsAddCheat.getString(ctx)),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_showAddCheatDialog());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _persistVars() async {
    await GameRepository.setEmbeddedCoreVariables(
      _systemFolder,
      widget.game.romname,
      _savedVars,
    );
  }

  Future<void> _cycleTweak(EmbeddedCoreVariable variable) async {
    final options = variable.selectableValues;
    if (options.length < 2) return;
    final current = _savedVars[variable.key] ?? options.first;
    final index = options.indexOf(current);
    final next = options[(index + 1) % options.length];
    setState(() {
      _savedVars = {..._savedVars, variable.key: next};
      _tweaks = catalogCoreOptionsForSystem(
        systemFolder: _systemFolder,
        savedValues: _savedVars,
      );
    });
    await _persistVars();
  }

  Future<void> _resetTweaks() async {
    await GameRepository.clearEmbeddedCoreVariables(
      _systemFolder,
      widget.game.romname,
    );
    await _load();
  }

  Future<void> _toggleCheat(EmbeddedRomCheat cheat) async {
    final enabled = !cheat.enabled;
    await GameRepository.setRomCheatEnabled(cheat.id, enabled);
    await _load();
    if (widget.cheatsOnly && Platform.isAndroid && _cheats.isNotEmpty) {
      await EmbeddedEmulatorService.applyCheats(
        _cheats
            .map((c) => (code: c.code, enabled: c.enabled))
            .toList(),
      );
    }
  }

  Future<void> _importCheatFile(
    File file, {
    bool replaceExisting = false,
  }) async {
    final parsed = parseRetroArchCheatFile(await file.readAsString());
    if (parsed.isEmpty) return;
    await GameRepository.importRomCheats(
      _systemFolder,
      widget.game.romname,
      parsed,
      replaceExisting: replaceExisting,
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocale.gameSettingsLibretroCheatsImported
              .getString(context)
              .replaceAll('%1', '${parsed.length}'),
        ),
      ),
    );
  }

  Future<void> _importChtBesideRom() async {
    final romPath = widget.game.romPath;
    if (romPath == null || romPath.isEmpty) return;
    final chtPath = p.setExtension(romPath, '.cht');
    final file = File(chtPath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file: $chtPath')),
      );
      return;
    }
    await _importCheatFile(file);
  }

  Future<void> _importFromLibretroDatabase() async {
    final displayName = widget.game.name.isNotEmpty
        ? widget.game.name
        : widget.game.realname;
    final count = await GameRepository.syncCheatsFromSources(
      systemFolderName: _systemFolder,
      romname: widget.game.romname,
      romPath: widget.game.romPath,
      displayName: displayName,
      titleName: widget.game.titleName ?? widget.game.realname,
      onlyIfEmpty: false,
    );
    if (count == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.gameSettingsLibretroCheatsNotFound.getString(context),
          ),
        ),
      );
      return;
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocale.gameSettingsLibretroCheatsImported
              .getString(context)
              .replaceAll('%1', '$count'),
        ),
      ),
    );
  }

  Future<void> _showAddCheatDialog() async {
    final descController = TextEditingController();
    final codeController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppLocale.gameSettingsAddCheat.getString(ctx)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: AppLocale.gameSettingsCheatDescriptionHint
                      .getString(ctx),
                ),
              ),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: AppLocale.gameSettingsCheatCodeHint.getString(ctx),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocale.cancel.getString(ctx)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocale.ok.getString(ctx)),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final code = codeController.text.trim();
    if (code.isEmpty) return;
    final description = descController.text.trim().isEmpty
        ? 'Custom cheat'
        : descController.text.trim();
    await GameRepository.addRomCheat(
      systemFolderName: _systemFolder,
      romname: widget.game.romname,
      description: description,
      code: code,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final raConnected =
        context.select<RetroAchievementsProvider, bool>(
          (p) => p.isConnected,
        );

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.cheatsOnly)
            Text(
              AppLocale.gameSettingsPlayAppliesNextLaunch.getString(context),
              style: TextStyle(
                fontSize: 10.r,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          if (raConnected) ...[
            SizedBox(height: 8.r),
            OmisuRetroPanel(
              padding: EdgeInsets.all(8.r),
              child: Row(
                children: [
                  Icon(
                    Symbols.warning_rounded,
                    size: 14.r,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(width: 8.r),
                  Expanded(
                    child: Text(
                      AppLocale.gameSettingsRaCheatWarning.getString(context),
                      style: TextStyle(fontSize: 10.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!widget.cheatsOnly && _tweaks.isNotEmpty) ...[
            SizedBox(height: 12.r),
            Text(
              AppLocale.gameSettingsPlayTweaks.getString(context),
              style: TextStyle(
                fontSize: 11.r,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.r),
            ..._tweaks.asMap().entries.map((entry) {
              final i = entry.key;
              final variable = entry.value;
              return _buildTweakRow(context, i, variable);
            }),
            _buildActionRow(
              context,
              _tweakCount,
              AppLocale.gameSettingsResetPlayTweaks.getString(context),
              Symbols.restart_alt_rounded,
              onTap: () => unawaited(_resetTweaks()),
            ),
          ],
          if (!widget.cheatsOnly) ...[
            SizedBox(height: 12.r),
            Text(
              AppLocale.gameSettingsPlayCheats.getString(context),
              style: TextStyle(
                fontSize: 11.r,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.r),
          ],
          if (_cheats.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.r, top: widget.cheatsOnly ? 8.r : 0),
              child: Text(
                widget.cheatsOnly
                    ? AppLocale.gameSettingsNoCheatsForGame.getString(context)
                    : AppLocale.gameSettingsNoPlayOptions.getString(context),
                style: TextStyle(
                  fontSize: 10.r,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ..._cheats.asMap().entries.map((entry) {
            final cheat = entry.value;
            final index = _firstCheatIndex + entry.key;
            return _buildCheatRow(context, index, cheat);
          }),
          if (_showManualActions) ...[
            _buildActionRow(
              context,
              _importChtIndex,
              AppLocale.gameSettingsImportCht.getString(context),
              Symbols.file_open_rounded,
              onTap: () => unawaited(_importChtBesideRom()),
            ),
            _buildActionRow(
              context,
              _importLibretroIndex,
              AppLocale.gameSettingsImportLibretroCheats.getString(context),
              Symbols.cloud_download_rounded,
              onTap: () => unawaited(_importFromLibretroDatabase()),
            ),
            _buildActionRow(
              context,
              _addCheatIndex,
              AppLocale.gameSettingsAddCheat.getString(context),
              Symbols.add_rounded,
              onTap: () => unawaited(_showAddCheatDialog()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTweakRow(
    BuildContext context,
    int index,
    EmbeddedCoreVariable variable,
  ) {
    final theme = Theme.of(context);
    final selected = _selectedIndex == index;
    final presentation = presentCoreOption(
      key: variable.key,
      value: _savedVars[variable.key],
      description: variable.description,
      selectableValues: variable.selectableValues,
    );
    return Padding(
      key: _itemKey(index),
      padding: EdgeInsets.only(bottom: 6.r),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
        child: InkWell(
          onTap: () => unawaited(_cycleTweak(variable)),
          borderRadius: BorderRadius.circular(6.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.title,
                        style: TextStyle(
                          fontSize: 11.r,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        presentation.currentValue,
                        style: TextStyle(
                          fontSize: 10.r,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right_rounded,
                  size: 16.r,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheatRow(
    BuildContext context,
    int index,
    EmbeddedRomCheat cheat,
  ) {
    final theme = Theme.of(context);
    final selected = _selectedIndex == index;
    return Padding(
      key: _itemKey(index),
      padding: EdgeInsets.only(bottom: 6.r),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 6.r),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  cheat.description,
                  style: TextStyle(fontSize: 11.r),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CustomToggleSwitch(
                value: cheat.enabled,
                onChanged: (_) => unawaited(_toggleCheat(cheat)),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    int index,
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final selected = _selectedIndex == index;
    return Padding(
      key: _itemKey(index),
      padding: EdgeInsets.only(bottom: 6.r),
      child: Material(
        color: selected
            ? theme.colorScheme.secondary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6.r),
        child: InkWell(
          onTap: () {
            SfxService().playEnterSound();
            onTap();
          },
          borderRadius: BorderRadius.circular(6.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
            child: Row(
              children: [
                Icon(icon, size: 16.r, color: theme.colorScheme.secondary),
                SizedBox(width: 8.r),
                Expanded(
                  child: Text(label, style: TextStyle(fontSize: 11.r)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
