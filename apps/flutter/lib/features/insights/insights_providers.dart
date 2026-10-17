import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/workspace_insights_repository.dart';

final workspaceInsightsRepositoryProvider = Provider<WorkspaceInsightsRepository>((ref) => throw UnimplementedError());
final integrationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) => ref.read(workspaceInsightsRepositoryProvider).integrations());
final workspaceReportProvider = FutureProvider<Map<String, dynamic>>((ref) => ref.read(workspaceInsightsRepositoryProvider).report());
