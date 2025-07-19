// lib/providers/call_provider.dart
import 'package:flutter/material.dart';
import '../models/lead_model.dart';
import '../services/dialer_service.dart';
import '../services/lead_service.dart';

class CallProvider with ChangeNotifier {
  final AutoDialerService _autoDialerService = AutoDialerService();
  final LeadService _leadService = LeadService();

  // Current call state
  AutoDialerState _autoDialerState = AutoDialerState(
    isActive: false,
    currentLead: null,
    currentIndex: 0,
    totalLeads: 0,
    remainingLeads: 0,
  );
  
  CallEvent? _lastCallEvent;
  bool _showingDispositionDialog = false;
  DateTime? _callStartTime;
  String? _errorMessage;

  // Getters
  AutoDialerState get autoDialerState => _autoDialerState;
  CallEvent? get lastCallEvent => _lastCallEvent;
  bool get showingDispositionDialog => _showingDispositionDialog;
  DateTime? get callStartTime => _callStartTime;
  String? get errorMessage => _errorMessage;
  
  bool get isAutoDialing => _autoDialerState.isActive;
  Lead? get currentLead => _autoDialerState.currentLead;
  int get remainingLeads => _autoDialerState.remainingLeads;
  double get progress => _autoDialerState.progress;

  CallProvider() {
    // Listen to auto dialer events
    _autoDialerService.addStateListener(_onAutoDialerStateChanged);
    _autoDialerService.addCallEventListener(_onCallEvent);
  }

  @override
  void dispose() {
    _autoDialerService.removeStateListener(_onAutoDialerStateChanged);
    _autoDialerService.removeCallEventListener(_onCallEvent);
    super.dispose();
  }

  // Handle auto dialer state changes
  void _onAutoDialerStateChanged(AutoDialerState state) {
    _autoDialerState = state;
    notifyListeners();
  }

  // Handle call events
  void _onCallEvent(CallEvent event) {
    _lastCallEvent = event;
    
    switch (event) {
      case CallEvent.callStarted:
        _callStartTime = DateTime.now();
        break;
      case CallEvent.callEnded:
        _callStartTime = null;
        // Show disposition dialog after call ends
        if (currentLead != null && !_showingDispositionDialog) {
          _showingDispositionDialog = true;
        }
        break;
      case CallEvent.dialingFailed:
        _errorMessage = 'Failed to dial ${currentLead?.phone}';
        break;
      case CallEvent.autoDialerStopped:
      case CallEvent.queueCompleted:
        _callStartTime = null;
        _showingDispositionDialog = false;
        break;
      default:
        break;
    }
    
    notifyListeners();
  }

  // Start auto dialing with leads
  Future<void> startAutoDialing(List<Lead> leads, {int startIndex = 0}) async {
    try {
      _errorMessage = null;
      await _autoDialerService.startAutoDialing(leads, startIndex: startIndex);
    } catch (e) {
      _errorMessage = 'Failed to start auto dialing: $e';
      notifyListeners();
    }
  }

  // Stop auto dialing
  void stopAutoDialing() {
    _autoDialerService.stopAutoDialing();
    _showingDispositionDialog = false;
    _callStartTime = null;
    notifyListeners();
  }

  // Move to next lead
  Future<void> nextLead() async {
    await _autoDialerService.nextLead();
  }

  // Skip current lead
  Future<void> skipLead() async {
    await _autoDialerService.skipLead();
  }

  // Mark call as started (when user confirms they made the call)
  void markCallStarted() {
    _autoDialerService.markCallStarted();
  }

  // Mark call as ended (when user hangs up)
  void markCallEnded() {
    _autoDialerService.markCallEnded();
  }

  // Log call with disposition
  Future<bool> logCallDisposition({
    required int leadId,
    required String disposition,
    String? remarks,
    String? newLeadStatus,
  }) async {
    try {
      final duration = _autoDialerService.getCallDuration();
      
      final response = await _leadService.createCallLog(
        leadId,
        disposition: disposition,
        remarks: remarks,
        duration: duration?.inSeconds,
        leadStatus: newLeadStatus,
      );

      if (response.isSuccess) {
        _showingDispositionDialog = false;
        notifyListeners();
        
        // Auto-move to next lead if in auto-dial mode
        if (isAutoDialing) {
          await Future.delayed(const Duration(seconds: 1));
          await nextLead();
        }
        
        return true;
      } else {
        _errorMessage = response.errorMessage;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to log call: $e';
      notifyListeners();
      return false;
    }
  }

  // Dismiss disposition dialog
  void dismissDispositionDialog() {
    _showingDispositionDialog = false;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get call duration
  Duration? getCallDuration() {
    return _autoDialerService.getCallDuration();
  }

  // Format call duration
  String formatCallDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Restart auto dialer from specific lead
  Future<void> restartFrom(int index) async {
    await _autoDialerService.restartFrom(index);
  }

  // Get disposition options
  List<Map<String, String>> get dispositionOptions => [
    {'value': 'interested', 'label': 'Interested', 'status': 'interested'},
    {'value': 'not_interested', 'label': 'Not Interested', 'status': 'not_interested'},
    {'value': 'callback', 'label': 'Callback Later', 'status': 'callback'},
    {'value': 'wrong_number', 'label': 'Wrong Number', 'status': 'wrong_number'},
    {'value': 'not_reachable', 'label': 'Not Reachable', 'status': 'not_reachable'},
    {'value': 'busy', 'label': 'Busy', 'status': 'contacted'},
    {'value': 'voicemail', 'label': 'Voicemail', 'status': 'contacted'},
    {'value': 'follow_up', 'label': 'Follow-up Required', 'status': 'contacted'},
  ];

  // Quick disposition actions
  Future<void> markAsInterested(Lead lead, {String? remarks}) async {
    await logCallDisposition(
      leadId: lead.id,
      disposition: 'interested',
      remarks: remarks,
      newLeadStatus: 'interested',
    );
  }

  Future<void> markAsNotInterested(Lead lead, {String? remarks}) async {
    await logCallDisposition(
      leadId: lead.id,
      disposition: 'not_interested',
      remarks: remarks,
      newLeadStatus: 'not_interested',
    );
  }

  Future<void> markAsCallback(Lead lead, {String? remarks}) async {
    await logCallDisposition(
      leadId: lead.id,
      disposition: 'callback',
      remarks: remarks,
      newLeadStatus: 'callback',
    );
  }

  Future<void> markAsNotReachable(Lead lead, {String? remarks}) async {
    await logCallDisposition(
      leadId: lead.id,
      disposition: 'not_reachable',
      remarks: remarks,
      newLeadStatus: 'not_reachable',
    );
  }
}