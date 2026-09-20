import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../models/system_model.dart';
import '../providers/file_provider.dart';
import '../sync/i_sync_provider.dart';
import '../services/game_service.dart';
import '../services/game_launch_manager.dart';
import '../services/embedded/embedded_exit_destination.dart';
import '../widgets/game_launch_dialog.dart';

/// Runs post-game navigation cleanup after embedded or external play ends.
void invokeGameClosedNavigation({
  required BuildContext context,
  required VoidCallback onGameClosed,
  VoidCallback? onHomeExit,
}) {
  if (!GameLaunchManager().tryBeginPostGameNavigation()) {
    return;
  }

  final exitHome = EmbeddedExitHandler.consumePendingHome();

  if (exitHome) {
    EmbeddedExitHandler.navigateToHome();
    onHomeExit?.call();
    return;
  }

  onGameClosed();
}

/// Standardizes the game launch workflow: Session initialization -> Progress Dialog -> Delay -> Execution -> Monitoring.
Future<void> launchGameWithDialog({
  required BuildContext context,
  required GameModel game,
  required SystemModel system,
  required FileProvider fileProvider,
  required ISyncProvider syncProvider,
  required VoidCallback onGameClosed,
  VoidCallback? onHomeExit,
  Future<void> Function(BuildContext context, GameLaunchResult result)?
  onLaunchFailed,
}) async {
  GameService.beginLaunchPending();
  await GameLaunchManager().beginSession();
  if (!context.mounted) {
    GameService.clearLaunchPending();
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => GameLaunchDialog(
      game: game,
      system: system,
      fileProvider: fileProvider,
      syncProvider: syncProvider,
      onGameClosed: () => invokeGameClosedNavigation(
        context: context,
        onGameClosed: onGameClosed,
        onHomeExit: onHomeExit,
      ),
    ),
  );

  final syncDeadline = SyncDeadline(const Duration(seconds: 8));
  await Future.wait([
    Future.delayed(const Duration(seconds: 2)),
    syncProvider
        .syncGameSavesBeforeLaunch(game, deadline: syncDeadline)
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => SyncResult.fail(SyncError.networkError),
        )
        .catchError((_) => SyncResult.fail(SyncError.unknown)),
  ]);
  if (!context.mounted) {
    GameService.clearLaunchPending();
    return;
  }

  GameLaunchManager().registerEmbeddedPostGameNav(() {
    invokeGameClosedNavigation(
      context: context,
      onGameClosed: onGameClosed,
      onHomeExit: onHomeExit,
    );
  });

  final result = await GameService.launchGame(context, system, game);

  if (result.success) {
    if (result.embeddedPlay) {
      // Navigation runs in GameLaunchService after finalizeEmbeddedPlay.
    } else {
      GameLaunchManager().clearEmbeddedPostGameNav();
      GameLaunchManager().onGameStarted(
        emulatorExe: GameService.launchedEmulatorExe,
      );
    }
  } else {
    final manager = GameLaunchManager();
    manager.clearEmbeddedPostGameNav();
    GameService.clearLaunchPending();
    manager.onDialogDisposed();
    // Embedded play pops the launch overlay before the game route opens; popping
    // again here would remove the home route and leave a black screen.
    if (context.mounted &&
        !manager.embeddedLaunchOverlayDismissed &&
        Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (onLaunchFailed != null && context.mounted) {
      await onLaunchFailed(context, result);
    }
  }
}
