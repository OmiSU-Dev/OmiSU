/// Friendly labels and short hints for in-game libretro core options.
class EmbeddedCoreOptionPresentation {
  const EmbeddedCoreOptionPresentation({
    required this.title,
    required this.currentValue,
    this.hint,
  });

  final String title;
  final String currentValue;
  final String? hint;
}

/// Parsed libretro option metadata from a core variable [description].
({String? name, List<String> values}) parseLibretroOptionDescription(
  String? description,
) {
  final raw = description?.trim();
  if (raw == null || raw.isEmpty) {
    return (name: null, values: const []);
  }

  final parts = raw.split(';');
  if (parts.length >= 2) {
    final name = parts.first.trim();
    final values = parts
        .sublist(1)
        .join(';')
        .split('|')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return (name: name.isEmpty ? null : name, values: values);
  }

  if (raw.contains('|')) {
    return (
      name: null,
      values: raw
          .split('|')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(),
    );
  }

  return (name: raw, values: const []);
}

String humanizeCoreOptionToken(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return '—';

  final lower = value.toLowerCase();
  const direct = {
    'enabled': 'On',
    'disabled': 'Off',
    'on': 'On',
    'off': 'Off',
    'true': 'On',
    'false': 'Off',
    'auto': 'Automatic',
    'default': 'Default',
    'none': 'None',
  };
  if (direct.containsKey(lower)) {
    return direct[lower]!;
  }

  final cleaned = value
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return value;

  const acronyms = {
    'gb': 'GB',
    'gbc': 'GBC',
    'gba': 'GBA',
    'snes': 'SNES',
    'nes': 'NES',
    'cpu': 'CPU',
    'gpu': 'GPU',
    'rtc': 'RTC',
    'sram': 'SRAM',
    'bios': 'BIOS',
    'hd': 'HD',
    'ui': 'UI',
    '3d': '3D',
    '2d': '2D',
  };

  return cleaned
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        final lower = word.toLowerCase();
        if (acronyms.containsKey(lower)) {
          return acronyms[lower]!;
        }
        if (word.length <= 3 && word == word.toUpperCase()) {
          return word;
        }
        if (RegExp(r'^\d').hasMatch(word)) return word;
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}

String friendlyCoreOptionTitle({
  required String key,
  String? descriptionName,
}) {
  final fromDescription = descriptionName?.trim();
  if (fromDescription != null && fromDescription.isNotEmpty) {
    return fromDescription;
  }

  var token = key.trim();
  for (final prefix in _corePrefixes) {
    if (token.startsWith(prefix)) {
      token = token.substring(prefix.length);
      break;
    }
  }

  return humanizeCoreOptionToken(token);
}

String friendlyCoreOptionValue({
  required String? value,
  required List<String> selectableValues,
}) {
  final current = value?.trim();
  if (current == null || current.isEmpty) return '—';

  final exactIndex = selectableValues.indexWhere(
    (option) => option.toLowerCase() == current.toLowerCase(),
  );
  if (exactIndex >= 0) {
    return humanizeCoreOptionToken(selectableValues[exactIndex]);
  }

  return humanizeCoreOptionToken(current);
}

String? coreOptionHint(String key) {
  final normalized = key.toLowerCase();
  final matches = _hintMatchers.entries
      .where((entry) => normalized.contains(entry.key))
      .toList();
  if (matches.isEmpty) return null;
  matches.sort((a, b) => b.key.length.compareTo(a.key.length));
  return matches.first.value;
}

EmbeddedCoreOptionPresentation presentCoreOption({
  required String key,
  required String? value,
  required String? description,
  required List<String> selectableValues,
}) {
  final parsed = parseLibretroOptionDescription(description);
  return EmbeddedCoreOptionPresentation(
    title: friendlyCoreOptionTitle(
      key: key,
      descriptionName: parsed.name,
    ),
    currentValue: friendlyCoreOptionValue(
      value: value,
      selectableValues: parsed.values.isNotEmpty
          ? parsed.values
          : selectableValues,
    ),
    hint: coreOptionHint(key),
  );
}

const _corePrefixes = [
  'gambatte_',
  'mgba_',
  'ppsspp_',
  'snes9x_',
  'nestopia_',
  'fceumm_',
  'genesis_plus_gx_',
  'pcsx_rearmed_',
  'beetle_psx_',
  'melonds_',
  'desmume_',
];

const _hintMatchers = {
  'colorization': 'Choose how Game Boy graphics are colored.',
  'palette': 'Changes the screen colors used by the emulator.',
  'gb_palette': 'Pick a color palette for black-and-white Game Boy games.',
  'link': 'Settings for Game Boy link cable or multiplayer.',
  'network_server': 'How this device connects for link cable play.',
  'frameskip': 'Skip drawing some frames to improve speed on slower devices.',
  'frame_duplication': 'Repeat frames to keep motion smooth when the game runs slowly.',
  'rewind': 'Lets you step backward through recent gameplay.',
  'rumble': 'Turn controller vibration on or off.',
  'audio': 'Adjust how game audio is handled.',
  'sound': 'Adjust how game audio is handled.',
  'filter': 'Adds smoothing or scaling to the picture.',
  'interpolation': 'Smooths jagged edges in the image.',
  'resolution': 'Changes the internal rendering resolution.',
  'aspect': 'Controls how the game image fits on your screen.',
  'crop': 'Trims unused borders from the game image.',
  'overscan': 'Shows or hides the extra border area TVs used to hide.',
  'shader': 'Visual effect applied to the game image.',
  'cpu': 'Changes how the emulated processor runs.',
  'region': 'Sets which country version of the game hardware to emulate.',
  'bios': 'Uses a real system BIOS file when available.',
  'rtc': 'Controls the in-game real-time clock.',
  'sram': 'Settings for in-game save memory.',
  'save': 'Settings for how the game saves progress.',
  'cheat': 'Options related to cheat codes.',
  'fast_forward': 'Controls speed when fast-forward is active.',
  'vsync': 'Syncs the frame rate to your screen refresh rate.',
  'latency': 'Trade-off between input response and audio/video sync.',
  'deadzone': 'How far you must move a stick before it registers.',
  'analog': 'Settings for analog stick or trigger behavior.',
  'touch': 'On-screen touch control behavior.',
  'controller': 'How the emulator reads your controller.',
  'port': 'Which player or controller port this setting applies to.',
};
