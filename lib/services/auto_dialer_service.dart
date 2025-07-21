// lib/services/auto_dialer_service.dart - UPDATED WITH DIRECT CALLING
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead_model.dart';
import 'direct_call_service.dart'; // Import the new direct call service

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
  DateTime? _callStartTime;
  
  // Configuration
  int _autoDialDelay = 10; // seconds
  bool _enableAutoRedial = true;
  bool _callConnectionConfirmed = false;
  bool _useDirectCalling = true; // NEW: Enable direct calling
  
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
  
  // Set auto dial delay (5, 10, 15, 20, 30 seconds)
  void setAutoDialDelay(int seconds) {
    _autoDialDelay = seconds;
    _notifyStateChange();
  }
  
  // Enable/disable auto redial
  void setAutoRedialEnabled(bool enabled) {
    _enableAutoRedial = enabled;
    _notifyStateChange();
  }

  // Enable/disable direct calling
  void setDirectCallingEnabled(bool enabled) {
    _useDirectCalling = enabled;
  }
  
  // Start auto dialing session
  Future<void> startAutoDialing(List<Lead> leads, {int startIndex = 0}) async {
    if (leads.isEmpty) {
      _notifyEvent(AutoDialerEvent.error('No leads to dial'));
      return;
    }

    // Check if direct calling is supported and request permissions
    if (_useDirectCalling) {
      final hasPermissions = await DirectCallService.requestCallPermissions();
      if (!hasPermissions) {
        _notifyEvent(AutoDialerEvent.error('Call permissions required for direct calling'));
        return;
      }
    }
    
    _leadQueue = leads;
    _currentIndex = startIndex;
    _isAutoDialing = true;
    _isCallInProgress = false;
    _callConnectionConfirmed = false;
    
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
    _callConnectionConfirmed = false;
    _callStartTime = null;
    _notifyStateChange();
    _notifyEvent(AutoDialerEvent.autoDialingStopped());
  }
  
  // Enhanced call method with direct calling
  Future<bool> makeCall(String phoneNumber) async {
    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      print('Attempting to dial: $cleanNumber');
      
      bool success = false;
      
      if (_useDirectCalling) {
        // Use direct calling (like GoDial, NeoDove)
        success = await DirectCallService.makeDirectCall(cleanNumber);
        print('Direct call result: $success');
      } else {
        // Fallback to regular dialer
        final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri, mode: LaunchMode.externalApplication);
          success = true;
        }
      }
      
      if (success) {
        // Mark call as started
        _callStartTime = DateTime.now();
        _isCallInProgress = true;
        _callConnectionConfirmed = false;
        
        if (_useDirectCalling) {
          // Start monitoring call state for direct calls
          _startCallStateMonitoring();
        } else {
          // Auto-confirm call connection after 3 seconds for regular dialing
          Timer(const Duration(seconds: 3), () {
            if (_isCallInProgress && !_callConnectionConfirmed) {
              confirmCallConnection();
            }
          });
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error making call: $e');
      return false;
    }
  }

  // Monitor call state for direct calls
  void _startCallStateMonitoring() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isCallInProgress) {
        timer.cancel();
        return;
      }

      try {
        final callState = await DirectCallService.getCallState();
        print('Call state: $callState');
        
        if (callState == 'OFFHOOK' && !_callConnectionConfirmed) {
          // Call connected
          confirmCallConnection();
        } else if (callState == 'IDLE' && _callConnectionConfirmed) {
          // Call ended
          _handleCallEnded();
          timer.cancel();
        }
      } catch (e) {
        print('Error monitoring call state: $e');
      }
    });
  }

  // Handle call ended
  void _handleCallEnded() {
    if (_isCallInProgress) {
      _isCallInProgress = false;
      _callConnectionConfirmed = false;
      _callStartTime = null;
      _notifyEvent(AutoDialerEvent.callEnded(currentLead!));
      _notifyStateChange();
      
      // Show disposition dialog automatically
      _notifyEvent(AutoDialerEvent.showDispositionDialog(currentLead!));
    }
  }
  
  // Method for user to confirm call connection manually
  void confirmCallConnection() {
    if (_isCallInProgress) {
      _callConnectionConfirmed = true;
      _notifyEvent(AutoDialerEvent.callConnected(currentLead!));
      _notifyStateChange();
    }
  }
  
  // Method for user to report call failed
  void reportCallFailed() {
    if (_isCallInProgress) {
      _isCallInProgress = false;
      _callConnectionConfirmed = false;
      _callStartTime = null;
      _notifyEvent(AutoDialerEvent.dialingFailed(currentLead!));
      
      // Auto-skip failed calls after a short delay
      if (_enableAutoRedial) {
        Timer(const Duration(seconds: 2), () {
          onDispositionSaved();
        });
      }
      
      _notifyStateChange();
    }
  }
  
  // Called when disposition is saved (triggers next call in auto mode)
  Future<void> onDispositionSaved() async {
    if (!_isAutoDialing) return;
    
    _isCallInProgress = false;
    _callConnectionConfirmed = false;
    _callStartTime = null;
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
  
  // Get call duration
  Duration? getCallDuration() {
    if (_callStartTime != null) {
      return DateTime.now().difference(_callStartTime!);
    }
    return null;
  }
  
  // Internal method to dial current lead
  Future<void> _dialCurrentLead() async {
    if (_currentIndex >= _leadQueue.length || !_isAutoDialing) return;
    
    final lead = _leadQueue[_currentIndex];
    _notifyStateChange();
    
    _notifyEvent(AutoDialerEvent.dialingStarted(lead));
    
    try {
      final success = await makeCall(lead.phone);
      if (!success) {
        _notifyEvent(AutoDialerEvent.dialingFailed(lead));
        // Auto-skip failed calls after a short delay
        Timer(const Duration(seconds: 2), () {
          onDispositionSaved();
        });
      }
      // If successful, the call state is managed by the makeCall method
    } catch (e) {
      _notifyEvent(AutoDialerEvent.dialingFailed(lead));
      Timer(const Duration(seconds: 2), () {
        onDispositionSaved();
      });
    }
  }
  
  // Clean phone number for dialing
  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Ensure US numbers start with country code if they don't have one
    if (cleaned.length == 10 && !cleaned.startsWith('+')) {
      cleaned = '+1$cleaned';
    }
    
    return cleaned;
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
      callConnectionConfirmed: _callConnectionConfirmed,
      callDuration: getCallDuration(),
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
  
  // Dispose resources
  void dispose() {
    _autoDialTimer?.cancel();
    _eventController.close();
    _stateController.close();
  }
}

