/// Local-only stream keys (never commit real keys).
///
/// Copy [streaming_local_secrets.values.dart.example] to
/// `streaming_local_secrets.values.dart` and fill in your key.
library;

part 'streaming_local_secrets.values.dart';

class StreamingLocalSecrets {
  static String get kickStreamKey => kickStreamKeyValue;
}
