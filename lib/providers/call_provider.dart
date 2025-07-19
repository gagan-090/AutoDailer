// lib/providers/call_provider.dart - REPLACE ORIGINAL FILE
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/lead_model.dart';
import '../services/auto_dialer_service.dart';
import '../services/lead_service.dart';

class CallProvider with ChangeNotifier {
  final AutoDialerService _autoDialerService = AutoDialerService();
  final LeadService _leadService = LeadService();

  // Stream subscriptions
  StreamSubscription<AutoDialerState>? _stateSubscription;
  StreamSubscription<AutoDialerEvent>? _eventSubscription;

  // Current state
  AutoDialerState _currentState = AutoDialerState(
    isActive: false,
    isCallInProgress: false,
    currentIndex: 0,
    totalLeads: 0,
    remainingLeads: 0,
    autoDialDelay: 10,
    autoRedialEnabled: true,
  );

  String? _errorMessage;
  bool _showingDispositionDialog = false;

  // Getters
  AutoDialerState get currentState => _currentState;
  String? get errorMessage => _errorMessage;
  bool get showingDispositionDialog => _showingDispositionDialog;
  bool get isAutoDialing => _currentState.isActive;
  bool get isCallInProgress => _currentState.isCallInProgress;
  Lead? get currentLead => _currentState.currentLead;
  int get remainingLeads => _currentState.remainingLeads;
  double get progress => _currentState.progress;

  CallProvider() {
    // Listen to dialer service streams
    _stateSubscription = _autoDialerService.stateStream.listen(_onStateChanged);
    _eventSubscription = _autoDialerService.eventStream.listen(_onEventChanged);
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _eventSubscription?.cancel();
    _autoDialerService.dispose();
    super.dispose();
  }

  // Handle state changes from dialer service
  void _onStateChanged(AutoDialerState state) {
    _currentState = state;
    notifyListeners();
  }

  // Handle events from dialer service
  void _onEventChanged(AutoDialerEvent event) {
    if (event is CallConnected && !_showingDispositionDialog) {
      // Automatically show disposition dialog when call is connected
      _showingDispositionDialog = true;
      notifyListeners();
    } else if (event is AutoDialerError) {
      _errorMessage = event.message;
      notifyListeners();
    }
  }

  // Start auto dialing session
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
    notifyListeners();
  }

  // Make a direct call (for leads screen)
  Future<bool> makeDirectCall(String phoneNumber) async {
    try {
      final success = await _autoDialerService.makeCall(phoneNumber);
      if (!success) {
        _errorMessage = 'Failed to make call';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error making call: $e';
      notifyListeners();
      return false;
    }
  }

  // Skip current lead in auto dialer
  Future<void> skipCurrentLead() async {
    await _autoDialerService.skipCurrentLead();
  }

  // Force dial current lead
  Future<void> dialCurrentLead() async {
    await _autoDialerService.dialCurrentLead();
  }

  // Log call with disposition
  Future<bool> logCallDisposition({
    required int leadId,
    required String disposition,
    String? remarks,
    String? newLeadStatus,
  }) async {
    try {
      final response = await _leadService.createCallLog(
        leadId,
        disposition: disposition,
        remarks: remarks,
        leadStatus: newLeadStatus,
      );

      if (response.isSuccess) {
        _showingDispositionDialog = false;
        notifyListeners();
        
        // Notify dialer service that disposition was saved
        if (isAutoDialing) {
          await _autoDialerService.onDispositionSaved();
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

  // Quick disposition methods for common actions
  Future<bool> markAsInterested(int leadId, {String? remarks}) async {
    return await logCallDisposition(
      leadId: leadId,
      disposition: 'interested',
      remarks: remarks,
      newLeadStatus: 'interested',
    );
  }

  Future<bool> markAsNotInterested(int leadId, {String? remarks}) async {
    return await logCallDisposition(
      leadId: leadId,
      disposition: 'not_interested',
      remarks: remarks,
      newLeadStatus: 'not_interested',
    );
  }

  Future<bool> markAsCallback(int leadId, {String? remarks}) async {
    return await logCallDisposition(
      leadId: leadId,
      disposition: 'callback',
      remarks: remarks,
      newLeadStatus: 'callback',
    );
  }

  Future<bool> markAsNotReachable(int leadId, {String? remarks}) async {
    return await logCallDisposition(
      leadId: leadId,
      disposition: 'not_reachable',
      remarks: remarks,
      newLeadStatus: 'not_reachable',
    );
  }

  Future<bool> markAsWrongNumber(int leadId, {String? remarks}) async {
    return await logCallDisposition(
      leadId: leadId,
      disposition: 'wrong_number',
      remarks: remarks,
      newLeadStatus: 'wrong_number',
    );
  }

  // Auto dialer settings
  void setAutoDialDelay(int seconds) {
    _autoDialerService.setAutoDialDelay(seconds);
  }

  void setAutoRedialEnabled(bool enabled) {
    _autoDialerService.setAutoRedialEnabled(enabled);
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

  // Get call duration (if available)
  Duration? getCallDuration() {
    // This could be implemented if you track call start times
    return null;
  }

  // Format call duration
  String formatCallDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}