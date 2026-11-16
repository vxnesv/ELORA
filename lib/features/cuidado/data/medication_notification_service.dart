import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/domain/contexto_cuidado.dart';

class MedicationNotificationService {
  MedicationNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  bool get _supported =>
      !kIsWeb &&
      const {
        TargetPlatform.android,
        TargetPlatform.iOS,
      }.contains(defaultTargetPlatform);

  Future<bool> requestPermission() async {
    if (!_supported || !await _initialize()) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: false, sound: true) ??
        false;
  }

  Future<bool> scheduleDaily(
    MedicamentoAgendado medication, {
    bool startTomorrow = false,
  }) async {
    if (!_supported || !await _initialize()) return false;
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      medication.horarioMinutos ~/ 60,
      medication.horarioMinutos % 60,
    );
    if (startTomorrow || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      medication.notificationId,
      'Lembrete de cuidado',
      'Abra a ELORA para conferir seu lembrete programado.',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'elora_medication_reminders',
          'Lembretes de cuidado',
          channelDescription: 'Horários configurados voluntariamente na ELORA',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  Future<void> cancel(MedicamentoAgendado medication) async {
    if (!_supported || !await _initialize()) return;
    await _plugin.cancel(medication.notificationId);
  }

  Future<bool> _initialize() async {
    if (_initialized) return true;
    try {
      tz.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
      _initialized =
          await _plugin.initialize(
            const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
            ),
          ) ??
          false;
      return _initialized;
    } catch (_) {
      return false;
    }
  }
}
