import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_constellation/services/reminder_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'reminder_service_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin])
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ReminderService setEnabled cancels when disabled', (WidgetTester tester) async {
    await TestWidgetsFlutterBinding.ensureInitialized();
    final mockPlugin = MockFlutterLocalNotificationsPlugin();
    final service = ReminderService(plugin: mockPlugin);
    await service.setEnabled(false);
    verify(mockPlugin.cancelAll()).called(1);
  });

  testWidgets('ReminderService default time is 16:00', (WidgetTester tester) async {
    await TestWidgetsFlutterBinding.ensureInitialized();
    final service = ReminderService();
    final (h, m) = await service.scheduledTime;
    expect(h, 16);
    expect(m, 0);
  });

  testWidgets('ReminderService snooze calls zonedSchedule', (WidgetTester tester) async {
    await TestWidgetsFlutterBinding.ensureInitialized();
    tz_data.initializeTimeZones();
    final mockPlugin = MockFlutterLocalNotificationsPlugin();
    final service = ReminderService(plugin: mockPlugin);
    await service.snooze();
    verify(mockPlugin.zonedSchedule(
      id: 1,
      title: anyNamed('title'),
      body: anyNamed('body'),
      scheduledDate: anyNamed('scheduledDate'),
      notificationDetails: anyNamed('notificationDetails'),
      androidScheduleMode: anyNamed('androidScheduleMode'),
    )).called(1);
  });
}
