import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/services/streaming/stream_platform.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Twitch / YouTube / Kick destination picker for RTMP setup.
class StreamingPlatformCards extends StatelessWidget {
  const StreamingPlatformCards({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.twitchLabel,
    required this.youtubeLabel,
    required this.kickLabel,
    this.focusedPlatformIndex,
    this.platformItemKeys,
  });

  final StreamPlatform? selected;
  final ValueChanged<StreamPlatform> onSelect;
  final String twitchLabel;
  final String youtubeLabel;
  final String kickLabel;

  /// 0–2 when gamepad focus is on a platform row; highlights matching card.
  final int? focusedPlatformIndex;

  /// Optional keys for gamepad scroll-to-focus (indices 0–2).
  final List<GlobalKey>? platformItemKeys;

  static const _platforms = [
    StreamPlatform.twitch,
    StreamPlatform.youtube,
    StreamPlatform.kick,
  ];

  String _labelFor(StreamPlatform platform) => switch (platform) {
        StreamPlatform.twitch => twitchLabel,
        StreamPlatform.youtube => youtubeLabel,
        StreamPlatform.kick => kickLabel,
      };

  IconData _iconFor(StreamPlatform platform) => switch (platform) {
        StreamPlatform.twitch => Symbols.live_tv,
        StreamPlatform.youtube => Symbols.video_library,
        StreamPlatform.kick => Symbols.sports_esports,
      };

  @override
  Widget build(BuildContext context) {
    return OmisuRetroPanel(
      padding: EdgeInsets.all(8.r),
      child: Row(
        children: [
          for (var i = 0; i < _platforms.length; i++) ...[
            if (i > 0) SizedBox(width: 6.r),
            Expanded(
              child: _PlatformCard(
                key: platformItemKeys != null && platformItemKeys!.length > i
                    ? platformItemKeys![i]
                    : null,
                label: _labelFor(_platforms[i]),
                icon: _iconFor(_platforms[i]),
                selected: selected == _platforms[i],
                gamepadFocused: focusedPlatformIndex == i,
                onTap: () => onSelect(_platforms[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.gamepadFocused,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool gamepadFocused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final borderColor = gamepadFocused
        ? primary
        : selected
            ? primary.withValues(alpha: 0.75)
            : theme.colorScheme.outline.withValues(alpha: 0.35);
    final borderWidth = (selected || gamepadFocused) ? 2.0 : 1.0;

    return Material(
      color: selected
          ? primary.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(4.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.r, horizontal: 6.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22.r,
                    color: selected ? primary : theme.colorScheme.onSurface,
                  ),
                  if (selected)
                    Positioned(
                      right: -6.r,
                      top: -4.r,
                      child: Icon(
                        Symbols.check_circle,
                        size: 14.r,
                        color: primary,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6.r),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 9.r,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
