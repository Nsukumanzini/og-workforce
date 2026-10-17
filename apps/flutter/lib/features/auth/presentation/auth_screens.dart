// The post-await navigation is guarded by State.mounted in each handler.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/theme/workforce_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/validation/validators.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key, required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 490),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(color: WorkforceTheme.mint, borderRadius: BorderRadius.circular(16)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.hub_rounded, color: WorkforceTheme.forest, size: 21),
                  SizedBox(width: 9),
                  Text('OG WORKFORCE', style: TextStyle(color: WorkforceTheme.forestDeep, fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
                ]),
              )),
              const SizedBox(height: 30),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 25),
              Card(
                child: Padding(padding: const EdgeInsets.all(22), child: child),
              ),
              const SizedBox(height: 18),
              Text('A clearer way to run your business.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      ),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthPage(title: 'Work smarter, together.', subtitle: 'Build your business workspace and prepare your AI workforce.', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    FilledButton(onPressed: () => context.go('/sign-up'), child: const Text('Create account')),
    const SizedBox(height: 12), OutlinedButton(onPressed: () => context.go('/sign-in'), child: const Text('Sign in')),
  ]));
}

class SignInScreen extends ConsumerStatefulWidget { const SignInScreen({super.key}); @override ConsumerState<SignInScreen> createState() => _SignInScreenState(); }
class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>(); final _email = TextEditingController(); final _password = TextEditingController(); bool _busy = false;
  @override void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }
  Future<void> _submit() async { if (!_form.currentState!.validate()) return; setState(() => _busy = true); try { await ref.read(authControllerProvider.notifier).signIn(_email.text, _password.text); } on AppFailure catch (e) { if (mounted) _message(e.message); } finally { if (mounted) setState(() => _busy = false); } }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override Widget build(BuildContext context) => AuthPage(title: 'Welcome back', subtitle: 'Sign in to your workspace.', child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    TextFormField(controller: _email, validator: Validators.email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address')), const SizedBox(height: 16),
    TextFormField(controller: _password, validator: (v) => Validators.required(v, label: 'Password'), obscureText: true, decoration: const InputDecoration(labelText: 'Password')), const SizedBox(height: 8),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.go('/forgot-password'), child: const Text('Forgot password?'))), const SizedBox(height: 12),
    FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const CircularProgressIndicator() : const Text('Sign in')),
    TextButton(onPressed: () => context.go('/sign-up'), child: const Text('Create an account')),
  ])));
}

