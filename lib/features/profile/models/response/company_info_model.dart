class SocialLinksModel {
  final String facebook;
  final String instagram;
  final String twitter;
  final String youtube;
  final String linkedin;

  const SocialLinksModel({
    this.facebook = '',
    this.instagram = '',
    this.twitter = '',
    this.youtube = '',
    this.linkedin = '',
  });

  factory SocialLinksModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SocialLinksModel();
    return SocialLinksModel(
      facebook: (json['facebook'] ?? '').toString().trim(),
      instagram: (json['instagram'] ?? '').toString().trim(),
      twitter: (json['twitter'] ?? '').toString().trim(),
      youtube: (json['youtube'] ?? '').toString().trim(),
      linkedin: (json['linkedin'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facebook': facebook,
      'instagram': instagram,
      'twitter': twitter,
      'youtube': youtube,
      'linkedin': linkedin,
    };
  }

  bool get hasAnyLink =>
      facebook.isNotEmpty ||
      instagram.isNotEmpty ||
      twitter.isNotEmpty ||
      youtube.isNotEmpty ||
      linkedin.isNotEmpty;
}

class CompanyInfoModel {
  final String id;
  final String companyName;
  final String tagline;
  final String supportEmail;
  final String supportPhone;
  final String address;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String formattedAddress;
  final String copyrightText;
  final String poweredBy;
  final String googleMapUrl;
  final double latitude;
  final double longitude;
  final String status;
  final SocialLinksModel socialLinks;

  const CompanyInfoModel({
    this.id = '',
    this.companyName = 'Masti Adda OTT',
    this.tagline =
        'The ultimate destination for premium entertainment. Watch the latest web series, movies, and originals anytime, anywhere.',
    this.supportEmail = 'support@mastiaddaapp.in',
    this.supportPhone = '',
    this.address = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.postalCode = '',
    this.formattedAddress = '',
    this.copyrightText = '© 2026 Masti Adda OTT All Rights Reserved',
    this.poweredBy = 'POWERED BY ❤️',
    this.googleMapUrl = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.status = '',
    this.socialLinks = const SocialLinksModel(),
  });

  factory CompanyInfoModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompanyInfoModel();

    return CompanyInfoModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      companyName: (json['companyName'] ?? 'Masti Adda OTT').toString(),
      tagline: (json['tagline'] ??
              'The ultimate destination for premium entertainment. Watch the latest web series, movies, and originals anytime, anywhere.')
          .toString(),
      supportEmail:
          (json['supportEmail'] ?? 'support@golidoliapp.in').toString(),
      supportPhone: (json['supportPhone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      addressLine1: (json['addressLine1'] ?? '').toString(),
      addressLine2: (json['addressLine2'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      postalCode: (json['postalCode'] ?? '').toString(),
      formattedAddress: (json['formattedAddress'] ?? '').toString(),
      copyrightText: (json['copyrightText'] ??
              '© ${DateTime.now().year} Masti Adda OTT All Rights Reserved')
          .toString(),
      poweredBy:
          (json['poweredBy'] ?? 'POWERED BY KRITI DIGITAL SOLUTIONS').toString(),
      googleMapUrl: (json['googleMapUrl'] ?? '').toString(),
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : 0.0,
      status: (json['status'] ?? '').toString(),
      socialLinks: SocialLinksModel.fromJson(
        json['socialLinks'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'companyName': companyName,
      'tagline': tagline,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'address': address,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'formattedAddress': formattedAddress,
      'copyrightText': copyrightText,
      'poweredBy': poweredBy,
      'googleMapUrl': googleMapUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'socialLinks': socialLinks.toJson(),
    };
  }

  /// Get the cleanest formatted address string
  String get displayAddress {
    if (formattedAddress.trim().isNotEmpty) return formattedAddress.trim();
    if (address.trim().isNotEmpty) {
      final cityStateCountry = [city, state, country, postalCode]
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
      if (cityStateCountry.isNotEmpty && !address.contains(city)) {
        return '${address.trim()}, $cityStateCountry';
      }
      return address.trim();
    }
    final parts = [addressLine1, addressLine2, city, state, country, postalCode]
        .where((p) => p.trim().isNotEmpty)
        .join(', ');
    return parts.isNotEmpty
        ? parts
        : 'Floor No 12, 1202, Residences Tanaji Nagar, Tanaji Nagar Road No 1, Near Time of India off, W.E. Highway, Mathura, Uttar Pradesh, India - 281004';
  }
}

class CompanyInfoResponse {
  final bool success;
  final CompanyInfoModel? data;

  const CompanyInfoResponse({
    required this.success,
    this.data,
  });

  factory CompanyInfoResponse.fromJson(Map<String, dynamic> json) {
    return CompanyInfoResponse(
      success: json['success'] == true,
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CompanyInfoModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
