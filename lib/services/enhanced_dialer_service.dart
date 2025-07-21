// lib/services/enhanced_dialer_service.dart - REPLACE auto_dialer_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead_model.dart';

class AutoDialerService {
  static final AutoDialerService _instance = AutoDialerService._internal();
  factory AutoDialerService() => _instance;
  AutoDialerService._internal();

  // Auto dialer state
  List<Lead> _leadQueue = [];
  int _currentIndex = 0;
  bool _isAutoDialing = false;
  bool _isCallInProgress = false;
  Timer? _autoDialTimer;
  
  // Configuration
  int _autoDialDelay = 10; // seconds
  bool _enableAutoRedial = true;
  bool _simulateDirectDial = true; // For testing purposes
  
  // Stream controllers for events
  final StreamController<AutoDialerEvent> _eventController = StreamController.broadcast();
  final StreamController<AutoDialerState> _stateController = StreamController.broadcast();
  
  // Getters
  Stream<AutoDialerEvent> get eventStream => _eventController.stream;
  Stream<AutoDialerState> get stateStream => _stateController.stream;
  bool get isAutoDialing => _isAutoDialing;
  bool get isCallInProgress => _isCallInProgress;
  Lead? get currentLead => _currentIndex < _leadQueue.length ? _leadQueue[_currentIndex] : null;
  int get remainingLeads => _leadQueue.length - _currentIndex;
  int get autoDialDelay => _autoDialDelay;
  
  // Set auto dial delay (10, 20, 30 seconds)
  void setAutoDialDelay(int seconds) {
    _autoDialDelay = seconds;
    _notifyStateChange();
  }
  
  // Enable/disable auto redial
  void setAutoRedialEnabled(bool enabled) {
    _enableAutoRedial = enabled;
    _notifyStateChange();
  }
  
  // Start auto dialing session
  Future<void> startAutoDialing(List<Lead> leads, {int startIndex = 0}) async {
    if (leads.isEmpty) {
      _notifyEvent(AutoDialerEvent.error('No leads to dial'));
      return;
    }
    
    _leadQueue = leads;
    _currentIndex = startIndex;
    _isAutoDialing = true;
    _isCallInProgress = false;
    
    _notifyStateChange();
    _notifyEvent(AutoDialerEvent.autoDialingStarted());
    
    // Start dialing immediately
    await _dialCurrentLead();
  }
  
  // Stop auto dialing
  void stopAutoDialing() {
    _autoDialTimer?.cancel();
    _isAutoDialing = false;
    _isCallInProgress = false;
    _notifyStateChange();
    _notifyEvent(AutoDialerEvent.autoDialingStopped());
  }
  
  // Enhanced call method with direct dialing simulation
  Future<bool> makeCall(String phoneNumber) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      
      if (_simulateDirectDial) {
        // For auto-dialer mode: simulate direct dialing
        await _simulateDirectDialing(cleanNumber);
        return true;
      } else {
        // For manual calls: open native dialer
        final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);
        
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
          return true;
        }
        return false;
      }
    } catch (e) {
      print('Error making call: $e');
      return false;
    }
  }
  
  // Simulate direct dialing for auto-dialer
  Future<void> _simulateDirectDialing(String phoneNumber) async {
    print('🔄 Auto-dialing: $phoneNumber');
    
    // Simulate dialing process
    await Future.delayed(const Duration(milliseconds: 500));
    print('📞 Connecting to $phoneNumber...');
    
    // Simulate connection delay (1-3 seconds)
    await Future.delayed(Duration(seconds: 1 + (DateTime.now().millisecond % 3)));
    
    // Simulate call outcome (85% success rate for demo)
    final isSuccess = DateTime.now().millisecond % 100 < 85;
    
    if (isSuccess) {
      print('✅ Call connected to $phoneNumber');
      // You can add platform-specific code here to actually make the call
      // For Android: Use method channels to invoke native dialing
      // For iOS: Use CallKit framework
    } else {
      print('❌ Call failed to $phoneNumber');
      throw Exception('Call connection failed');
    }
  }
  
  // Platform-specific direct dialing (placeholder for future implementation)
  Future<bool> _makeDirectCall(String phoneNumber) async {
    try {
      // For Android: Use method channel to call TelecomManager
      // For iOS: Use CallKit
      
      const platform = MethodChannel('telecrm/dialer');
      
      final result = await platform.invokeMethod('makeDirectCall', {
        'phoneNumber': phoneNumber,
      });
      
      return result == true;
    } catch (e) {
      print('Direct call failed, falling back to URL launcher: $e');
      // Fallback to URL launcher if direct call fails
      return await _makeCallWithUrlLauncher(phoneNumber);
    }
  }
  
  // Fallback method using URL launcher
  Future<bool> _makeCallWithUrlLauncher(String phoneNumber) async {
    try {
      final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('URL launcher call failed: $e');
      return false;
    }
  }
  
  // Called when disposition is saved (triggers next call in auto mode)
  Future<void> onDispositionSaved() async {
    if (!_isAutoDialing) return;
    
    _isCallInProgress = false;
    _currentIndex++;
    
    // Check if we have more leads
    if (_currentIndex >= _leadQueue.length) {
      // All leads completed
      _notifyEvent(AutoDialerEvent.allLeadsCompleted());
      stopAutoDialing();
      return;
    }
    
    _notifyStateChange();
    
    if (_enableAutoRedial) {
      // Auto dial next lead after delay
      _notifyEvent(AutoDialerEvent.preparingNextCall(_autoDialDelay));
      
      _autoDialTimer = Timer(Duration(seconds: _autoDialDelay), () {
        _dialCurrentLead();
      });
    } else {
      // Wait for manual trigger
      _notifyEvent(AutoDialerEvent.waitingForManualDial());
    }
  }
  
  // Skip current lead
  Future<void> skipCurrentLead() async {
    if (!_isAutoDialing || currentLead == null) return;
    
    _notifyEvent(AutoDialerEvent.leadSkipped(currentLead!));
    await onDispositionSaved(); // This will move to next lead
  }
  
  // Force dial current lead (manual trigger)
  Future<void> dialCurrentLead() async {
    _autoDialTimer?.cancel();
    await _dialCurrentLead();
  }
  
  // Internal method to dial current lead
  Future<void> _dialCurrentLead() async {
    if (_currentIndex >= _leadQueue.length || !_isAutoDialing) return;
    
    final lead = _leadQueue[_currentIndex];
    _isCallInProgress = true;
    _simulateDirectDial = true; // Enable direct dialing for auto mode
    _notifyStateChange();
    
    _notifyEvent(AutoDialerEvent.dialingStarted(lead));
    
    try {
      final success = await makeCall(lead.phone);
      if (success) {
        _notifyEvent(AutoDialerEvent.callConnected(lead));
      } else {
        _notifyEvent(AutoDialerEvent.dialingFailed(lead));
        // Auto-skip failed calls after a short delay
        Timer(const Duration(seconds: 2), () {
          onDispositionSaved();
        });
      }
    } catch (e) {
      _notifyEvent(AutoDialerEvent.dialingFailed(lead));
      Timer(const Duration(seconds: 2), () {
        onDispositionSaved();
      });
    }
  }
  
  // Manual call (for leads screen) - uses native dialer
  Future<bool> makeManualCall(String phoneNumber) async {
    _simulateDirectDial = false; // Disable direct dialing for manual calls
    return await makeCall(phoneNumber);
  }
  
  // Clean phone number for dialing
  String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }
  
  // Notify state change
  void _notifyStateChange() {
    _stateController.add(AutoDialerState(
      isActive: _isAutoDialing,
      isCallInProgress: _isCallInProgress,
      currentLead: currentLead,
      currentIndex: _currentIndex,
      totalLeads: _leadQueue.length,
      remainingLeads: remainingLeads,
      autoDialDelay: _autoDialDelay,
      autoRedialEnabled: _enableAutoRedial,
    ));
  }
  
  // Notify event
  void _notifyEvent(AutoDialerEvent event) {
    _eventController.add(event);
  }
  
  // Get progress percentage
  double getProgress() {
    if (_leadQueue.isEmpty) return 0.0;
    return _currentIndex / _leadQueue.length;
  }
  
  // Configure dialing mode
  void setDialingMode({required bool directDial}) {
    _simulateDirectDial = directDial;
  }
  
  // Dispose resources
  void dispose() {
    _autoDialTimer?.cancel();
    _eventController.close();
    _stateController.close();
  }
}

