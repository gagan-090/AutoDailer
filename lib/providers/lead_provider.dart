// lib/providers/lead_provider.dart
import 'package:flutter/material.dart';
import '../models/lead_model.dart';
import '../services/lead_service.dart';

class LeadProvider with ChangeNotifier {
  final LeadService _leadService = LeadService();

  List<Lead> _leads = [];
  Lead? _selectedLead;
  bool _isLoading = false;
  String? _errorMessage;
  DashboardData? _dashboardData;

  // Filters
  String _statusFilter = '';
  String _searchQuery = '';

  // Getters
  List<Lead> get leads => _leads;
  Lead? get selectedLead => _selectedLead;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardData? get dashboardData => _dashboardData;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  // Filtered leads
  List<Lead> get filteredLeads {
    var filtered = _leads.where((lead) {
      bool matchesStatus = _statusFilter.isEmpty || lead.status == _statusFilter;
      bool matchesSearch = _searchQuery.isEmpty || 
          lead.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lead.phone.contains(_searchQuery) ||
          (lead.company?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      return matchesStatus && matchesSearch;
    }).toList();

    // Sort by priority: new -> callback -> contacted -> interested
    filtered.sort((a, b) {
      const priority = {
        'new': 1,
        'callback': 2,
        'contacted': 3,
        'interested': 4,
        'not_interested': 5,
        'converted': 6,
        'wrong_number': 7,
        'not_reachable': 8,
      };
      
      int aPriority = priority[a.status] ?? 9;
      int bPriority = priority[b.status] ?? 9;
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // If same priority, sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  // Load leads
  Future<void> loadLeads({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _leadService.getMyLeads(
        status: _statusFilter.isNotEmpty ? _statusFilter : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        ordering: '-created_at',
      );

      if (response.isSuccess) {
        _leads = response.data ?? [];
        print('LeadProvider: Loaded ${_leads.length} leads');
      } else {
        _errorMessage = response.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Failed to load leads: $e';
      print('LeadProvider error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load dashboard data
  Future<void> loadDashboard() async {
    try {
      final response = await _leadService.getDashboardData();
      
      if (response.isSuccess) {
        _dashboardData = response.data;
        notifyListeners();
      }
    } catch (e) {
      print('Dashboard load error: $e');
    }
  }

  // Set filters
  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
    loadLeads(refresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    if (query.isEmpty) {
      loadLeads(refresh: true);
    }
  }

  void clearFilters() {
    _statusFilter = '';
    _searchQuery = '';
    notifyListeners();
    loadLeads(refresh: true);
  }

  // Select lead
  void selectLead(Lead lead) {
    _selectedLead = lead;
    notifyListeners();
  }

  // Update lead status
  Future<bool> updateLeadStatus(int leadId, String status, {String? notes}) async {
    try {
      final response = await _leadService.updateLeadStatus(leadId, status, notes: notes);
      
      if (response.isSuccess) {
        // Update local data
        final index = _leads.indexWhere((lead) => lead.id == leadId);
        if (index != -1) {
          _leads[index] = response.data!;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response.errorMessage;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update lead: $e';
      notifyListeners();
      return false;
    }
  }

  // Log call
  Future<bool> logCall(int leadId, {
    required String disposition,
    String? remarks,
    int? duration,
    String? leadStatus,
  }) async {
    try {
      final response = await _leadService.createCallLog(
        leadId,
        disposition: disposition,
        remarks: remarks,
        duration: duration,
        leadStatus: leadStatus,
      );
      
      if (response.isSuccess) {
        // Refresh leads to get updated data
        await loadLeads(refresh: true);
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

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get leads by status
  List<Lead> getLeadsByStatus(String status) {
    return _leads.where((lead) => lead.status == status).toList();
  }

  // Get lead stats
  Map<String, int> get leadStats {
    final stats = <String, int>{};
    for (final lead in _leads) {
      stats[lead.status] = (stats[lead.status] ?? 0) + 1;
    }
    return stats;
  }
}