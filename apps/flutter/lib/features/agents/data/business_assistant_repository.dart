import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AssistantSource { const AssistantSource(this.type,this.label,{this.page,this.sheet}); final String type,label; final int? page; final String? sheet; factory AssistantSource.fromJson(Map<String,dynamic> j)=>AssistantSource('${j['type']??'source'}','${j['label']??'Source'}',page:j['page'] as int?,sheet:j['sheet'] as String?); }
class AssistantMessage { const AssistantMessage({required this.role,required this.content,this.sources=const [],this.confidence}); final String role,content; final List<AssistantSource> sources; final String? confidence; }
class AssistantSession { const AssistantSession(this.id,this.title); final String id,title; }
class BusinessAssistantRepository {
  BusinessAssistantRepository(this.baseUrl,this.client); final String baseUrl; final SupabaseClient client;
  Future<Map<String,String>> _headers() async { final token=client.auth.currentSession?.accessToken; if(token==null) throw Exception('Sign in required.'); return {'Authorization':'Bearer $token','Content-Type':'application/json'}; }
  Future<dynamic> _get(String path) async { final r=await http.get(Uri.parse('$baseUrl$path'),headers:await _headers()); if(r.statusCode>=400) throw Exception('Assistant request failed.'); return jsonDecode(r.body); }
  Future<dynamic> _post(String path,[Map<String,dynamic>? body]) async { final r=await http.post(Uri.parse('$baseUrl$path'),headers:await _headers(),body:jsonEncode(body??{})); if(r.statusCode>=400) throw Exception('Assistant request failed.'); return jsonDecode(r.body); }
  Future<List<AssistantSession>> listSessions() async { final j=await _get('/api/v1/agents/business-assistant/sessions'); return [for(final x in (j['sessions'] as List? ?? const [])) AssistantSession('${x['id']}','${x['title']??'New Conversation'}')]; }
  Future<AssistantSession> createSession() async { final x=(await _post('/api/v1/agents/business-assistant/sessions'))['session']; return AssistantSession('${x['id']}','${x['title']??'New Conversation'}'); }
  Future<List<AssistantMessage>> messages(String id) async { final j=await _get('/api/v1/agents/business-assistant/sessions/$id/messages'); return [for(final x in (j['messages'] as List? ?? const [])) AssistantMessage(role:'${x['role']}',content:'${x['content']}',sources:[for(final s in (x['citations'] as List? ?? const [])) AssistantSource.fromJson(Map<String,dynamic>.from(s))])]; }
  Future<AssistantMessage> send(String id,String text) async { final j=await _post('/api/v1/agents/business-assistant/sessions/$id/messages',{'message':text}); return AssistantMessage(role:'assistant',content:'${j['message']?['content']??''}',confidence:j['confidence'] as String?,sources:[for(final s in (j['sources'] as List? ?? const [])) AssistantSource.fromJson(Map<String,dynamic>.from(s))]); }
}
