class Workspace {
  const Workspace({required this.id, required this.name, required this.role, required this.onboardingComplete});
  final String id;
  final String name;
  final String role;
  final bool onboardingComplete;
}

class WorkspaceDraft {
  const WorkspaceDraft({
    required this.businessName, required this.businessType, required this.industry,
    required this.description, required this.countryCode, required this.region,
    required this.city, required this.email, required this.phone, this.tradingName,
    this.website, this.registrationNumber, this.vatNumber, this.taxNumber, this.csdNumber,
  });
  final String businessName;
  final String? tradingName;
  final String businessType;
  final String industry;
  final String description;
  final String countryCode;
  final String region;
  final String city;
  final String email;
  final String phone;
  final String? website;
  final String? registrationNumber;
  final String? vatNumber;
  final String? taxNumber;
  final String? csdNumber;

  Map<String, dynamic> toRpc() => {
    'p_legal_name': businessName, 'p_trading_name': tradingName, 'p_business_type': businessType,
    'p_industry': industry, 'p_description': description, 'p_country_code': countryCode,
    'p_region': region, 'p_city': city, 'p_email': email, 'p_phone': phone, 'p_website': website,
    'p_registration_number': registrationNumber, 'p_vat_number': vatNumber,
    'p_tax_number': taxNumber, 'p_csd_number': csdNumber,
  };
}

const businessTypes = [
  'Sole proprietor', 'Private company', 'Non-profit organisation', 'Partnership',
  'Close corporation', 'Government/public organisation', 'Educational institution', 'Other',
];

const industries = [
  'Information Technology', 'Professional Services', 'Construction', 'Security', 'Property / Real Estate',
  'Retail', 'Hospitality', 'Healthcare', 'Education', 'Transport / Logistics', 'Automotive', 'Finance',
  'Manufacturing', 'Agriculture', 'Cleaning Services', 'Beauty / Personal Care', 'Legal Services', 'Other',
];

const countries = {'ZA': 'South Africa', 'BW': 'Botswana', 'NA': 'Namibia', 'GB': 'United Kingdom', 'US': 'United States', 'OTHER': 'Other'};
