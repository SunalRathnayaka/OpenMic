// lib/services/permission_service.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:logger/logger.dart';

class PermissionService {
  final Logger _logger = Logger();

  Future<bool> initializeWithPermissions() async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _logger.w('Microphone permission denied');
        return false;
      }

      if (Platform.isAndroid) {
        // Request all necessary Android permissions
        final permissions = await Future.wait([
          Permission.ignoreBatteryOptimizations.request(),
          Permission.notification.request(), // Required for foreground service
          Permission.systemAlertWindow
              .request(), // For showing overlays in background
        ]);

        if (permissions.any((status) => !status.isGranted)) {
          _logger.w('Some Android permissions were denied');
          // Continue anyway as not all permissions are critical
        }
      }

      // Check for permanent denials
      if (await Permission.microphone.isPermanentlyDenied) {
        _logger.w('Microphone permission permanently denied');
        return false;
      }

      _logger.i('Permissions initialized successfully');
      return true;
    } catch (e) {
      _logger.e('Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> enableBackgroundMode() async {
    try {
      // Enable wakelock
      await WakelockPlus.enable();
      _logger.i('Wakelock enabled');

      // Android-specific optimizations
      if (Platform.isAndroid) {
        // Request ignore battery optimizations
        if (!await Permission.ignoreBatteryOptimizations.isGranted) {
          final status = await Permission.ignoreBatteryOptimizations.request();
          _logger.i(
            'Battery optimization permission ${status.isGranted ? "granted" : "denied"}',
          );
        }
      }

      _logger.i('Background mode enabled');
    } catch (e) {
      _logger.e('Error enabling background mode: $e');
      rethrow;
    }
  }

  Future<void> disableBackgroundMode() async {
    try {
      await WakelockPlus.disable();
      _logger.i('Background mode disabled');
    } catch (e) {
      _logger.e('Error disabling background mode: $e');
      rethrow;
    }
  }

  Future<Map<String, bool>> checkAllPermissions() async {
    try {
      final Map<String, bool> permissions = {
        'microphone': await Permission.microphone.isGranted,
        'batteryOptimization':
            await Permission.ignoreBatteryOptimizations.isGranted,
      };

      if (Platform.isAndroid) {
        permissions.addAll({
          'notification': await Permission.notification.isGranted,
          'systemAlertWindow': await Permission.systemAlertWindow.isGranted,
        });
      }

      return permissions;
    } catch (e) {
      _logger.e('Error checking permissions: $e');
      return {'error': false};
    }
  }
}
