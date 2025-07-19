// lib/services/dialer_service.dart
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead_model.dart';

class DialerService {
  static final DialerService _instance = DialerService._internal();
  factory DialerService() => _instance;
  DialerService._internal();

  // Make a phone call
  Future<bool> makeCall(String phoneNumber) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create tel URL
      final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);
      
      // Check if can launch
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        return true;
      } else {
        throw Exception('Cannot launch dialer');
      }
    } catch (e) {
      print('Error making call: $e');
      return false;
    }
  }

  // Copy phone number to clipboard
  Future<void> copyToClipboard(String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
  }

  // Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return cleanNumber.isNotEmpty && cleanNumber.length >= 10;
  }

  // Format phone number for display
  String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanNumber.length == 10) {
      // Format as (XXX) XXX-XXXX
      return '(${cleanNumber.substring(0, 3)}) ${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6)}';
    } else if (cleanNumber.length == 11 && cleanNumber.startsWith('1')) {
      // Format as +1 (XXX) XXX-XXXX
      return '+1 (${cleanNumber.substring(1, 4)}) ${cleanNumber.substring(4, 7)}-${cleanNumber.substring(7)}';
    }
    
    return phoneNumber; // Return original if can't format
  }
}

// Auto Dialer Service for sequential calling
class AutoDialerService {
  static final AutoDialerService _instance = AutoDialerService._internal();
  factory AutoDialerService() => _instance;
  AutoDialerService._internal();

  final DialerService _dialerService = DialerService();
  
  List<Lead> _leadQueue = [];
  int _currentIndex = 0;
  bool _isAutoDialing = false;
  DateTime? _callStartTime;
  
  // Stream controllers for auto dialer state
  final List<Function(AutoDialerState)> _stateListeners = [];
  final List<Function(CallEvent)> _callEventListeners = [];
  
  // Getters
  bool get isAutoDialing => _isAutoDialing;
  int get currentIndex => _currentIndex;
  int get remainingLeads => _leadQueue.length - _currentIndex;
  Lead? get currentLead => _currentIndex < _leadQueue.length ? _leadQueue[_currentIndex] : null;
  List<Lead> get leadQueue => List.unmodifiable(_leadQueue);
  
  // Add listeners
  void addStateListener(Function(AutoDialerState) listener) {
    _stateListeners.add(listener);
  }
  
  void addCallEventListener(Function(CallEvent) listener) {
    _callEventListeners.add(listener);
  }
  
  void removeStateListener(Function(AutoDialerState) listener) {
    _stateListeners.remove(listener);
  }
  
  void removeCallEventListener(Function(CallEvent) listener) {
    _callEventListeners.remove(listener);
  }
  
  // Notify listeners
  void _notifyStateListeners(AutoDialerState state) {
    for (final listener in _stateListeners) {
      listener(state);
    }
  }
  
  void _notifyCallEventListeners(CallEvent event) {
    for (final listener in _callEventListeners) {
      listener(event);
    }
  }
  
  // Start auto dialing
  Future<void> startAutoDialing(List<Lead> leads, {int startIndex = 0}) async {
    if (leads.isEmpty) return;
    
    _leadQueue = leads;
    _currentIndex = startIndex;
    _isAutoDialing = true;
    
    _notifyStateListeners(AutoDialerState(
      isActive: true,
      currentLead: currentLead,
      currentIndex: _currentIndex,
      totalLeads: _leadQueue.length,
      remainingLeads: remainingLeads,
    ));
    
    await _dialCurrent();
  }
  
  // Stop auto dialing
  void stopAutoDialing() {
    _isAutoDialing = false;
    _callStartTime = null;
    
    _notifyStateListeners(AutoDialerState(
      isActive: false,
      currentLead: null,
      currentIndex: 0,
      totalLeads: 0,
      remainingLeads: 0,
    ));
    
    _notifyCallEventListeners(CallEvent.autoDialerStopped);
  }
  
  // Move to next lead
  Future<void> nextLead() async {
    if (!_isAutoDialing) return;
    
    _currentIndex++;
    
    if (_currentIndex >= _leadQueue.length) {
      // All leads completed
      _notifyCallEventListeners(CallEvent.queueCompleted);
      stopAutoDialing();
      return;
    }
    
    _notifyStateListeners(AutoDialerState(
      isActive: true,
      currentLead: currentLead,
      currentIndex: _currentIndex,
      totalLeads: _leadQueue.length,
      remainingLeads: remainingLeads,
    ));
    
    // Small delay before next call
    await Future.delayed(const Duration(seconds: 2));
    await _dialCurrent();
  }
  
  // Skip current lead
  Future<void> skipLead() async {
    if (!_isAutoDialing || currentLead == null) return;
    
    _notifyCallEventListeners(CallEvent.leadSkipped);
    await nextLead();
  }
  
  // Mark call as started
  void markCallStarted() {
    _callStartTime = DateTime.now();
    _notifyCallEventListeners(CallEvent.callStarted);
  }
  
  // Mark call as ended
  void markCallEnded() {
    _callStartTime = null;
    _notifyCallEventListeners(CallEvent.callEnded);
  }
  
  // Get call duration
  Duration? getCallDuration() {
    if (_callStartTime != null) {
      return DateTime.now().difference(_callStartTime!);
    }
    return null;
  }
  
  // Private method to dial current lead
  Future<void> _dialCurrent() async {
    if (_currentIndex >= _leadQueue.length || !_isAutoDialing) return;
    
    final lead = _leadQueue[_currentIndex];
    _notifyCallEventListeners(CallEvent.dialingStarted);
    
    // Small delay before dialing
    await Future.delayed(const Duration(seconds: 1));
    
    final success = await _dialerService.makeCall(lead.phone);
    
    if (success) {
      markCallStarted();
    } else {
      _notifyCallEventListeners(CallEvent.dialingFailed);
      // Auto-skip to next lead if dialing failed
      await Future.delayed(const Duration(seconds: 1));
      await nextLead();
    }
  }
  
  // Restart from specific lead
  Future<void> restartFrom(int index) async {
    if (index >= 0 && index < _leadQueue.length) {
      _currentIndex = index;
      if (_isAutoDialing) {
        await _dialCurrent();
      }
    }
  }
  
  // Dispose resources
  void dispose() {
    _stateListeners.clear();
    _callEventListeners.clear();
  }
}

// Auto dialer state class
class AutoDialerState {
  final bool isActive;
  final Lead? currentLead;
  final int currentIndex;
  final int totalLeads;
  final int remainingLeads;
  
  AutoDialerState({
    required this.isActive,
    this.currentLead,
    required this.currentIndex,
    required this.totalLeads,
    required this.remainingLeads,
  });
  
  double get progress => totalLeads > 0 ? (currentIndex / totalLeads) : 0.0;
  double get completionPercentage => totalLeads > 0 ? ((currentIndex / totalLeads) * 100) : 0.0;
}

// Call events enum
enum CallEvent {
  dialingStarted,
  dialingFailed,
  callStarted,
  callEnded,
  leadSkipped,
  autoDialerStopped,
  queueCompleted,
}