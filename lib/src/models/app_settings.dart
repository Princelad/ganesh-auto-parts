/// Model for application settings including GST configuration
class AppSettings {
  final int? id;
  final bool gstEnabled;
  final double defaultGstRate;
  final String? gstin; // GST Identification Number
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessEmail;
  final int updatedAt;

  AppSettings({
    this.id,
    required this.gstEnabled,
    required this.defaultGstRate,
    this.gstin,
    required this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gstEnabled': gstEnabled ? 1 : 0,
      'defaultGstRate': defaultGstRate,
      'gstin': gstin,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'updatedAt': updatedAt,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as int?,
      gstEnabled: (map['gstEnabled'] as int) == 1,
      defaultGstRate: (map['defaultGstRate'] as num).toDouble(),
      gstin: map['gstin'] as String?,
      businessName: map['businessName'] as String,
      businessAddress: map['businessAddress'] as String?,
      businessPhone: map['businessPhone'] as String?,
      businessEmail: map['businessEmail'] as String?,
      updatedAt: map['updatedAt'] as int,
    );
  }

  AppSettings copyWith({
    int? id,
    bool? gstEnabled,
    double? defaultGstRate,
    String? gstin,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    int? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      gstEnabled: gstEnabled ?? this.gstEnabled,
      defaultGstRate: defaultGstRate ?? this.defaultGstRate,
      gstin: gstin ?? this.gstin,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
