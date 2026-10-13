import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TenderOpportunity {
  TenderOpportunity.fromJson(Map<String, dynamic> j)
    : id = '${j['id']}',
      title = '${j['title']}',
      buyer = '${j['buyer'] ?? ''}',
      reference = '${j['reference'] ?? ''}',
      description = '${j['description'] ?? ''}',
      closingAt = '${j['closing_at'] ?? ''}',
      status = '${j['status'] ?? ''}',
      location = '${j['location'] ?? ''}';
  final String id,
      title,
      buyer,
      reference,
      description,
      closingAt,
      status,
      location;
}

class TenderEvidenceSource {
  TenderEvidenceSource.fromJson(Map<String, dynamic> j)
    : source = '${j['source'] ?? ''}',
      count = j['count'] as int? ?? 0,
      labels = (j['labels'] as List? ?? const []).map((v) => '$v').toList();
  final String source;
  final int count;
  final List<String> labels;
}

class TenderDocumentEvidence {
  TenderDocumentEvidence.fromJson(Map<String, dynamic> j)
    : documentId = '${j['document_id'] ?? ''}',
      title = '${j['document_title'] ?? 'Document'}',
      page = j['page']?.toString(),
      chunk = j['chunk_index']?.toString();
  final String documentId, title;
  final String? page, chunk;
}

class TenderRequirementEvidence {
  TenderRequirementEvidence.fromJson(Map<String, dynamic> j)
    : requirementId = '${j['requirementId']}',
      requirementText = '${j['requirementText']}',
      classification = '${j['classification']}',
      mandatory = j['mandatory'] == true,
      humanInputRequired = j['humanInputRequired'] == true,
      missingEvidence = (j['missingEvidence'] as List? ?? const [])
          .map((v) => '$v')
          .toList(),
      structured = (j['structuredEvidence'] as List? ?? const [])
          .map(
            (v) => TenderEvidenceSource.fromJson(Map<String, dynamic>.from(v)),
          )
          .toList(),
      tenderDocuments = (j['tenderDocumentEvidence'] as List? ?? const [])
          .map(
            (v) =>
                TenderDocumentEvidence.fromJson(Map<String, dynamic>.from(v)),
          )
          .toList(),
      businessDocuments =
          (j['businessBrainDocumentEvidence'] as List? ?? const [])
              .map(
                (v) => TenderDocumentEvidence.fromJson(
                  Map<String, dynamic>.from(v),
                ),
              )
              .toList();
  final String requirementId, requirementText, classification;
  final bool mandatory, humanInputRequired;
  final List<String> missingEvidence;
  final List<TenderEvidenceSource> structured;
  final List<TenderDocumentEvidence> tenderDocuments, businessDocuments;
}

class TenderApproval {
  TenderApproval.fromJson(Map<String, dynamic> j)
    : id = '${j['id']}',
      status = '${j['status'] ?? 'pending'}',
      requestedAt = '${j['requested_at'] ?? ''}',
      action = Map<String, dynamic>.from(j['action'] ?? {});
  final String id, status, requestedAt;
  final Map<String, dynamic> action;
}

class TenderBundle {
  TenderBundle.fromJson(Map<String, dynamic> j)
    : opportunity = TenderOpportunity.fromJson(
        Map<String, dynamic>.from(j['opportunity'] as Map),
      ),
      workspace = j['workspace'] == null
          ? null
          : Map<String, dynamic>.from(j['workspace']),
      requirements = (j['requirements'] as List? ?? const [])
          .map((x) => Map<String, dynamic>.from(x))
          .toList(),
      missingInformation = (j['missingInformation'] as List? ?? const [])
          .map((x) => Map<String, dynamic>.from(x))
          .toList(),
      drafts = (j['drafts'] as List? ?? const [])
          .map((x) => Map<String, dynamic>.from(x))
          .toList(),
      documents = (j['documents'] as List? ?? const [])
          .map((x) => Map<String, dynamic>.from(x))
          .toList(),
      approvals = (j['approvals'] as List? ?? const [])
          .map((x) => TenderApproval.fromJson(Map<String, dynamic>.from(x)))
          .toList();
  final TenderOpportunity opportunity;
  final Map<String, dynamic>? workspace;
  final List<Map<String, dynamic>> requirements,
      missingInformation,
      drafts,
      documents;
  final List<TenderApproval> approvals;
}

class TendersRepository {
  TendersRepository(this.baseUrl, this.client);
  final String baseUrl;
  final SupabaseClient client;
  Future<Map<String, String>> _h() async {
    final t = client.auth.currentSession?.accessToken;
    if (t == null) throw Exception('Sign in required.');
    return {'Authorization': 'Bearer $t', 'Content-Type': 'application/json'};
  }

