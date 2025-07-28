// lib/widgets/whatsapp_button.dart

import 'package:flutter/material.dart';
import '../services/whatsapp_service.dart';
import '../models/lead_model.dart';

class WhatsAppButton extends StatelessWidget {
  final Lead lead;
  final String? customMessage;
  final String? agentName;
  final VoidCallback? onMessageSent;
  final bool showText;
  final bool isFloatingAction;

  const WhatsAppButton({
    Key? key,
    required this.lead,
    this.customMessage,
    this.agentName,
    this.onMessageSent,
    this.showText = true,
    this.isFloatingAction = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isFloatingAction) {
      return FloatingActionButton(
        onPressed: () => _sendWhatsAppMessage(context),
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
      );
    }

    if (showText) {
      return ElevatedButton.icon(
        onPressed: () => _sendWhatsAppMessage(context),
        icon: const Icon(Icons.chat, size: 20),
        label: const Text('WhatsApp'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366), // WhatsApp green
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => _sendWhatsAppMessage(context),
      icon: const Icon(
        Icons.chat,
        color: Color(0xFF25D366),
      ),
      tooltip: 'Send WhatsApp Message',
    );
  }

  Future<void> _sendWhatsAppMessage(BuildContext context) async {
    try {
      // Show loading indicator
      _showLoadingDialog(context);

      // Prepare message
      String message = customMessage ??
          WhatsAppService.getLeadMessage(
            leadName: lead.name,
            companyName: lead.company,
            agentName: agentName,
          );

      // Send WhatsApp message
      final success = await WhatsAppService.sendMessage(
        phoneNumber: lead.phone,
        message: message,
      );

      // Hide loading dialog
      Navigator.of(context).pop();

      if (success) {
        _showSuccessSnackbar(context);
        onMessageSent?.call();
      } else {
        _showErrorDialog(context);
      }
    } catch (e) {
      // Hide loading dialog
      Navigator.of(context).pop();
      _showErrorDialog(context, error: e.toString());
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Opening WhatsApp...'),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('WhatsApp opened for ${lead.name}'),
          ],
        ),
        backgroundColor: const Color(0xFF25D366),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, {String? error}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('WhatsApp Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unable to open WhatsApp. This could be because:'),
            const SizedBox(height: 8),
            const Text('• WhatsApp is not installed'),
            const Text('• Invalid phone number'),
            const Text('• Permission denied'),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text('Error: $error', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessageOptionsDialog(context);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Message Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Introduction'),
              subtitle: const Text('General introduction message'),
              onTap: () {
                Navigator.pop(context);
                _sendCustomMessage(
                    context,
                    WhatsAppService.getLeadMessage(
                      leadName: lead.name,
                      companyName: lead.company,
                      agentName: agentName,
                    ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.follow_the_signs),
              title: const Text('Follow-up'),
              subtitle: const Text('Follow-up on previous conversation'),
              onTap: () {
                Navigator.pop(context);
                _sendCustomMessage(
                    context,
                    WhatsAppService.getFollowUpMessage(
                      leadName: lead.name,
                      previousInteraction: lead.lastCallDisposition,
                    ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Custom Message'),
              subtitle: const Text('Write your own message'),
              onTap: () {
                Navigator.pop(context);
                _showCustomMessageDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCustomMessageDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom WhatsApp Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To: ${lead.name} (${lead.phone})'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _sendCustomMessage(context, controller.text);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCustomMessage(BuildContext context, String message) async {
    final success = await WhatsAppService.sendMessage(
      phoneNumber: lead.phone,
      message: message,
    );

    if (success) {
      _showSuccessSnackbar(context);
      onMessageSent?.call();
    } else {
      _showErrorDialog(context);
    }
  }
}
