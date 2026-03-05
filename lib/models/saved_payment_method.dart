import '../utils/encryption_helper.dart';

class SavedPaymentMethod {
  final int? id;
  final String paymentMethod;
  String? _cardNumber; // Privado para controlar acceso
  String? _cardHolder;
  String? _validUntil;
  String? _email;
  final double? balance;
  final bool isDefault;
  final DateTime savedDate;
  final String? _cardHash; // Hash para validación

  SavedPaymentMethod({
    this.id,
    required this.paymentMethod,
    String? cardNumber,
    String? cardHolder,
    String? validUntil,
    String? email,
    this.balance,
    required this.isDefault,
    required this.savedDate,
    String? cardHash,
  })  : _cardNumber = cardNumber,
        _cardHolder = cardHolder,
        _validUntil = validUntil,
        _email = email,
        _cardHash = cardHash;

  // Getter con desencriptación automática
  String? get cardNumber {
    if (_cardNumber == null) return null;
    try {
      return EncryptionHelper().decryptText(_cardNumber!);
    } catch (e) {
      return _cardNumber; // Fallback
    }
  }

  // Getter con desencriptación automática
  String? get cardHolder {
    if (_cardHolder == null) return null;
    try {
      return EncryptionHelper().decryptText(_cardHolder!);
    } catch (e) {
      return _cardHolder;
    }
  }

  // Getter con desencriptación automática
  String? get validUntil {
    if (_validUntil == null) return null;
    try {
      return EncryptionHelper().decryptText(_validUntil!);
    } catch (e) {
      return _validUntil;
    }
  }

  // Getter con desencriptación automática
  String? get email {
    if (_email == null) return null;
    try {
      return EncryptionHelper().decryptText(_email!);
    } catch (e) {
      return _email;
    }
  }

  // Getter para el hash
  String? get cardHash => _cardHash;

  // Método para obtener solo últimos 4 dígitos (seguro)
  String getLastFourDigits() {
    final number = cardNumber;
    if (number == null) return '****';
    String cleaned = number.replaceAll(' ', '');
    if (cleaned.length <= 4) return cleaned;
    return cleaned.substring(cleaned.length - 4);
  }

  // Versión enmascarada para mostrar
  String getMaskedDisplay() {
    if (paymentMethod == 'Credit' && cardNumber != null) {
      return '•••• ${getLastFourDigits()}';
    } else if (paymentMethod == 'PayPal' && email != null) {
      // Enmascarar email: j***@gmail.com
      final parts = email!.split('@');
      if (parts.length == 2) {
        String name = parts[0];
        if (name.length > 2) {
          name = '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}';
        }
        return '$name@${parts[1]}';
      }
      return email!;
    } else if (paymentMethod == 'Wallet') {
      return 'Wallet';
    }
    return paymentMethod;
  }

  Map<String, dynamic> toMap() {
    final encryptor = EncryptionHelper();
    return {
      'id': id,
      'paymentMethod': paymentMethod,
      'cardNumber': _cardNumber, // Ya encriptado
      'cardHolder': _cardHolder, // Ya encriptado
      'validUntil': _validUntil, // Ya encriptado
      'email': _email, // Ya encriptado
      'balance': balance,
      'isDefault': isDefault ? 1 : 0,
      'savedDate': savedDate.toIso8601String(),
      'cardHash': _cardHash,
    };
  }

  factory SavedPaymentMethod.fromMap(Map<String, dynamic> map) {
    return SavedPaymentMethod(
      id: map['id'],
      paymentMethod: map['paymentMethod'] ?? 'Credit',
      cardNumber: map['cardNumber'],
      cardHolder: map['cardHolder'],
      validUntil: map['validUntil'],
      email: map['email'],
      balance: map['balance'],
      isDefault: map['isDefault'] == 1,
      savedDate: DateTime.parse(map['savedDate']),
      cardHash: map['cardHash'],
    );
  }
}
