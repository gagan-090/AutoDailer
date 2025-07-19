// lib/models/lead_info_model.dart
class LeadInfo {
  final int id;
  final String name;
  final String phone;
  final String? company;

  LeadInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.company,
  });

  factory LeadInfo.fromJson(Map<String, dynamic> json) {
    return LeadInfo(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      company: json['company'],
    );
  }
}
