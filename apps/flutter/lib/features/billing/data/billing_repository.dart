import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'billing_models.dart';

class BillingRepository {
  BillingRepository(this.baseUrl, this.client);

  final String baseUrl;
  final SupabaseClient client;

  Future<BillingStatus> getBillingStatus() async {
    final body = await _get('/api/v1/billing/status');
    return BillingStatus.fromJson(Map<String, dynamic>.from(body));
  }

  Future<List<BillingPlan>> getPlans() async {
    final body = Map<String, dynamic>.from(await _get('/api/v1/billing/plans'));
    return (body['plans'] as List? ?? const [])
        .map((item) => BillingPlan.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> createCheckout({required String planCode}) async {
    final token = client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Sign in required.');
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/billing/checkout'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'plan_code': planCode}),
    );
    if (response.statusCode == 503) {
      throw const BillingProviderUnavailableException();
    }
    if (response.statusCode >= 400) throw Exception('Checkout could not be started.');
  }

  Future<dynamic> _get(String path) async {
    final token = client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Sign in required.');
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode >= 400) throw Exception('Billing is unavailable.');
    return jsonDecode(response.body);
  }
}

class BillingProviderUnavailableException implements Exception {
  const BillingProviderUnavailableException();

  @override
  String toString() => 'Billing provider is not configured.';
}
