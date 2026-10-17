import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/app_user.dart';

abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> authChanges();
  Future<void> signUp({required String fullName, required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);
  final SupabaseClient _client;

  @override
  AppUser? get currentUser => _map(_client.auth.currentUser);

  @override
  Stream<AppUser?> authChanges() =>
      _client.auth.onAuthStateChange.map((event) => _map(event.session?.user));

  @override
  Future<void> signUp({required String fullName, required String email, required String password}) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(), password: password, data: {'full_name': fullName.trim()},
      );
      if (response.user == null) throw const AppFailure('We could not create your account.');
    } on AuthException catch (error) {
      throw AppFailure(_friendly(error.message), technicalMessage: error.toString());
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException catch (error) {
      throw AppFailure(_friendly(error.message), technicalMessage: error.message);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim(), redirectTo: 'ogworkforce://reset-password');
    } on AuthException catch (error) {
      throw AppFailure(_friendly(error.message), technicalMessage: error.message);
    }
  }

  @override
  Future<void> updatePassword(String password) => _client.auth.updateUser(UserAttributes(password: password));

  @override
  Future<void> signOut() => _client.auth.signOut();

  AppUser? _map(User? user) => user == null
      ? null
      : AppUser(id: user.id, email: user.email ?? '', displayName: user.userMetadata?['full_name'] as String?);

  String _friendly(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login')) return 'Incorrect email address or password.';
    if (lower.contains('already registered')) return 'An account already exists for this email address.';
    if (lower.contains('password')) return 'Choose a stronger password and try again.';
    return 'We could not complete that request. Please try again.';
  }
}

class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();
  @override
  AppUser? get currentUser => null;
  @override
  Stream<AppUser?> authChanges() => const Stream.empty();
  AppFailure get _failure => const AppFailure('Authentication is not configured for this build.');
  @override Future<void> signIn({required String email, required String password}) => Future.error(_failure);
  @override Future<void> signOut() => Future.value();
  @override Future<void> signUp({required String fullName, required String email, required String password}) => Future.error(_failure);
  @override Future<void> sendPasswordReset(String email) => Future.error(_failure);
  @override Future<void> updatePassword(String password) => Future.error(_failure);
}
