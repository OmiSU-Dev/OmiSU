/// Local-only stream keys for **developer builds only** (gitignored).
///
/// Copy [streaming_local_secrets.values.dart.example] to
/// `streaming_local_secrets.values.dart`. Leave empty for release builds —
/// keys are never merged into the app automatically; use Settings → Streaming.
library;

part 'streaming_local_secrets.values.dart';

class StreamingLocalSecrets {
  static String get kickStreamKey => kickStreamKeyValue;
}
