import '../../../core/validation/validators.dart';

class BusinessBrainValidators {
  static String? nonNegative(String? value, {String label = 'Value'}) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || number < 0 ? '$label must be zero or greater.' : null;
  }
  static String? percentage(String? value, {String label = 'Percentage'}) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || number < 0 || number > 100 ? '$label must be between 0 and 100.' : null;
  }
  static String? optionalEmail(String? value) => value == null || value.trim().isEmpty ? null : Validators.email(value);
  static String? currency(String? value) => value == null || !RegExp(r'^[A-Z]{3}$').hasMatch(value.trim()) ? 'Use a three-letter currency code.' : null;
  static String? documentType(String name) => RegExp(r'\.(pdf|docx|xlsx|png|jpe?g)$', caseSensitive: false).hasMatch(name) ? null : 'Unsupported document type.';
  static String? documentSize(int bytes) => bytes > 10 * 1024 * 1024 ? 'Documents must be 10 MB or smaller.' : null;
}
