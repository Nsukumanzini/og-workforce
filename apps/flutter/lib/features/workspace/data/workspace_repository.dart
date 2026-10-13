import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/workspace.dart';

abstract class WorkspaceRepository {
  Future<Workspace?> currentWorkspace(String userId);
  Future<Workspace> createInitialWorkspace(WorkspaceDraft draft);
}

class SupabaseWorkspaceRepository implements WorkspaceRepository {
  SupabaseWorkspaceRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<Workspace?> currentWorkspace(String userId) async {
    final row = await _client.from('organisation_members').select(
      'organisation_id, role_key, organisations!inner(id, legal_name, business_profiles(onboarding_completed_at))',
    ).eq('user_id', userId).eq('status', 'active').limit(1).maybeSingle();
    if (row == null) return null;
    final organisation = row['organisations'] as Map<String, dynamic>;
    final profileData = organisation['business_profiles'];
    final profile = profileData is Map<String, dynamic>
        ? profileData
        : profileData is List && profileData.isNotEmpty
            ? profileData.first as Map<String, dynamic>
            : null;
    return Workspace(
      id: row['organisation_id'] as String,
      name: organisation['legal_name'] as String,
      role: row['role_key'] as String,
      onboardingComplete: profile?['onboarding_completed_at'] != null,
    );
  }

  @override
  Future<Workspace> createInitialWorkspace(WorkspaceDraft draft) async {
    try {
      final id = await _client.rpc('create_initial_workspace', params: draft.toRpc()) as String;
      final user = _client.auth.currentUser;
      final workspace = user == null ? null : await currentWorkspace(user.id);
      if (workspace == null || workspace.id != id) throw const AppFailure('Your workspace was created but could not be loaded. Please refresh.');
      return workspace;
    } on PostgrestException catch (error) {
      throw AppFailure('We could not create the workspace. Please review your details and try again.', technicalMessage: error.message);
    }
  }
}

class UnconfiguredWorkspaceRepository implements WorkspaceRepository {
  const UnconfiguredWorkspaceRepository();
  @override Future<Workspace?> currentWorkspace(String userId) async => null;
  @override Future<Workspace> createInitialWorkspace(WorkspaceDraft draft) =>
      Future.error(const AppFailure('Workspace creation is not configured for this build.'));
}
