// lib/services/whatsapp_service.dart

import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class WhatsAppService {
  static const String _whatsappScheme = 'whatsapp://send';
  static const String _whatsappWebUrl = 'https://wa.me';

  /// Check if WhatsApp is installed on the device
  static Future<bool> isWhatsAppInstalled() async {
    try {
      final Uri whatsappUri = Uri.parse('$_whatsappScheme?phone=');
      return await canLaunchUrl(whatsappUri);
    } catch (e) {
      return false;
    }
  }

  /// Send WhatsApp message to a phone number
  /// [phoneNumber] should be in international format (e.g., +919876543210)
  /// [message] is optional predefined message
  static Future<bool> sendMessage({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhone = _cleanPhoneNumber(phoneNumber);

      // Check if WhatsApp is installed
      final isInstalled = await isWhatsAppInstalled();

      if (isInstalled) {
        // Use WhatsApp app
        return await _launchWhatsAppApp(cleanPhone, message);
      } else {
        // Fallback to WhatsApp Web
        return await _launchWhatsAppWeb(cleanPhone, message);
      }
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      return false;
    }
  }

  /// Launch WhatsApp app directly
  static Future<bool> _launchWhatsAppApp(
      String phoneNumber, String? message) async {
    try {
      String url = '$_whatsappScheme?phone=$phoneNumber';
      if (message != null && message.isNotEmpty) {
        final encodedMessage = Uri.encodeComponent(message);
        url += '&text=$encodedMessage';
      }

      final Uri whatsappUri = Uri.parse(url);
      return await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Error launching WhatsApp app: $e');
      return false;
    }
  }

  /// Launch WhatsApp Web as fallback
  static Future<bool> _launchWhatsAppWeb(
      String phoneNumber, String? message) async {
    try {
      String url = '$_whatsappWebUrl/$phoneNumber';
      if (message != null && message.isNotEmpty) {
        final encodedMessage = Uri.encodeComponent(message);
        url += '?text=$encodedMessage';
      }

      final Uri webUri = Uri.parse(url);
      return await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Error launching WhatsApp Web: $e');
      return false;
    }
  }

  /// Clean phone number to international format
  static String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If doesn't start with +, assume it's Indian number and add +91
    if (!cleaned.startsWith('+')) {
      // Remove leading 0 if present (common in Indian numbers)
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1);
      }
      // Add +91 for Indian numbers (you can modify this based on your region)
      cleaned = '+91$cleaned';
    }

    return cleaned;
  }

  /// Get predefined message templates for leads
  static String getLeadMessage({
    required String leadName,
    String? companyName,
    String? agentName,
  }) {
    if (companyName != null && companyName.isNotEmpty) {
      return "Hi $leadName, this is ${agentName ?? 'our team'} from $companyName. "
          "I'd like to discuss some exciting opportunities with you. "
          "When would be a good time to connect?";
    } else {
      return "Hi $leadName, this is ${agentName ?? 'our team'}. "
          "I'd like to discuss some exciting opportunities with you. "
          "When would be a good time to connect?";
    }
  }

  /// Get follow-up message template
  static String getFollowUpMessage({
    required String leadName,
    String? previousInteraction,
  }) {
    return "Hi $leadName, following up on our previous conversation. "
        "${previousInteraction ?? 'Hope you had time to consider our discussion.'} "
        "Would you like to schedule a call to discuss further?";
  }

  /// Get reminder message template
  static String getReminderMessage({
    required String leadName,
    required String appointmentTime,
  }) {
    return "Hi $leadName, this is a friendly reminder about our scheduled call at $appointmentTime. "
        "Looking forward to speaking with you!";
  }
}
