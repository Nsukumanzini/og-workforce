import 'package:flutter_test/flutter_test.dart';
import 'package:og_workforce_ai/core/validation/validators.dart';
import 'package:og_workforce_ai/features/workspace/domain/workspace.dart';

void main() {
  group('registration validation', () {
    test('requires valid email and strong matching password', () {
      expect(Validators.email('invalid'), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('Goodpass1'), isNull);
      expect(Validators.confirmPassword('different', 'Goodpass1'), isNotNull);
      expect(Validators.confirmPassword('Goodpass1', 'Goodpass1'), isNull);
    });
  });

  test('workspace draft maps only expected RPC fields', () {
    const draft = WorkspaceDraft(
      businessName: 'Optimal Growth', businessType: 'Private company', industry: 'Information Technology',
      description: 'Business software', countryCode: 'ZA', region: 'Gauteng', city: 'Johannesburg',
      email: 'hello@example.test', phone: '+27110000000',
    );
    expect(draft.toRpc()['p_legal_name'], 'Optimal Growth');
    expect(draft.toRpc()['p_country_code'], 'ZA');
    expect(draft.toRpc().containsKey('user_id'), isFalse);
  });
}
