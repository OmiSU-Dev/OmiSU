import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/models/system_model.dart';
import 'package:omisu/utils/rom_folder_path.dart';
import 'package:omisu/utils/rom_folder_system_resolver.dart';

void main() {
  group('normalizeRomFolderLabel', () {
    test('matches No-Intro hyphenated names to canonical aliases', () {
      expect(
        normalizeRomFolderLabel('Nintendo - Game Boy'),
        normalizeRomFolderLabel('Nintendo Game Boy'),
      );
      expect(
        normalizeRomFolderLabel('Nintendo - SNES'),
        normalizeRomFolderLabel('Nintendo SNES'),
      );
    });
  });

  group('RomFolderSystemResolver keywords', () {
    final systems = [
      const SystemModel(
        id: 'nes',
        folderName: 'nes',
        realName: 'NES',
        iconImage: 'assets/x/nes-icon.png',
        color: '#000',
      ),
      const SystemModel(
        id: 'snes',
        folderName: 'snes',
        realName: 'SNES',
        iconImage: 'assets/x/snes-icon.png',
        color: '#000',
      ),
    ];

    test('maps No-Intro NES/SNES folder labels via keyword heuristics', () {
      expect(
        RomFolderSystemResolver.resolveSystemIdFromLabel(
          'Nintendo - NES',
          availableSystems: systems,
        ),
        'nes',
      );
      expect(
        RomFolderSystemResolver.resolveSystemIdFromLabel(
          'Nintendo - SNES',
          availableSystems: systems,
        ),
        'snes',
      );
    });
  });
}
