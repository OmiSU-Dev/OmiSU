import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/services/streaming/stream_platform.dart';
import 'package:omisu/services/streaming/stream_settings_service.dart';
import 'package:omisu/services/streaming/streaming_local_secrets.dart';
import 'package:omisu/utils/adaptive_scroll.dart';
import 'package:omisu/widgets/custom_toggle_switch.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_title.dart';
import 'widgets/setting_row.dart';
import 'widgets/settings_section_header.dart';
import 'widgets/streaming_platform_cards.dart';

class StreamingSettingsContent extends StatefulWidget {
  final bool isContentFocused;
  final int selectedContentIndex;

  const StreamingSettingsContent({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
  });

  @override
  State<StreamingSettingsContent> createState() =>
      StreamingSettingsContentState();
}

class StreamingSettingsContentState extends State<StreamingSettingsContent> {
  StreamSettings _settings = const StreamSettings();
  StreamPlatform? _selectedPlatform;
  final _serverController = TextEditingController();
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  String? _validationMessage;
  final ScrollController _scrollController = ScrollController();
  final AdaptiveScroller _scroller = AdaptiveScroller();
  final List<GlobalKey> _itemKeys = List.generate(12, (_) => GlobalKey());

  int getItemCount() {
    if (!Platform.isAndroid) return 0;
    return _settings.faceCamEnabled ? 12 : 10;
  }

  void scrollToIndex(int index) {
    _scroller.ensureVisibleIndex(
      index,
      keys: _itemKeys,
      controller: _scrollController,
    );
  }