// Auto Dialer State
class AutoDialerState {
  final bool isActive;
  final bool isCallInProgress;
  final Lead? currentLead;
  final int currentIndex;
  final int totalLeads;
  final int remainingLeads;
  final int autoDialDelay;
  final bool autoRedialEnabled;
  
  AutoDialerState({
    required this.isActive,
    required this.isCallInProgress,
    this.currentLead,
    required this.currentIndex,
    required this.totalLeads,
    required this.remainingLeads,
    required this.autoDialDelay,
    required this.autoRedialEnabled,
  });
  
  double get progress => totalLeads > 0 ? currentIndex / totalLeads : 0.0;
}

// Auto Dialer Events - Made public for external access
abstract class AutoDialerEvent {
  const AutoDialerEvent();
  
  factory AutoDialerEvent.autoDialingStarted() = AutoDialingStarted;
  factory AutoDialerEvent.autoDialingStopped() = AutoDialingStopped;
  factory AutoDialerEvent.dialingStarted(Lead lead) = DialingStarted;
  factory AutoDialerEvent.callConnected(Lead lead) = CallConnected;
  factory AutoDialerEvent.dialingFailed(Lead lead) = DialingFailed;
  factory AutoDialerEvent.leadSkipped(Lead lead) = LeadSkipped;
  factory AutoDialerEvent.preparingNextCall(int delay) = PreparingNextCall;
  factory AutoDialerEvent.waitingForManualDial() = WaitingForManualDial;
  factory AutoDialerEvent.allLeadsCompleted() = AllLeadsCompleted;
  factory AutoDialerEvent.error(String message) = AutoDialerError;
}

class AutoDialingStarted extends AutoDialerEvent {
  const AutoDialingStarted();
}

class AutoDialingStopped extends AutoDialerEvent {
  const AutoDialingStopped();
}

class DialingStarted extends AutoDialerEvent {
  final Lead lead;
  const DialingStarted(this.lead);
}

class CallConnected extends AutoDialerEvent {
  final Lead lead;
  const CallConnected(this.lead);
}

class DialingFailed extends AutoDialerEvent {
  final Lead lead;
  const DialingFailed(this.lead);
}

class LeadSkipped extends AutoDialerEvent {
  final Lead lead;
  const LeadSkipped(this.lead);
}

class PreparingNextCall extends AutoDialerEvent {
  final int delay;
  const PreparingNextCall(this.delay);
}

class WaitingForManualDial extends AutoDialerEvent {
  const WaitingForManualDial();
}

class AllLeadsCompleted extends AutoDialerEvent {
  const AllLeadsCompleted();
}

class AutoDialerError extends AutoDialerEvent {
  final String message;
  const AutoDialerError(this.message);
}