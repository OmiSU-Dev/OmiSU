import 'directories_settings_content.dart';

/// Library settings — directories, scan behaviour, and import tools.
class LibrarySettingsContent extends DirectoriesSettingsContent {
  const LibrarySettingsContent({
    super.key,
    required super.isContentFocused,
    required super.selectedContentIndex,
  }) : super(useLibraryTitle: true);
}

typedef LibrarySettingsContentState = DirectoriesSettingsContentState;
