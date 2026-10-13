import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/app_user.dart';
import '../features/workspace/data/workspace_repository.dart';
import '../features/workspace/domain/workspace.dart';
import '../features/business_brain/data/business_brain_repository.dart';
import '../features/agents/data/business_assistant_repository.dart';
final businessAssistantRepositoryProvider = Provider<BusinessAssistantRepository>((_) => throw UnimplementedError());

final authRepositoryProvider = Provider<AuthRepository>((_) => const UnconfiguredAuthRepository());
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((_) => const UnconfiguredWorkspaceRepository());
final businessBrainRepositoryProvider = Provider<BusinessBrainRepository>((_) => const UnconfiguredBusinessBrainRepository());
final businessBrainSnapshotProvider = FutureProvider<BusinessBrainSnapshot?>((ref) async {
  final workspace = ref.watch(workspaceControllerProvider).value;
  if (workspace == null) return null;
  return ref.read(businessBrainRepositoryProvider).loadSnapshot(workspace.id);
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
final workspaceControllerProvider = AsyncNotifierProvider<WorkspaceController, Workspace?>(WorkspaceController.new);

class AuthController extends AsyncNotifier<AuthState> {
  StreamSubscription<AppUser?>? _subscription;
  @override
  Future<AuthState> build() async {
    final repository = ref.read(authRepositoryProvider);
    _subscription = repository.authChanges().listen((user) {
      state = AsyncData(user == null ? const AuthState.signedOut() : AuthState.signedIn(user));
      ref.invalidate(workspaceControllerProvider);
    });
    ref.onDispose(() => _subscription?.cancel());
    final user = repository.currentUser;
    return user == null ? const AuthState.signedOut() : AuthState.signedIn(user);
  }

  Future<void> signIn(String email, String password) => _run(() => ref.read(authRepositoryProvider).signIn(email: email, password: password));
  Future<void> signUp(String name, String email, String password) => _run(() => ref.read(authRepositoryProvider).signUp(fullName: name, email: email, password: password));
  Future<void> reset(String email) => _run(() => ref.read(authRepositoryProvider).sendPasswordReset(email));
  Future<void> updatePassword(String password) => _run(() => ref.read(authRepositoryProvider).updatePassword(password));
  Future<void> signOut() async { await ref.read(authRepositoryProvider).signOut(); ref.invalidate(workspaceControllerProvider); }

  Future<void> _run(Future<void> Function() operation) async {
    try { await operation(); } on AppFailure catch (error, stack) { state = AsyncError(error, stack); rethrow; }
  }
}

class WorkspaceController extends AsyncNotifier<Workspace?> {
  @override
  Future<Workspace?> build() async {
    final auth = await ref.watch(authControllerProvider.future);
    if (auth.user == null) return null;
    return ref.read(workspaceRepositoryProvider).currentWorkspace(auth.user!.id);
  }

  Future<void> create(WorkspaceDraft draft) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(workspaceRepositoryProvider).createInitialWorkspace(draft));
  }
}