// Enhanced Auto Dialer State
class AutoDialerState {
  final bool isActive;
  final bool isCallInProgress;
  final Lead? currentLead;
  final int currentIndex;
  final int totalLeads;
  final int remainingLeads;
  final int autoDialDelay;
  final bool autoRedialEnabled;
  final bool callConnectionConfirmed;
  final Duration? callDuration;
  
  AutoDialerState({
    required this.isActive,
    required this.isCallInProgress,
    this.currentLead,
    required this.currentIndex,
    required this.totalLeads,
    required this.remainingLeads,
    required this.autoDialDelay,
    required this.autoRedialEnabled,
    required this.callConnectionConfirmed,
    this.callDuration,
  });
  
  double get progress => totalLeads > 0 ? currentIndex / totalLeads : 0.0;
}

// Auto Dialer Events - Enhanced with new events
abstract class AutoDialerEvent {
  const AutoDialerEvent();
  
  factory AutoDialerEvent.autoDialingStarted() = AutoDialingStarted;
  factory AutoDialerEvent.autoDialingStopped() = AutoDialingStopped;
  factory AutoDialerEvent.dialingStarted(Lead lead) = DialingStarted;
  factory AutoDialerEvent.callConnected(Lead lead) = CallConnected;
  factory AutoDialerEvent.callEnded(Lead lead) = CallEnded; // NEW
  factory AutoDialerEvent.dialingFailed(Lead lead) = DialingFailed;
  factory AutoDialerEvent.leadSkipped(Lead lead) = LeadSkipped;
  factory AutoDialerEvent.preparingNextCall(int delay) = PreparingNextCall;
  factory AutoDialerEvent.waitingForManualDial() = WaitingForManualDial;
  factory AutoDialerEvent.allLeadsCompleted() = AllLeadsCompleted;
  factory AutoDialerEvent.showDispositionDialog(Lead lead) = ShowDispositionDialog; // NEW
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

class CallEnded extends AutoDialerEvent {
  final Lead lead;
  const CallEnded(this.lead);
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

class ShowDispositionDialog extends AutoDialerEvent {
  final Lead lead;
  const ShowDispositionDialog(this.lead);
}

class AutoDialerError extends AutoDialerEvent {
  final String message;
  const AutoDialerError(this.message);
}