  void selectItem(int index) {
    if (!Platform.isAndroid) return;
    SfxService().playEnterSound();
    switch (index) {
      case 0:
        unawaited(_selectPlatform(StreamPlatform.twitch));
      case 1:
        unawaited(_selectPlatform(StreamPlatform.youtube));
      case 2:
        unawaited(_selectPlatform(StreamPlatform.kick));
      case 3:
        unawaited(_openDashboard());
      case 4:
        unawaited(_pasteStreamKey());
      case 5:
        _cycleQuality();
      case 6:
        _validateUrl();
      case 7:
        if (_settings.gameAudioEnabled && !_settings.includeMicrophone) {
          return;
        }
        unawaited(
          _save(
            _settings.copyWith(
              gameAudioEnabled: !_settings.gameAudioEnabled,
            ),
          ),
        );
      case 8:
        unawaited(
          _save(
            _settings.copyWith(
              includeMicrophone: !_settings.includeMicrophone,
            ),
          ),
        );
      case 9:
        final enable = !_settings.faceCamEnabled;
        unawaited(
          _save(
            _settings.copyWith(
              faceCamEnabled: enable,
              includeMicrophone: enable ? true : _settings.includeMicrophone,
            ),
          ),
        );
      case 10:
        if (_settings.faceCamEnabled) _cycleFaceCamCorner();
      case 11:
        if (_settings.faceCamEnabled) _cycleFaceCamSize();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    unawaited(_persistCredentials());
    _scrollController.dispose();
    _serverController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await StreamSettingsService.ensureStreamCredentials();
    if (!mounted) return;
    final s = StreamSettingsService.current;
    setState(() {
      _settings = s;
      _serverController.text = s.rtmpServerUrl;
      _keyController.text = s.streamKey;
      _selectedPlatform = StreamPlatformX.detectFromServerUrl(s.rtmpServerUrl);
    });
  }

  Future<void> _save(StreamSettings next) async {
    await StreamSettingsService.save(next);
    if (mounted) {
      setState(() {
        _settings = next;
        _selectedPlatform =
            StreamPlatformX.detectFromServerUrl(next.rtmpServerUrl);
      });
    }
  }

  Future<void> _selectPlatform(StreamPlatform platform) async {
    var streamKey = _keyController.text.trim();
    if (platform == StreamPlatform.kick) {
      final kickKey = StreamingLocalSecrets.kickStreamKey.trim();
      if (kickKey.isNotEmpty) {
        streamKey = kickKey;
        _keyController.text = kickKey;
      }
    }
    final serverUrl = platform.ingestUrl;
    _serverController.text = serverUrl;
    setState(() => _selectedPlatform = platform);
    await _save(
      _settings.copyWith(
        rtmpServerUrl: serverUrl,
        streamKey: streamKey.isNotEmpty ? streamKey : _settings.streamKey,
      ),
    );
  }

  String _platformSteps(BuildContext context, StreamPlatform platform) {
    return switch (platform) {
      StreamPlatform.twitch =>
        AppLocale.streamingTwitchSteps.getString(context),
      StreamPlatform.youtube =>
        AppLocale.streamingYoutubeSteps.getString(context),
      StreamPlatform.kick => AppLocale.streamingKickSteps.getString(context),
    };
  }


  Future<void> _openDashboard() async {
    final platform = _selectedPlatform;
    if (platform == null) return;
    final url = platform.dashboardUri;
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.streamingOpenDashboardFailed.getString(context),
          ),
        ),
      );
    }
  }

  Future<void> _pasteStreamKey() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocale.streamingPasteStreamKeyEmpty.getString(context),
            ),
          ),
        );
      }
      return;
    }
    _keyController.text = text;
    await _persistCredentials();
  }

  void _validateUrl() {
    final error = StreamSettingsService.validateServerUrl(_serverController.text);
    setState(
      () => _validationMessage =
          error ?? AppLocale.streamingUrlOk.getString(context),
    );
  }

  void _cycleQuality() {
    final presets = StreamSettings.qualityPresets;
    final idx = presets.indexOf(_settings.qualityPreset);
    final next = presets[(idx + 1) % presets.length];
    unawaited(_save(_settings.copyWith(qualityPreset: next)));
  }

  void _cycleFaceCamCorner() {
    final corners = StreamSettings.faceCamCorners;
    final idx = corners.indexOf(_settings.faceCamCorner);
    final next = corners[(idx + 1) % corners.length];
    unawaited(_save(_settings.copyWith(faceCamCorner: next)));
  }

  void _cycleFaceCamSize() {
    final sizes = StreamSettings.faceCamSizes;
    final idx = sizes.indexOf(_settings.faceCamSize);
    final next = sizes[(idx + 1) % sizes.length];
    unawaited(_save(_settings.copyWith(faceCamSize: next)));
  }

  Future<void> _persistCredentials() async {
    await _save(
      _settings.copyWith(
        rtmpServerUrl: _serverController.text.trim(),
        streamKey: _keyController.text.trim(),
      ),
    );
  }

  Widget _row({
    required int index,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.r),
      child: SettingRow(
        key: _itemKeys[index],
        title: title,
        subtitle: subtitle,
        focused: widget.isContentFocused && widget.selectedContentIndex == index,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildPlatformHelpPanel(BuildContext context) {
    final platform = _selectedPlatform;
    if (platform == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 10.r),
      child: OmisuRetroPanel(
        padding: EdgeInsets.all(10.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocale.streamingPlatformHelpTitle.getString(context),
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 11.r,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.r),
            Text(
              _platformSteps(context, platform),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10.r,
                height: 1.35,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            SizedBox(height: 10.r),
            OutlinedButton.icon(
              onPressed: _openDashboard,
              icon: Icon(Symbols.open_in_new, size: 14.r),
              label: Text(
                AppLocale.streamingOpenDashboard.getString(context),
                style: TextStyle(fontSize: 11.r, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 32.r),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 6.r),
            OutlinedButton.icon(
              onPressed: _pasteStreamKey,
              icon: Icon(Symbols.content_paste, size: 14.r),
              label: Text(
                AppLocale.streamingPasteStreamKey.getString(context),
                style: TextStyle(fontSize: 11.r, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 32.r),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? get _focusedPlatformIndex {
    if (!widget.isContentFocused) return null;
    final idx = widget.selectedContentIndex;
    if (idx >= 0 && idx <= 2) return idx;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return Center(
        child: Text(AppLocale.streamingAndroidOnly.getString(context)),
      );
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsTitle(
          title: AppLocale.streaming.getString(context),
          subtitle: AppLocale.streamingSubtitle.getString(context),
        ),
        SizedBox(height: 12.r),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsSectionHeader(
                  label: AppLocale.streamingPlatformSection.getString(context),
                ),
                Text(
                  AppLocale.streamingPlatformSelectedHint.getString(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.r,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                SizedBox(height: 8.r),
                StreamingPlatformCards(
                  selected: _selectedPlatform,
                  onSelect: (p) => unawaited(_selectPlatform(p)),
                  twitchLabel:
                      AppLocale.streamingPlatformTwitch.getString(context),
                  youtubeLabel:
                      AppLocale.streamingPlatformYoutube.getString(context),
                  kickLabel:
                      AppLocale.streamingPlatformKick.getString(context),
                  focusedPlatformIndex: _focusedPlatformIndex,
                  platformItemKeys: _itemKeys.sublist(0, 3),
                ),
                _buildPlatformHelpPanel(context),
                _row(
                  index: 3,
                  title: AppLocale.streamingOpenDashboard.getString(context),
                  subtitle: _selectedPlatform != null
                      ? _selectedPlatform!.dashboardUri.toString()
                      : AppLocale.streamingPlatformSelectedHint.getString(
                          context,
                        ),
                  trailing: const Icon(Symbols.open_in_new, size: 20),
                  onTap: _openDashboard,
                ),
                _row(
                  index: 4,
                  title: AppLocale.streamingPasteStreamKey.getString(context),
                  subtitle: AppLocale.streamingStreamKey.getString(context),
                  trailing: const Icon(Symbols.content_paste, size: 20),
                  onTap: _pasteStreamKey,
                ),
                SettingsSectionHeader(
                  label: AppLocale.streamingRtmpSection.getString(context),
                ),
                OmisuRetroPanel(
                  padding: EdgeInsets.all(10.r),
                  child: Column(
                    children: [
                      TextField(
                        controller: _serverController,
                        decoration: InputDecoration(
                          labelText:
                              AppLocale.streamingServerUrl.getString(context),
                          isDense: true,
                        ),
                        onEditingComplete: _persistCredentials,
                      ),
                      SizedBox(height: 8.r),
                      TextField(
                        controller: _keyController,
                        obscureText: _obscureKey,
                        decoration: InputDecoration(
                          labelText:
                              AppLocale.streamingStreamKey.getString(context),
                          isDense: true,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Symbols.content_paste, size: 20),
                                tooltip: AppLocale.streamingPasteStreamKey
                                    .getString(context),
                                onPressed: _pasteStreamKey,
                              ),
                              IconButton(
                                icon: Icon(
                                  _obscureKey
                                      ? Symbols.visibility
                                      : Symbols.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureKey = !_obscureKey),
                              ),
                            ],
                          ),
                        ),
                        onEditingComplete: _persistCredentials,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.r),
                _row(
                  index: 5,
                  title: AppLocale.streamingQuality.getString(context),
                  subtitle: _settings.qualityPreset,
                  trailing: const Icon(Symbols.hd, size: 20),
                  onTap: _cycleQuality,
                ),
                _row(
                  index: 6,
                  title: AppLocale.streamingValidateUrl.getString(context),
                  subtitle: _validationMessage ?? '',
                  trailing: const Icon(Symbols.check_circle, size: 20),
                  onTap: _validateUrl,
                ),
                SettingsSectionHeader(
                  label: AppLocale.streamingAudioSection.getString(context),
                ),
                _row(
                  index: 7,
                  title: AppLocale.streamingGameAudio.getString(context),
                  subtitle: AppLocale.streamingGameAudioSubtitle.getString(context),
                  trailing: CustomToggleSwitch(
                    value: _settings.gameAudioEnabled,
                    onChanged: (v) {
                      if (!v && !_settings.includeMicrophone) return;
                      _save(_settings.copyWith(gameAudioEnabled: v));
                    },
                  ),
                  onTap: () {
                    if (_settings.gameAudioEnabled && !_settings.includeMicrophone) {
                      return;
                    }
                    _save(
                      _settings.copyWith(
                        gameAudioEnabled: !_settings.gameAudioEnabled,
                      ),
                    );
                  },
                ),
                _row(
                  index: 8,
                  title: AppLocale.streamingIncludeMic.getString(context),
                  subtitle: AppLocale.streamingIncludeMicSubtitle.getString(context),
                  trailing: CustomToggleSwitch(
                    value: _settings.includeMicrophone,
                    onChanged: (v) => _save(
                      _settings.copyWith(includeMicrophone: v),
                    ),
                  ),
                  onTap: () => _save(
                    _settings.copyWith(
                      includeMicrophone: !_settings.includeMicrophone,
                    ),
                  ),
                ),
                SettingsSectionHeader(
                  label: AppLocale.streamingFaceCamSection.getString(context),
                ),
                _row(
                  index: 9,
                  title: AppLocale.streamingFaceCam.getString(context),
                  subtitle: AppLocale.streamingFaceCamSubtitle.getString(context),
                  trailing: CustomToggleSwitch(
                    value: _settings.faceCamEnabled,
                    onChanged: (v) => _save(
                      _settings.copyWith(
                        faceCamEnabled: v,
                        includeMicrophone: v ? true : _settings.includeMicrophone,
                      ),
                    ),
                  ),
                  onTap: () {
                    final enable = !_settings.faceCamEnabled;
                    _save(
                      _settings.copyWith(
                        faceCamEnabled: enable,
                        includeMicrophone:
                            enable ? true : _settings.includeMicrophone,
                      ),
                    );
                  },
                ),
                if (_settings.faceCamEnabled) ...[
                  _row(
                    index: 10,
                    title: AppLocale.streamingFaceCamCorner.getString(context),
                    subtitle: _settings.faceCamCorner,
                    trailing: const Icon(Symbols.crop_free, size: 20),
                    onTap: _cycleFaceCamCorner,
                  ),
                  _row(
                    index: 11,
                    title: AppLocale.streamingFaceCamSize.getString(context),
                    subtitle: _settings.faceCamSize,
                    trailing: const Icon(Symbols.photo_size_select_small, size: 20),
                    onTap: _cycleFaceCamSize,
                  ),
                ],
                Text(
                  AppLocale.streamingFaceCamV11Note.getString(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.r,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
