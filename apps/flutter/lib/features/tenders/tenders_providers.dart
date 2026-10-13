import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/tenders_repository.dart';

class TenderQuery { const TenderQuery({this.search = '', this.status, this.source}); final String search; final String? status, source; TenderQuery copyWith({String? search, String? status, bool clearStatus = false, String? source, bool clearSource = false}) => TenderQuery(search: search ?? this.search, status: clearStatus ? null : (status ?? this.status), source: clearSource ? null : (source ?? this.source)); }
final tenderQueryProvider = Provider<TenderQuery>((ref) => const TenderQuery());
final tendersRepositoryProvider = Provider<TendersRepository>((ref) => throw UnimplementedError());
final tenderOpportunitiesProvider = FutureProvider<List<TenderOpportunity>>((ref) { final q = ref.watch(tenderQueryProvider); return ref.read(tendersRepositoryProvider).opportunities(search: q.search, status: q.status, source: q.source); });
final tenderAgentProvider = FutureProvider<Map<String, dynamic>>((ref) => ref.read(tendersRepositoryProvider).agent());
final tenderSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) => ref.read(tendersRepositoryProvider).summary());
final tenderWorkspaceEvidenceProvider = FutureProvider.autoDispose.family<List<TenderRequirementEvidence>, String>((ref, workspaceId) => ref.read(tendersRepositoryProvider).evidence(workspaceId));

