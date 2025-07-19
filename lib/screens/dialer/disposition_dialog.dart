// lib/screens/dialer/disposition_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/call_provider.dart';
import '../../config/theme_config.dart';
import '../../models/lead_model.dart';

class DispositionDialog extends StatefulWidget {
  final Lead lead;
  final VoidCallback onDispositionSaved; // Added callback parameter

  const DispositionDialog({
    super.key,
    required this.lead,
    required this.onDispositionSaved, // Added to constructor
  });

  @override
  State<DispositionDialog> createState() => _DispositionDialogState();
}

class _DispositionDialogState extends State<DispositionDialog> {
  String? _selectedDisposition;
  String? _selectedLeadStatus;
  final TextEditingController _remarksController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _dispositionOptions = [
    {
      'value': 'interested',
      'label': 'Interested',
      'icon': Icons.thumb_up,
      'color': Colors.green,
      'status': 'interested',
      'description': 'Customer showed interest in the product/service',
    },
    {
      'value': 'not_interested',
      'label': 'Not Interested',
      'icon': Icons.thumb_down,
      'color': Colors.red,
      'status': 'not_interested',
      'description': 'Customer is not interested',
    },
    {
      'value': 'callback',
      'label': 'Callback Later',
      'icon': Icons.schedule,
      'color': Colors.orange,
      'status': 'callback',
      'description': 'Customer requested a callback at a later time',
    },
    {
      'value': 'wrong_number',
      'label': 'Wrong Number',
      'icon': Icons.error_outline,
      'color': Colors.grey,
      'status': 'wrong_number',
      'description': 'Incorrect or invalid phone number',
    },
    {
      'value': 'not_reachable',
      'label': 'Not Reachable',
      'icon': Icons.phone_disabled,
      'color': Colors.brown,
      'status': 'not_reachable',
      'description': 'No answer, line busy, or unreachable',
    },
    {
      'value': 'busy',
      'label': 'Busy',
      'icon': Icons.hourglass_empty,
      'color': Colors.amber,
      'status': 'contacted',
      'description': 'Customer was busy, try again later',
    },
    {
      'value': 'voicemail',
      'label': 'Voicemail',
      'icon': Icons.voicemail,
      'color': Colors.blue,
      'status': 'contacted',
      'description': 'Left a voicemail message',
    },
    {
      'value': 'follow_up',
      'label': 'Follow-up Required',
      'icon': Icons.assignment,
      'color': Colors.purple,
      'status': 'contacted',
      'description': 'Needs follow-up action or information',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: ThemeConfig.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.edit,
                  color: ThemeConfig.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Call Disposition',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      widget.lead.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.lead.phone,
            style: TextStyle(
              fontSize: 16,
              color: ThemeConfig.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How did the call go?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Disposition Options
            ...(_dispositionOptions.map((option) {
              final isSelected = _selectedDisposition == option['value'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDisposition = option['value'];
                      _selectedLeadStatus = option['status'];
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? option['color'].withOpacity(0.1)
                          : Colors.grey[50],
                      border: Border.all(
                        color: isSelected 
                            ? option['color']
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: option['value'],
                          groupValue: _selectedDisposition,
                          onChanged: (value) {
                            setState(() {
                              _selectedDisposition = value;
                              _selectedLeadStatus = option['status'];
                            });
                          },
                          activeColor: option['color'],
                        ),
                        Icon(
                          option['icon'],
                          color: isSelected ? option['color'] : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option['label'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? option['color'] : Colors.black,
                                ),
                              ),
                              Text(
                                option['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 20),
            // Remarks Section
            const Text(
              'Call Notes (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarksController,
              decoration: InputDecoration(
                hintText: 'Add any notes about the call...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            // Call Duration Info
            Consumer<CallProvider>(
              builder: (context, callProvider, child) {
                final duration = callProvider.getCallDuration();
                if (duration != null) {
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Call Duration: ${callProvider.formatCallDuration(duration)}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  final callProvider = Provider.of<CallProvider>(context, listen: false);
                  callProvider.dismissDispositionDialog();
                  Navigator.pop(context);
                },
          child: const Text('Cancel'),
        ),
        // Save Button
        ElevatedButton(
          onPressed: (_selectedDisposition != null && !_isLoading)
              ? _saveDisposition
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeConfig.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save & Continue'),
        ),
      ],
    );
  }

  void _saveDisposition() async {
    if (_selectedDisposition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final callProvider = Provider.of<CallProvider>(context, listen: false);

      final success = await callProvider.logCallDisposition(
        leadId: widget.lead.id,
        disposition: _selectedDisposition!,
        remarks: _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : null,
        newLeadStatus: _selectedLeadStatus,
      );

      if (success && mounted) {
        widget.onDispositionSaved(); // Invoke the callback
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Call logged successfully for ${widget.lead.name}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              callProvider.errorMessage ?? 'Failed to save call disposition',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }
}