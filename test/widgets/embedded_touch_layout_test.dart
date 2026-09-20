import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/widgets/embedded/embedded_touch_layout.dart';

void main() {
  test('GB uses 2-button Nintendo layout', () {
    final layout = EmbeddedTouchLayoutConfig.forSystem('gb');
    expect(layout.faceLayout, TouchFaceLayout.nintendo2);
    expect(layout.showShoulders, isFalse);
  });

  test('SNES uses 4-button layout with shoulders', () {
    final layout = EmbeddedTouchLayoutConfig.forSystem('snes');
    expect(layout.faceLayout, TouchFaceLayout.nintendo4);
    expect(layout.showShoulders, isTrue);
  });

  test('folder alias sfc resolves to SNES layout', () {
    final layout = EmbeddedTouchLayoutConfig.forSystem('sfc');
    expect(layout.faceLayout, TouchFaceLayout.nintendo4);
  });

  test('Genesis uses 6-button layout', () {
    final layout = EmbeddedTouchLayoutConfig.forSystem('genesis');
    expect(layout.faceLayout, TouchFaceLayout.genesis6);
  });

  test('PS1 uses PlayStation layout with triggers', () {
    final layout = EmbeddedTouchLayoutConfig.forSystem('ps1');
    expect(layout.faceLayout, TouchFaceLayout.playstation);
    expect(layout.showTriggers, isTrue);
  });

  test('N64 uses C-buttons and hides Select', () {
    final layout = EmbeddedTouchLayoutConfig.forSystem('n64');
    expect(layout.faceLayout, TouchFaceLayout.n64);
    expect(layout.showSelect, isFalse);
  });

  test('MAME uses arcade 4-button layout', () {
    final layout = EmbeddedTouchLayoutConfig.forSystem('mame');
    expect(layout.faceLayout, TouchFaceLayout.arcade4);
    expect(layout.showStart, isFalse);
  });
}
