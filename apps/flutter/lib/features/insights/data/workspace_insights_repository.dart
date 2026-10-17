import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkspaceInsightsRepository {
  WorkspaceInsightsRepository(this.baseUrl, this.client);

  final String baseUrl;
  final SupabaseClient client;

  Future<Map<String, String>> _headers() async {
    final token = client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Sign in to view workspace insights.');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
    if (response.statusCode >= 400) {
      throw Exception('Request failed (${response.statusCode}). Please try again.');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<List<Map<String, dynamic>>> integrations() async {
    final result = await _get('/api/v1/integrations');
    return (result['integrations'] as List? ?? const [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Map<String, dynamic>> report() => _get('/api/v1/reports/overview');
}