class SignUpScreen extends ConsumerStatefulWidget { const SignUpScreen({super.key}); @override ConsumerState<SignUpScreen> createState() => _SignUpScreenState(); }
class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>(); final _name = TextEditingController(); final _email = TextEditingController(); final _password = TextEditingController(); final _confirm = TextEditingController(); bool _accepted = false; bool _busy = false;
  @override void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }
  Future<void> _submit() async {
    if (!_form.currentState!.validate() || !_accepted) {
      if (!_accepted) _message('Accept the Terms and Privacy Policy to continue.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).signUp(_name.text, _email.text, _password.text);
      if (mounted) _message('Account created. If this environment requires email confirmation, check your inbox before signing in.');
    } catch (error) {
      _logSignupFailure(error);
      if (mounted) {
        _message(error is AppFailure
            ? error.message
            : 'We could not reach the signup service. Open the browser console for a safe diagnostic.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _logSignupFailure(Object error) {
    final technicalMessage = error is AppFailure
        ? (error.technicalMessage ?? error.message)
        : error.toString();
    var safeMessage = technicalMessage;
    for (final value in [_name.text, _email.text, _password.text, _confirm.text]) {
      if (value.isNotEmpty) safeMessage = safeMessage.replaceAll(value, '[redacted]');
    }
    safeMessage = safeMessage
        .replaceAll(RegExp(r'https?://[^\s?]+\?[^\s]+'), '[URL with query redacted]')
        .replaceAll(RegExp(r'\beyJ[a-zA-Z0-9_-]{8,}\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\b'), '[token redacted]')
        .replaceAll(RegExp(r'\bsb_(publishable|secret)_[a-zA-Z0-9_-]+\b'), '[Supabase key redacted]')
        .replaceAll(RegExp(r'authorization\s*[:=]\s*(?:bearer\s+)?[^\s,;]+(?:\s+[^\s,;]+)?', caseSensitive: false), '[authorization redacted]')
        .replaceAll(RegExp(r'(apikey|access_token|refresh_token|password|secret_key)\s*[:=]\s*["\x27]?[^\s,;"\x27}]+["\x27]?', caseSensitive: false), '[credential redacted]');
    debugPrint('[signup] Supabase signup request failed (${error.runtimeType}): $safeMessage');
    debugPrint('[signup] Diagnosis hints: net::ERR_NAME_NOT_RESOLVED means hostname/DNS resolution failed; '
        'CORS errors mean the API did not allow this site origin; HTTP 4xx/5xx details indicate a server response.');
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override Widget build(BuildContext context) => AuthPage(title: 'Create your account', subtitle: 'Start with your identity. Business details come next.', child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    TextFormField(controller: _name, validator: (v) => Validators.required(v, label: 'Full name'), textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name')), const SizedBox(height: 16),
    TextFormField(controller: _email, validator: Validators.email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address')), const SizedBox(height: 16),
    TextFormField(controller: _password, validator: Validators.password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')), const SizedBox(height: 16),
    TextFormField(controller: _confirm, validator: (v) => Validators.confirmPassword(v, _password.text), obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')), const SizedBox(height: 8),
    CheckboxListTile(value: _accepted, onChanged: (v) => setState(() => _accepted = v ?? false), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, title: const Text('I accept the Terms and Privacy Policy.')),
    const SizedBox(height: 12), FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const CircularProgressIndicator() : const Text('Create account')),
    TextButton(onPressed: () => context.go('/sign-in'), child: const Text('Already have an account? Sign in')),
  ])));
}

class ForgotPasswordScreen extends ConsumerStatefulWidget { const ForgotPasswordScreen({super.key}); @override ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState(); }
class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> { final _form = GlobalKey<FormState>(); final _email = TextEditingController(); bool _sent = false; @override void dispose() { _email.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AuthPage(title: 'Reset your password', subtitle: _sent ? 'Check your inbox for a reset link.' : 'Enter the email address for your account.', child: _sent ? FilledButton(onPressed: () => context.go('/sign-in'), child: const Text('Back to sign in')) : Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [TextFormField(controller: _email, validator: Validators.email, decoration: const InputDecoration(labelText: 'Email address')), const SizedBox(height: 20), FilledButton(onPressed: () async { if (_form.currentState!.validate()) { try { await ref.read(authControllerProvider.notifier).reset(_email.text); if (mounted) setState(() => _sent = true); } on AppFailure catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); } } }, child: const Text('Send reset link'))])));
}

class ResetPasswordScreen extends ConsumerStatefulWidget { const ResetPasswordScreen({super.key}); @override ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState(); }
class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> { final _form = GlobalKey<FormState>(); final _password = TextEditingController(); final _confirm = TextEditingController(); @override void dispose() { _password.dispose(); _confirm.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AuthPage(title: 'Choose a new password', subtitle: 'Use a strong, unique password.', child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [TextFormField(controller: _password, obscureText: true, validator: Validators.password, decoration: const InputDecoration(labelText: 'New password')), const SizedBox(height: 16), TextFormField(controller: _confirm, obscureText: true, validator: (v) => Validators.confirmPassword(v, _password.text), decoration: const InputDecoration(labelText: 'Confirm password')), const SizedBox(height: 20), FilledButton(onPressed: () async { if (_form.currentState!.validate()) { try { await ref.read(authControllerProvider.notifier).updatePassword(_password.text); if (mounted) context.go('/dashboard'); } on AppFailure catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); } } }, child: const Text('Update password'))])));
}
