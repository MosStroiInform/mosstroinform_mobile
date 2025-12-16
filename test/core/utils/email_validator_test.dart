import 'package:flutter_test/flutter_test.dart';
import 'package:mosstroinform_mobile/core/utils/email_validator.dart';

void main() {
  group('EmailValidator', () {
    group('validate', () {
      test('возвращает null для валидных email адресов', () {
        expect(EmailValidator.validate('test@example.com'), isNull);
        expect(EmailValidator.validate('user.name@example.com'), isNull);
        expect(EmailValidator.validate('user+tag@example.com'), isNull);
        expect(EmailValidator.validate('user_name@example.com'), isNull);
        expect(EmailValidator.validate('user123@example.com'), isNull);
        expect(EmailValidator.validate('test.email@example.co.uk'), isNull);
        expect(EmailValidator.validate('user@subdomain.example.com'), isNull);
        expect(EmailValidator.validate('a@b.co'), isNull);
        expect(EmailValidator.validate('test.email+tag@example-domain.com'), isNull);
        expect(EmailValidator.validate('user_name123@example-domain.co.uk'), isNull);
      });

      test('возвращает ключ ошибки для невалидных email адресов', () {
        expect(EmailValidator.validate('invalid'), 'email.invalid');
        expect(EmailValidator.validate('invalid@'), 'email.invalid');
        expect(EmailValidator.validate('@example.com'), 'email.invalid');
        expect(EmailValidator.validate('invalid@example'), 'email.invalid');
        expect(EmailValidator.validate('invalid@.com'), 'email.invalid');
        expect(EmailValidator.validate('invalid@example.'), 'email.invalid');
        expect(EmailValidator.validate('invalid@example.c'), 'email.invalid');
        expect(EmailValidator.validate('invalid @example.com'), 'email.invalid');
        expect(EmailValidator.validate('invalid@ example.com'), 'email.invalid');
        expect(EmailValidator.validate('invalid@@example.com'), 'email.invalid');
        expect(EmailValidator.validate('invalid@example@com'), 'email.invalid');
      });

      test('возвращает ключ ошибки для null значения', () {
        expect(EmailValidator.validate(null), 'email.empty');
      });

      test('возвращает ключ ошибки для пустой строки', () {
        expect(EmailValidator.validate(''), 'email.empty');
      });

      test('возвращает ключ ошибки для строки только с пробелами', () {
        expect(EmailValidator.validate('   '), 'email.empty');
        expect(EmailValidator.validate('\t'), 'email.empty');
        expect(EmailValidator.validate('\n'), 'email.empty');
      });

      test('возвращает null для email с пробелами в начале и конце', () {
        expect(EmailValidator.validate('  test@example.com  '), isNull);
        expect(EmailValidator.validate('\ttest@example.com\t'), isNull);
        expect(EmailValidator.validate('\ntest@example.com\n'), isNull);
      });

      test('возвращает ключ ошибки для email с пробелами внутри', () {
        expect(EmailValidator.validate('test @example.com'), 'email.invalid');
        expect(EmailValidator.validate('test@ example.com'), 'email.invalid');
        expect(EmailValidator.validate('test @ example.com'), 'email.invalid');
        expect(EmailValidator.validate('test@example .com'), 'email.invalid');
      });

      test('возвращает ключ ошибки для email без домена верхнего уровня', () {
        expect(EmailValidator.validate('test@example'), 'email.invalid');
        expect(EmailValidator.validate('test@example.'), 'email.invalid');
      });

      test('возвращает ключ ошибки для email с слишком коротким доменом верхнего уровня', () {
        expect(EmailValidator.validate('test@example.c'), 'email.invalid');
      });

      test('возвращает null для email с длинным доменом верхнего уровня', () {
        expect(EmailValidator.validate('test@example.info'), isNull);
        expect(EmailValidator.validate('test@example.museum'), isNull);
        expect(EmailValidator.validate('test@example.travel'), isNull);
      });

      test('возвращает ключ ошибки для email с специальными символами в неправильных местах', () {
        expect(EmailValidator.validate('test@@example.com'), 'email.invalid');
        expect(EmailValidator.validate('test@example@com'), 'email.invalid');
      });

      test('возвращает null для email с точками в локальной части', () {
        expect(EmailValidator.validate('first.last@example.com'), isNull);
        expect(EmailValidator.validate('first.middle.last@example.com'), isNull);
      });

      test('возвращает null для email с подчеркиваниями', () {
        expect(EmailValidator.validate('user_name@example.com'), isNull);
        expect(EmailValidator.validate('user_name_123@example.com'), isNull);
      });

      test('возвращает null для email с дефисами в домене', () {
        expect(EmailValidator.validate('test@example-domain.com'), isNull);
        expect(EmailValidator.validate('test@sub-domain.example.com'), isNull);
      });
    });
  });
}