  Future<dynamic> _req(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final h = await _h();
    final u = Uri.parse('$baseUrl$path');
    final r = method == 'POST'
        ? await http.post(u, headers: h, body: jsonEncode(body ?? {}))
        : method == 'PATCH'
        ? await http.patch(u, headers: h, body: jsonEncode(body ?? {}))
        : await http.get(u, headers: h);
    if (r.statusCode >= 400)
      throw Exception('Tender request failed (${r.statusCode}).');
    return jsonDecode(r.body);
  }

  Future<List<TenderOpportunity>> opportunities({
    String? search,
    String? status,
    String? source,
  }) async =>
      (await _req(
            '/api/v1/tenders/opportunities?search=${Uri.encodeComponent(search ?? '')}&status=${Uri.encodeComponent(status ?? '')}&source=${Uri.encodeComponent(source ?? '')}',
          ))['opportunities']
          .map<TenderOpportunity>(
            (x) => TenderOpportunity.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList();
  Future<TenderBundle> opportunity(String id) async => TenderBundle.fromJson(
    Map<String, dynamic>.from(await _req('/api/v1/tenders/opportunities/$id')),
  );
  Future<TenderBundle> workspace(String id) async => TenderBundle.fromJson(
    Map<String, dynamic>.from(await _req('/api/v1/tenders/workspaces/$id')),
  );
  Future<List<TenderRequirementEvidence>> evidence(String id) async =>
      (await _req('/api/v1/tenders/workspaces/$id/evidence'))['evidence']
          .map<TenderRequirementEvidence>(
            (x) => TenderRequirementEvidence.fromJson(
              Map<String, dynamic>.from(x),
            ),
          )
          .toList();
  Future<Map<String, dynamic>> summary() async =>
      Map<String, dynamic>.from(await _req('/api/v1/tenders/summary'));
  Future<Map<String, dynamic>> agent() async => Map<String, dynamic>.from(
    (await _req('/api/v1/agents/tenders'))['agent'] ?? {},
  );
  Future<Map<String, dynamic>> run() async => Map<String, dynamic>.from(
    await _req('/api/v1/agents/tenders/run', method: 'POST', body: {}),
  );
  Future<void> openWorkspace(String id) async {
    await _req(
      '/api/v1/tenders/workspaces',
      method: 'POST',
      body: {'opportunity_id': id},
    );
  }

  Future<void> updateRequirement(String id, String status, String notes) async {
    await _req(
      '/api/v1/tenders/requirements/$id',
      method: 'PATCH',
      body: {'status': status, 'notes': notes},
    );
  }

  Future<void> processDocument(String workspaceId, String documentId) async {
    await _req(
      '/api/v1/tenders/workspaces/$workspaceId/documents/$documentId/process',
      method: 'POST',
      body: {},
    );
  }

  Future<void> resolveMissing(String id, String status) async {
    await _req(
      '/api/v1/tenders/missing-information/$id',
      method: 'PATCH',
      body: {'status': status},
    );
  }

  Future<Map<String, dynamic>> generateDraft(
    String workspaceId,
    String type,
  ) async => Map<String, dynamic>.from(
    (await _req(
      '/api/v1/tenders/workspaces/$workspaceId/drafts/generate',
      method: 'POST',
      body: {'draft_type': type},
    ))['draft'],
  );
  Future<void> regenerateDraft(String id) async {
    await _req(
      '/api/v1/tenders/drafts/$id/regenerate',
      method: 'POST',
      body: {'confirm': true},
    );
  }

  Future<Map<String, dynamic>> requestApproval(String id) async =>
      Map<String, dynamic>.from(
        await _req(
          '/api/v1/tenders/drafts/$id/request-approval',
          method: 'POST',
          body: {},
        ),
      );
  Future<void> importTender(Map<String, dynamic> body) async {
    await _req('/api/v1/tenders/opportunities', method: 'POST', body: body);
  }

  Future<TenderDocumentUploadResult> uploadWorkspaceDocument({
    required String workspaceId,
    required PlatformFile file,
  }) async {
    final token = client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Sign in required.');
    if (file.bytes == null)
      throw Exception('Selected file data is unavailable.');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/tenders/workspaces/$workspaceId/documents'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    final extension = file.extension?.toLowerCase();
    final mediaType = switch (extension) {
      'pdf' => MediaType('application', 'pdf'),
      'docx' => MediaType(
        'application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      ),
      'xlsx' => MediaType(
        'application',
        'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
      'png' => MediaType('image', 'png'),
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      _ => throw Exception('Selected file type is not supported.'),
    };
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
        contentType: mediaType,
      ),
    );
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode >= 400) throw Exception('Document upload failed.');
    return TenderDocumentUploadResult.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }
}

class TenderDocumentUploadResult {
  TenderDocumentUploadResult.fromJson(Map<String, dynamic> json)
    : document = Map<String, dynamic>.from(json['document'] ?? {}),
      processing = Map<String, dynamic>.from(json['processing'] ?? {});
  final Map<String, dynamic> document, processing;
  String get processingStatus => '${processing['status'] ?? 'uploaded'}';
}
