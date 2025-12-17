import 'package:flutter/widgets.dart';
import 'package:mosstroinform_mobile/l10n/app_localizations.dart';

/// Утилита для валидации email адресов
class EmailValidator {
  static const String _errorEmpty = 'email.empty';
  static const String _errorInvalid = 'email.invalid';

  /// Возвращает ключ ошибки или null, если email корректен
  static String? validate(String? email) {
    if (email == null || email.isEmpty || email.trim().isEmpty) {
      return _errorEmpty;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email.trim()) ? null : _errorInvalid;
  }
}

/// Локализует ключ ошибки в текст для пользователя
extension EmailValidationLocalizer on String? {
  String? localize(BuildContext context) {
    if (this == null) return null;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return this;

    switch (this) {
      case EmailValidator._errorEmpty:
        return l10n.enterEmail;
      case EmailValidator._errorInvalid:
        return l10n.enterValidEmail;
      default:
        return this;
    }
  }
}
