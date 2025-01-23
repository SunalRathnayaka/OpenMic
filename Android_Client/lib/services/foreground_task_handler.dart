// lib/services/foreground_task_handler.dart
import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logger/logger.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AudioForegroundTaskHandler());
}

class AudioForegroundTaskHandler extends TaskHandler {
  final Logger _logger = Logger();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      _logger.i('Foreground task started');
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Audio Broadcasting',
        notificationText: 'Broadcasting in background...',
      );
    } catch (e) {
      _logger.e('Error in onStart: $e');
    }
  }

  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    try {
      _logger.d('Foreground task event triggered');
    } catch (e) {
      _logger.e('Error in onEvent: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    try {
      _logger.i('Foreground task destroyed');
    } catch (e) {
      _logger.e('Error in onDestroy: $e');
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    try {
      _logger.d('Repeat event triggered');
      // Add any periodic task logic here that needs to run repeatedly
      // This is called based on the interval set in foregroundTaskOptions
    } catch (e) {
      _logger.e('Error in onRepeatEvent: $e');
    }
  }

  Future<void> onButtonPressed(String id) async {
    try {
      _logger.i('Notification button pressed: $id');
      if (id == 'stopBroadcast') {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      _logger.e('Error in onButtonPressed: $e');
    }
  }

  @override
  void onNotificationPressed() {
    // Handle notification tap
    _logger.i('Notification pressed');
  }
}

class ForegroundServiceManager {
  final Logger _logger = Logger();

  Future<void> initForegroundTask() async {
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'audio_broadcast_channel',
          channelName: 'Audio Broadcast Service',
          channelDescription: 'Running audio broadcast in background',
          priority: NotificationPriority.HIGH,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(1000),
          autoRunOnBoot: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
    } catch (e) {
      _logger.e('Error initializing foreground task: $e');
      rethrow;
    }
  }

  Future<void> startForegroundService() async {
    try {
      // Check for system overlay permission
      if (!await FlutterForegroundTask.canDrawOverlays) {
        final isGranted =
            await FlutterForegroundTask.openSystemAlertWindowSettings();
        if (!isGranted) {
          _logger.e('Overlay permission not granted');
          return;
        }
      }

      // Start foreground service
      await FlutterForegroundTask.startService(
        notificationTitle: 'Audio Broadcasting',
        notificationText: 'Initializing broadcast...',
        callback: startCallback,
      );

      _logger.i('Foreground service started successfully');
    } catch (e) {
      _logger.e('Failed to start foreground service: $e');
      rethrow;
    }
  }

  Future<void> stopForegroundService() async {
    try {
      await FlutterForegroundTask.stopService();
      _logger.i('Foreground service stopped');
    } catch (e) {
      _logger.e('Error stopping foreground service: $e');
      rethrow;
    }
  }
}
