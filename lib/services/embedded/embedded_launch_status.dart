/// Omarchy-style boot prompts shown while embedded play starts.
class EmbeddedLaunchStatus {
  const EmbeddedLaunchStatus({
    required this.prompt,
    required this.detail,
  });

  final String prompt;
  final String detail;

  static const initial = EmbeddedLaunchStatus(
    prompt: '> load_cartridge_',
    detail: 'Starting game session…',
  );

  static const desktopUnsupported = EmbeddedLaunchStatus(
    prompt: '> platform_err_',
    detail: 'Built-in play is available on Android devices.',
  );

  static EmbeddedLaunchStatus fromNativeMessage(String message) {
    switch (message) {
      case 'Preparing built-in player…':
        return const EmbeddedLaunchStatus(
          prompt: '> init_core_',
          detail: 'Preparing emulation core…',
        );
      case 'Loading game…':
        return const EmbeddedLaunchStatus(
          prompt: '> load_rom_',
          detail: 'Loading game data…',
        );
      case 'Preparing PSP system files…':
        return const EmbeddedLaunchStatus(
          prompt: '> psp_sys_',
          detail: 'Preparing PSP system files…',
        );
      default:
        return EmbeddedLaunchStatus(
          prompt: '> load_cartridge_',
          detail: message,
        );
    }
  }
}
