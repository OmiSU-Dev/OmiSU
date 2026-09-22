import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/utils/app_path_display.dart';

void main() {
  test('forUser replaces legacy NeoStation folder segment', () {
    expect(
      AppPathDisplay.forUser(
        '/storage/emulated/0/NeoStation/rom_import/game.zip',
      ),
      '/storage/emulated/0/OmiSU/rom_import/game.zip',
    );
  });

  test('forUser leaves paths without legacy branding unchanged', () {
    const path = '/storage/emulated/0/ROMS/nes';
    expect(AppPathDisplay.forUser(path), path);
  });
}
