import 'package:flutter/foundation.dart';

/// Live boot-phase text for the pre-init splash (Omarchy-style `> prompt_` line).
class BootStatus {
  BootStatus._();

  static final BootStatus instance = BootStatus._();

  final ValueNotifier<String> promptLine = ValueNotifier<String>('> boot_');
  final ValueNotifier<String> detailLine = ValueNotifier<String>('');

  void set({required String prompt, required String detail}) {
    if (promptLine.value != prompt) promptLine.value = prompt;
    if (detailLine.value != detail) detailLine.value = detail;
  }
}
