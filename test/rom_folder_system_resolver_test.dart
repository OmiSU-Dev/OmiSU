import 'dart:convert';
import 'dart:io';

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

  group('Nintendo DS folder ownership', () {
    late List<String> dsFolders;
    late List<String> ndsFolders;

    setUpAll(() {
      Map<String, dynamic> load(String name) {
        final file = File('assets/systems/$name');
        expect(file.existsSync(), isTrue, reason: 'run from the Nordi root');
        return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      }

      List<String> folders(Map<String, dynamic> json) {
        final system = json['system'] as Map<String, dynamic>;
        return (system['folders'] as List).map((f) => f.toString()).toList();
      }

      dsFolders = folders(load('ds.json'));
      ndsFolders = folders(load('nds.json'));
    });

    test('ds.json and nds.json do not claim the same ROM folders', () {
      final dsKeys = dsFolders.map(normalizeRomFolderLabel).toSet();
      final ndsKeys = ndsFolders.map(normalizeRomFolderLabel).toSet();
      expect(dsKeys.intersection(ndsKeys), isEmpty);
    });

    test('nds owns the common library names and ds keeps its own folder', () {
      final systems = [
        SystemModel(
          id: 'ds',
          folderName: 'ds',
          realName: 'Nintendo DS',
          iconImage: 'assets/x/ds-icon.png',
          color: '#000',
          folders: dsFolders,
        ),
        SystemModel(
          id: 'nds',
          folderName: 'nds',
          realName: 'Nintendo DS',
          iconImage: 'assets/x/nds-icon.png',
          color: '#000',
          folders: ndsFolders,
        ),
      ];

      expect(
        RomFolderSystemResolver.resolveSystemIdFromLabel(
          'nds',
          availableSystems: systems,
        ),
        'nds',
      );
      expect(
        RomFolderSystemResolver.resolveSystemIdFromLabel(
          'Nintendo DS',
          availableSystems: systems,
        ),
        'nds',
      );
      expect(
        RomFolderSystemResolver.resolveSystemIdFromLabel(
          'ds',
          availableSystems: systems,
        ),
        'ds',
      );
    });
  });
}
