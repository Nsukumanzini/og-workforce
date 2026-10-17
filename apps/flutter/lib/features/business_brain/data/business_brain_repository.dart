import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';

class BusinessBrainSnapshot {
  const BusinessBrainSnapshot({required this.companyProfile, required this.counts});
  final Map<String, dynamic>? companyProfile;
  final Map<String, int> counts;

  int get activeProducts => counts['products'] ?? 0;
  int get activeServices => counts['services'] ?? 0;
  int get documents => counts['documents'] ?? 0;
  bool get hasHours => (counts['hours'] ?? 0) == 7;
  bool get hasContactOrEscalation => (counts['contacts'] ?? 0) > 0 || (counts['escalations'] ?? 0) > 0;
  bool get hasProductsOrServices => activeProducts > 0 || activeServices > 0;
  bool get hasPricing => counts['pricing'] == 1;
  bool get hasEngagement => counts['engagement'] == 1;

  int get completedCoreSections => [
        companyProfile != null,
        hasHours,
        hasContactOrEscalation,
        hasProductsOrServices,
        hasPricing,
        hasEngagement,
      ].where((value) => value).length;

  int get coreSectionCount => 6;
  double get completion => completedCoreSections / coreSectionCount;
}

abstract class BusinessBrainRepository {
  Future<BusinessBrainSnapshot> loadSnapshot(String organisationId);
  Future<List<Map<String, dynamic>>> list(String table, String organisationId, {String? orderBy});
  Future<Map<String, dynamic>> save(String table, String organisationId, Map<String, dynamic> values);
  Future<void> archive(String table, String organisationId, String id);
}

class SupabaseBusinessBrainRepository implements BusinessBrainRepository {
  SupabaseBusinessBrainRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<BusinessBrainSnapshot> loadSnapshot(String organisationId) async {
    const tables = {
      'products': 'products',
      'services': 'services',
      'documents': 'documents',
      'contacts': 'business_contacts',
      'escalations': 'escalation_contacts',
      'pricing': 'pricing_rules',
      'engagement': 'customer_engagement_profiles',
    };
    final results = await Future.wait<dynamic>([
      _client.from('business_profiles').select().eq('organisation_id', organisationId).maybeSingle(),
      for (final entry in tables.entries)
        entry.key == 'pricing' || entry.key == 'engagement'
            ? _client.from(entry.value).select('id').eq('organisation_id', organisationId)
            : _client.from(entry.value).select('id').eq('organisation_id', organisationId).eq('active', true),
      _client.from('business_hours').select('id').eq('organisation_id', organisationId).eq('is_open', true),
    ]);
    final profile = results.first as Map<String, dynamic>?;
    final counts = <String, int>{};
    var index = 1;
    for (final entry in tables.entries) {
      counts[entry.key] = (results[index++] as List).length;
    }
    counts['hours'] = (results[index] as List).length;
    return BusinessBrainSnapshot(companyProfile: profile, counts: counts);
  }

  @override
  Future<List<Map<String, dynamic>>> list(String table, String organisationId, {String? orderBy}) async {
    try {
      final query = _client.from(table).select().eq('organisation_id', organisationId);
      final rows = orderBy == null ? await query : await query.order(orderBy);
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      throw AppFailure('We could not load this Business Brain section.', technicalMessage: error.message);
    }
  }

  @override
  Future<Map<String, dynamic>> save(String table, String organisationId, Map<String, dynamic> values) async {
    try {
      final payload = {...values, 'organisation_id': organisationId};
      final row = await _client.from(table).upsert(payload).select().single();
      return Map<String, dynamic>.from(row);
    } on PostgrestException catch (error) {
      throw AppFailure('We could not save this Business Brain change.', technicalMessage: error.message);
    }
  }

  @override
  Future<void> archive(String table, String organisationId, String id) async {
    try {
      await _client.from(table).update({'active': false}).eq('organisation_id', organisationId).eq('id', id);
    } on PostgrestException catch (error) {
      throw AppFailure('We could not archive this record.', technicalMessage: error.message);
    }
  }
}

class UnconfiguredBusinessBrainRepository implements BusinessBrainRepository {
  const UnconfiguredBusinessBrainRepository();
  @override
  Future<BusinessBrainSnapshot> loadSnapshot(String organisationId) async => const BusinessBrainSnapshot(companyProfile: null, counts: {});
  @override
  Future<List<Map<String, dynamic>>> list(String table, String organisationId, {String? orderBy}) async => const [];
  @override
  Future<Map<String, dynamic>> save(String table, String organisationId, Map<String, dynamic> values) => Future.error(const AppFailure('Business Brain is not configured for this build.'));
  @override
  Future<void> archive(String table, String organisationId, String id) => Future.error(const AppFailure('Business Brain is not configured for this build.'));
}
