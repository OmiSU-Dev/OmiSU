import 'package:omisu/services/streaming/stream_settings_service.dart';

/// Live streaming destination for RTMP ingest setup.
enum StreamPlatform {
  twitch,
  youtube,
  kick,
}

extension StreamPlatformX on StreamPlatform {
  String get ingestUrl => switch (this) {
        StreamPlatform.twitch => StreamSettings.twitchServer,
        StreamPlatform.youtube => StreamSettings.youtubeServer,
        StreamPlatform.kick => StreamSettings.kickServer,
      };

  Uri get dashboardUri => switch (this) {
        StreamPlatform.twitch => Uri.parse(
              'https://dashboard.twitch.tv/settings/stream',
            ),
        StreamPlatform.youtube => Uri.parse('https://studio.youtube.com/'),
        StreamPlatform.kick => Uri.parse(
              'https://kick.com/dashboard/settings/stream',
            ),
      };

  static StreamPlatform? detectFromServerUrl(String serverUrl) {
    final trimmed = serverUrl.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed == StreamSettings.twitchServer.trim()) {
      return StreamPlatform.twitch;
    }
    if (trimmed == StreamSettings.youtubeServer.trim()) {
      return StreamPlatform.youtube;
    }
    if (trimmed == StreamSettings.kickServer.trim() ||
        trimmed.contains('global-contribute.live-video.net') ||
        trimmed.contains('live-video.net')) {
      return StreamPlatform.kick;
    }
    return null;
  }
}
