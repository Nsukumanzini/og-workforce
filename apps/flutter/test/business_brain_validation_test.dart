import 'package:flutter_test/flutter_test.dart';
import 'package:og_workforce_ai/features/business_brain/domain/business_brain_validators.dart';

void main() {
  test('validates product and service numeric limits', () {
    expect(BusinessBrainValidators.nonNegative('-1'), isNotNull);
    expect(BusinessBrainValidators.nonNegative('100'), isNull);
    expect(BusinessBrainValidators.percentage('101'), isNotNull);
    expect(BusinessBrainValidators.percentage('25'), isNull);
  });
  test('validates optional contact email and currency', () {
    expect(BusinessBrainValidators.optionalEmail(''), isNull);
    expect(BusinessBrainValidators.optionalEmail('bad'), isNotNull);
    expect(BusinessBrainValidators.currency('ZAR'), isNull);
    expect(BusinessBrainValidators.currency('rand'), isNotNull);
  });
  test('validates document type and size', () {
    expect(BusinessBrainValidators.documentType('policy.PDF'), isNull);
    expect(BusinessBrainValidators.documentType('secret.exe'), isNotNull);
    expect(BusinessBrainValidators.documentSize(10 * 1024 * 1024), isNull);
    expect(BusinessBrainValidators.documentSize(10 * 1024 * 1024 + 1), isNotNull);
  });
}
