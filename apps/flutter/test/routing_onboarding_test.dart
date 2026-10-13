import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:og_workforce_ai/app/routing/app_router.dart';
import 'package:og_workforce_ai/features/auth/domain/app_user.dart';
import 'package:og_workforce_ai/features/workspace/domain/workspace.dart';

void main() {
  const user = AppUser(id: 'user-a', email: 'a@example.test', displayName: 'User A');
  const signedIn = AuthState.signedIn(user);
  const signedOut = AuthState.signedOut();
  const noWorkspace = AsyncData<Workspace?>(null);
  const workspace = AsyncData<Workspace?>(Workspace(id: 'org-a', name: 'Org A', role: 'owner', onboardingComplete: true));

  test('unauthenticated users return to authentication routes', () {
    expect(appRouteRedirect(auth: signedOut, workspace: noWorkspace, path: '/dashboard'), '/welcome');
    expect(appRouteRedirect(auth: signedOut, workspace: noWorkspace, path: '/sign-in'), isNull);
  });

  test('authenticated users without a workspace cannot bypass onboarding', () {
    expect(appRouteRedirect(auth: signedIn, workspace: noWorkspace, path: '/dashboard'), '/onboarding');
    expect(appRouteRedirect(auth: signedIn, workspace: noWorkspace, path: '/onboarding'), isNull);
  });

  test('a completed workspace opens the dashboard and protects it after logout', () {
    expect(appRouteRedirect(auth: signedIn, workspace: workspace, path: '/onboarding'), '/dashboard');
    expect(appRouteRedirect(auth: signedIn, workspace: workspace, path: '/dashboard'), isNull);
    expect(appRouteRedirect(auth: signedOut, workspace: workspace, path: '/dashboard'), '/welcome');
  });

  test('loading state holds on splash and reset-password remains reachable', () {
    expect(appRouteRedirect(auth: const AuthState.loading(), workspace: noWorkspace, path: '/splash'), isNull);
    expect(appRouteRedirect(auth: signedIn, workspace: workspace, path: '/reset-password'), isNull);
  });
}
