import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/gamepad/gamepad_navigation_manager.dart';
import 'package:omisu/services/global_notification_service.dart';
import 'package:omisu/themes/corner_radii.dart';
import 'package:omisu/utils/gamepad_nav.dart';
import 'package:omisu/widgets/notification_bell.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The bell is the only surface for notifications and sits in no screen's own
/// navigation order, so a controller could never reach it: Select opens it from
/// anywhere the header is on screen, and the popup then owns input until B (or
/// another Select tap) closes it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await FlutterLocalization.instance.ensureInitialized();
    FlutterLocalization.instance.init(
      mapLocales: [MapLocale('en', AppLocale.en)],
      initLanguageCode: 'en',
    );
  });

  tearDown(() {
    GlobalNotificationService().notifier.value = [];
    GamepadNavigation.globalSelectTap = null;
  });

  Future<void> pumpBell(WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1920, 1080)),
        child: ScreenUtilInit(
          designSize: const Size(1920, 1080),
          builder: (context, child) => MaterialApp(
            localizationsDelegates:
                FlutterLocalization.instance.localizationsDelegates,
            supportedLocales: FlutterLocalization.instance.supportedLocales,
            theme: ThemeData(
              extensions: <ThemeExtension<dynamic>>[CornerRadii.m()],
            ),
            home: const Scaffold(body: Center(child: NotificationBell())),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  bool isOpen() =>
      find.text('Clear all').evaluate().isNotEmpty ||
      find.text('No active notifications').evaluate().isNotEmpty;

  testWidgets('a mounted bell claims the app-wide Select tap', (tester) async {
    await pumpBell(tester);
    expect(GamepadNavigation.globalSelectTap, isNotNull);
  });

  testWidgets('the Select tap opens the popup, and a second one closes it', (
    tester,
  ) async {
    GlobalNotificationService().show(id: 'done', message: 'Import complete');
    await pumpBell(tester);
    expect(isOpen(), isFalse);

    GamepadNavigation.globalSelectTap!();
    await tester.pump();
    expect(isOpen(), isTrue);

    // On the device the second tap reaches the popup's own layer, which binds
    // Select to close; the bell's hook toggles for the same reason, so either
    // route ends with the popup shut.
    GamepadNavigation.globalSelectTap!();
    await tester.pump();
    expect(isOpen(), isFalse);
  });

  testWidgets('an empty bell still opens, so Select always answers', (
    tester,
  ) async {
    await pumpBell(tester);

    GamepadNavigation.globalSelectTap!();
    await tester.pump();

    expect(find.text('No active notifications'), findsOneWidget);
  });

  testWidgets('the open popup takes input from the screen underneath it', (
    tester,
  ) async {
    final events = <String>[];
    GamepadNavigationManager.pushLayer(
      'test_app_screen',
      onActivate: () => events.add('+app'),
      onDeactivate: () => events.add('-app'),
    );
    addTearDown(() => GamepadNavigationManager.popLayer('test_app_screen'));

    GlobalNotificationService().show(id: 'done', message: 'Import complete');
    await pumpBell(tester);
    events.clear();

    GamepadNavigation.globalSelectTap!();
    // The layer is pushed in a post-frame callback, like every other screen's.
    await tester.pump();
    await tester.pump();
    expect(events, ['-app'], reason: 'the popup must own the controller');

    GamepadNavigation.globalSelectTap!();
    await tester.pump();
    await tester.pump();
    expect(events, ['-app', '+app'], reason: 'closing hands input back');
  });

  testWidgets('the bell releases the Select tap when it leaves the tree', (
    tester,
  ) async {
    await pumpBell(tester);
    expect(GamepadNavigation.globalSelectTap, isNotNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(GamepadNavigation.globalSelectTap, isNull);
  });
}
