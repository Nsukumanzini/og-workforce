class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? required(String? value, {String label = 'This field'}) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  static String? email(String? value) =>
      !(_email.hasMatch(value?.trim() ?? '')) ? 'Enter a valid email address.' : null;

  static String? password(String? value) {
    if ((value?.length ?? 0) < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(value!)) return 'Include an uppercase letter.';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include a number.';
    return null;
  }

  static String? confirmPassword(String? value, String password) =>
      value != password ? 'Passwords do not match.' : null;

  static String? country(String? value) =>
      value == null || value.length != 2 ? 'Choose a country.' : null;
}
