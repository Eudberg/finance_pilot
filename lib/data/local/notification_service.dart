import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'cycle_reminders_channel';
  static const String _channelName = 'Cycle Reminders';
  static const String _channelDescription = 'Lembretes do ciclo financeiro';
  static const String _cyclePayloadPrefix = 'cycle_reminder_';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    _setLocalTimeZoneFromOffset();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_notify');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> scheduleCycleReminders({required bool enabled}) async {
    if (!_initialized) {
      await init();
    }

    await _cancelCycleNotifications();

    if (!enabled) {
      return;
    }

    final DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final DateTime monthRef = DateTime(now.year, now.month + i, 1);

      final DateTime advanceDate = DateTime(
        monthRef.year,
        monthRef.month,
        20,
        9,
      );
      if (advanceDate.isAfter(now)) {
        await _scheduleMonthlyReminder(
          id: _buildNotificationId(monthRef.year, monthRef.month, true),
          date: advanceDate,
          body: 'Caiu adiantamento: abra o checklist',
          payload: '${_cyclePayloadPrefix}day20',
        );
      }

      final DateTime settlementBase =
          calculateFifthBusinessDay(monthRef.year, monthRef.month);
      final DateTime settlementDate = DateTime(
        settlementBase.year,
        settlementBase.month,
        settlementBase.day,
        9,
      );
      if (settlementDate.isAfter(now)) {
        await _scheduleMonthlyReminder(
          id: _buildNotificationId(monthRef.year, monthRef.month, false),
          date: settlementDate,
          body: 'Caiu acerto: abra o checklist',
          payload: '${_cyclePayloadPrefix}day5',
        );
      }
    }
  }

  int _buildNotificationId(int year, int month, bool day20) {
    final int base = day20 ? 20000 : 30000;
    return base + ((year % 100) * 100) + month;
  }

  Future<void> _scheduleMonthlyReminder({
    required int id,
    required DateTime date,
    required String body,
    required String payload,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: 'Finance Pilot',
      body: body,
      scheduledDate: tz.TZDateTime.from(date, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> _cancelCycleNotifications() async {
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    for (final PendingNotificationRequest notification in pending) {
      if (notification.payload?.startsWith(_cyclePayloadPrefix) ?? false) {
        await _plugin.cancel(id: notification.id);
      }
    }
  }

  void _setLocalTimeZoneFromOffset() {
    if (kIsWeb) {
      return;
    }

    final Duration offset = DateTime.now().timeZoneOffset;
    final int offsetMs = offset.inMilliseconds;
    final tz.Location customLocation = tz.Location(
      'local_offset',
      <int>[tz.minTime],
      <int>[0],
      <tz.TimeZone>[
        tz.TimeZone(
          offsetMs,
          isDst: false,
          abbreviation: DateTime.now().timeZoneName,
        ),
      ],
    );
    tz.setLocalLocation(customLocation);
  }
}

DateTime calculateFifthBusinessDay(int year, int month) {
  int businessDays = 0;
  for (int day = 1; day <= 31; day++) {
    final DateTime date = DateTime(year, month, day);
    if (date.month != month) {
      break;
    }
    final bool isBusinessDay = date.weekday != DateTime.sunday;
    if (!isBusinessDay) {
      continue;
    }
    businessDays++;
    if (businessDays == 5) {
      return date;
    }
  }
  return DateTime(year, month, 6);
}
