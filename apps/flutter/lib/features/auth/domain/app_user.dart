class AppUser {
  const AppUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;
}

enum AuthPhase { loading, signedOut, signedIn }

class AuthState {
  const AuthState({required this.phase, this.user, this.error});

  const AuthState.loading() : this(phase: AuthPhase.loading);
  const AuthState.signedOut() : this(phase: AuthPhase.signedOut);
  const AuthState.signedIn(AppUser user) : this(phase: AuthPhase.signedIn, user: user);

  final AuthPhase phase;
  final AppUser? user;
  final String? error;
}
