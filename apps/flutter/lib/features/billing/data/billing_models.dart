class BillingPlan {
  BillingPlan.fromJson(Map<String, dynamic> json)
      : code = '${json['key'] ?? json['code'] ?? ''}',
        name = '${json['name'] ?? ''}',
        description = json['description'] as String?,
        monthlyPrice = _number(json['monthlyPrice'] ?? json['monthly_price']),
        annualPrice = _number(json['annualPrice'] ?? json['annual_price']),
        currency = '${json['currency'] ?? 'ZAR'}',
        features = (json['features'] as List? ?? const []).map((value) => '$value').toList(),
        limits = Map<String, dynamic>.from(json['limits'] ?? const {}),
        active = json['active'] is bool ? json['active'] as bool : true;

  final String code;
  final String name;
  final String? description;
  final num? monthlyPrice;
  final num? annualPrice;
  final String currency;
  final List<String> features;
  final Map<String, dynamic> limits;
  final bool active;
}

class UsageMetric {
  const UsageMetric({required this.key, required this.value, this.limit});

  final String key;
  final num value;
  final num? limit;
}

class BillingStatus {
  BillingStatus.fromJson(Map<String, dynamic> json)
      : plan = BillingPlan.fromJson(Map<String, dynamic>.from(json['plan'] ?? const {})),
        subscription = Map<String, dynamic>.from(json['subscription'] ?? const {}),
        usage = Map<String, dynamic>.from(json['usage'] ?? const {}),
        provider = Map<String, dynamic>.from(json['billingProvider'] ?? const {});

  final BillingPlan plan;
  final Map<String, dynamic> subscription;
  final Map<String, dynamic> usage;
  final Map<String, dynamic> provider;

  String get subscriptionState => '${subscription['status'] ?? 'inactive'}';
  DateTime? get trialStart => _date(subscription['trial_start'] ?? subscription['trial_starts_at']);
  DateTime? get trialEnd => _date(subscription['trial_end'] ?? subscription['trial_ends_at']);
  bool get trialActive {
    final state = subscriptionState.toLowerCase();
    return state == 'trialing' || state == 'trial_active' || (trialEnd?.isAfter(DateTime.now()) ?? false);
  }

  bool get providerConfigured => provider['configured'] == true;
  String get providerMessage => '${provider['message'] ?? 'Billing provider is not configured.'}';

  List<UsageMetric> get metrics => usage.entries.map((entry) => UsageMetric(
        key: entry.key,
        value: _number(entry.value) ?? 0,
        limit: _number(plan.limits[entry.key]),
      )).toList();
}

num? _number(Object? value) => value is num ? value : num.tryParse('$value');
DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse('$value');
