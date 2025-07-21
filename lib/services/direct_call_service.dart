import 'package:flutter/services.dart';

class DirectCallService {
  static const MethodChannel _channel = MethodChannel('telecrm/direct_call');

  static Future<bool> makeDirectCall(String phoneNumber) async {
    try {
      final bool result = await _channel.invokeMethod('makeDirectCall', {
        'phoneNumber': phoneNumber,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to make direct call: '${e.message}'");
      return false;
    }
  }

  static Future<bool> requestCallPermissions() async {
    try {
      final bool result = await _channel.invokeMethod('requestCallPermissions');
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getCallState() async {
    try {
      return await _channel.invokeMethod('getCallState');
    } catch (_) {
      return 'UNKNOWN';
    }
  }
}
