import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/global_notification_service.dart';

/// "Clear all" tidies away messages; it must never take a running task's
/// notification with it. Losing one is not cosmetic: [update] is a no-op once
/// the id is gone, so the progress bar never comes back and the completion
/// message never arrives — the task reads as cancelled.
void main() {
  final service = GlobalNotificationService();

  setUp(() => service.notifier.value = []);
  tearDown(() => service.notifier.value = []);

  List<String> ids() => service.notifier.value.map((n) => n.id).toList();

  test('clear all removes finished notifications', () {
    service.show(id: 'done', message: 'Import complete');
    service.dismiss();
    expect(ids(), isEmpty);
  });

  test('clear all keeps a notification that tracks running work', () {
    service.show(
      id: 'scrape',
      message: 'Scraping',
      progress: 0.4,
      ongoing: true,
    );
    service.show(id: 'done', message: 'Import complete');

    service.dismiss();

    expect(ids(), ['scrape']);
    expect(service.notifier.value.single.progress, 0.4);
  });

  test('a kept notification keeps reporting progress and completion', () {
    service.show(
      id: 'scrape',
      message: 'Scraping',
      progress: 0.4,
      ongoing: true,
    );
    service.dismiss();

    service.update(
      id: 'scrape',
      message: 'Scraping',
      progress: 0.8,
      ongoing: true,
    );
    expect(service.notifier.value.single.progress, 0.8);

    service.update(
      id: 'scrape',
      message: 'Scraping complete',
      type: GlobalNotificationType.success,
    );
    final finished = service.notifier.value.single;
    expect(finished.message, 'Scraping complete');
    expect(finished.ongoing, isFalse);

    // Finished, so the next "Clear all" takes it.
    service.dismiss();
    expect(ids(), isEmpty);
  });

  test('an update marks the notification finished unless it opts back in', () {
    service.show(
      id: 'scrape',
      message: 'Scraping',
      progress: 0.4,
      ongoing: true,
    );
    service.update(
      id: 'scrape',
      message: 'Failed',
      type: GlobalNotificationType.error,
    );
    expect(service.notifier.value.single.ongoing, isFalse);
  });

  test('the per-notification close button still removes an ongoing one', () {
    service.show(
      id: 'scrape',
      message: 'Scraping',
      progress: 0.4,
      ongoing: true,
    );
    service.dismiss('scrape');
    expect(ids(), isEmpty);
  });
}
