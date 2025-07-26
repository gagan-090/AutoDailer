// lib/services/call_completion_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/lead_model.dart';

class CallCompletionService {
  static const MethodChannel _channel = MethodChannel('call_completion_channel');
  
  static StreamController<CallCompletionEvent>? _eventController;
  static Timer? _callMonitorTimer;
  static bool _isMonitoring = false;
  static DateTime? _callStartTime;
  static Lead? _currentCallLead;
  static bool _callWasActive = false;
  
  // Initialize the service
  static Future<void> initialize() async {
    _eventController = StreamController<CallCompletionEvent>.broadcast();
    
    // Set up method call handler for native platform
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCallStateChanged':
          _handleCallStateChange(call.arguments);
          break;
        case 'onCallEnded':
          _handleCallEnded(call.arguments);
          break;
        default:
          break;
      }
    });
  }
  
  // Get the event stream
  static Stream<CallCompletionEvent> get eventStream => 
      _eventController?.stream ?? const Stream.empty();
  
  // Start monitoring a call
  static Future<void> startMonitoringCall(Lead lead) async {
    _currentCallLead = lead;
    _callStartTime = DateTime.now();
    _isMonitoring = true;
    _callWasActive = false;
    
    // Request phone permission if not granted
    if (Platform.isAndroid) {
      final permission = await Permission.phone.request();
      if (!permission.isGranted) {
        _emitEvent(CallCompletionEvent.permissionDenied());
        return;
      }
    }
    
    // Start native call monitoring
    try {
      await _channel.invokeMethod('startCallMonitoring');
    } catch (e) {
      debugPrint('Failed to start native call monitoring: $e');
    }
    
    // Fallback timer-based monitoring
    _startFallbackMonitoring();
    
    _emitEvent(CallCompletionEvent.monitoringStarted(lead));
  }
  
  // Stop monitoring
  static Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _callMonitorTimer?.cancel();
    _callMonitorTimer = null;
    _currentCallLead = null;
    _callStartTime = null;
    _callWasActive = false;
    
    try {
      await _channel.invokeMethod('stopCallMonitoring');
    } catch (e) {
      debugPrint('Failed to stop native call monitoring: $e');
    }
  }
  
  // Manual call completion trigger (fallback button)
  static void manualCallCompletion() {
    if (_currentCallLead != null) {
      final duration = _callStartTime != null 
          ? DateTime.now().difference(_callStartTime!)
          : const Duration(seconds: 30);
      
      _emitEvent(CallCompletionEvent.callCompleted(
        _currentCallLead!,
        duration,
        CallCompletionReason.manual,
      ));
      
      stopMonitoring();
    }
  }
  
  // Handle native call state changes
  static void _handleCallStateChange(dynamic arguments) {
    if (!_isMonitoring) return;
    
    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(arguments);
      final String state = data['state'] ?? '';
      
      switch (state) {
        case 'RINGING':
          _emitEvent(CallCompletionEvent.callRinging(_currentCallLead!));
          break;
        case 'OFFHOOK':
          _callWasActive = true;
          _emitEvent(CallCompletionEvent.callConnected(_currentCallLead!));
          break;
        case 'IDLE':
          if (_callWasActive) {
            _handleCallCompletion(CallCompletionReason.native);
          }
          break;
      }
    } catch (e) {
      debugPrint('Error handling call state change: $e');
    }
  }
  
  // Handle native call ended
  static void _handleCallEnded(dynamic arguments) {
    if (!_isMonitoring) return;
    
    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(arguments);
      final int durationMs = data['duration'] ?? 0;
      final Duration duration = Duration(milliseconds: durationMs);
      
      _handleCallCompletion(CallCompletionReason.native, duration);
    } catch (e) {
      debugPrint('Error handling call ended: $e');
    }
  }
  
  // Start fallback monitoring using timer
  static void _startFallbackMonitoring() {
    _callMonitorTimer?.cancel();
    
    // Check every 2 seconds for app state changes
    _callMonitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      _checkAppForegroundState();
    });
    
    // Auto-trigger after 60 seconds if no native detection
    Timer(const Duration(seconds: 60), () {
      if (_isMonitoring && _currentCallLead != null) {
        _handleCallCompletion(CallCompletionReason.timeout);
      }
    });
  }
  
  // Check if app returned to foreground (indicating call might be ended)
  static void _checkAppForegroundState() {
    // This will be enhanced with AppLifecycleState monitoring
    // For now, we rely on native monitoring and manual trigger
  }
  
  // Handle call completion
  static void _handleCallCompletion(CallCompletionReason reason, [Duration? duration]) {
    if (_currentCallLead == null) return;
    
    final callDuration = duration ?? (_callStartTime != null 
        ? DateTime.now().difference(_callStartTime!)
        : const Duration(seconds: 30));
    
    _emitEvent(CallCompletionEvent.callCompleted(
      _currentCallLead!,
      callDuration,
      reason,
    ));
    
    stopMonitoring();
  }
  
  // Emit event
  static void _emitEvent(CallCompletionEvent event) {
    _eventController?.add(event);
  }
  
  // Dispose resources
  static void dispose() {
    _callMonitorTimer?.cancel();
    _eventController?.close();
    _eventController = null;
  }
}

// Call completion events
abstract class CallCompletionEvent {
  const CallCompletionEvent();
  
  factory CallCompletionEvent.monitoringStarted(Lead lead) = MonitoringStarted;
  factory CallCompletionEvent.callRinging(Lead lead) = CallRinging;
  factory CallCompletionEvent.callConnected(Lead lead) = CallConnected;
  factory CallCompletionEvent.callCompleted(Lead lead, Duration duration, CallCompletionReason reason) = CallCompleted;
  factory CallCompletionEvent.permissionDenied() = PermissionDenied;
  factory CallCompletionEvent.error(String message) = CallCompletionError;
}

class MonitoringStarted extends CallCompletionEvent {
  final Lead lead;
  const MonitoringStarted(this.lead);
}

class CallRinging extends CallCompletionEvent {
  final Lead lead;
  const CallRinging(this.lead);
}

class CallConnected extends CallCompletionEvent {
  final Lead lead;
  const CallConnected(this.lead);
}

class CallCompleted extends CallCompletionEvent {
  final Lead lead;
  final Duration duration;
  final CallCompletionReason reason;
  const CallCompleted(this.lead, this.duration, this.reason);
}

class PermissionDenied extends CallCompletionEvent {
  const PermissionDenied();
}

class CallCompletionError extends CallCompletionEvent {
  final String message;
  const CallCompletionError(this.message);
}

// Reason for call completion detection
enum CallCompletionReason {
  native,    // Detected by native platform
  manual,    // Manually triggered by user
  timeout,   // Auto-triggered after timeout
  appResume, // Detected when app resumed
}