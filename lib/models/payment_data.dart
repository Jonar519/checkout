import '../utils/encryption_helper.dart';

class PaymentData {
  final int? id;
  final double totalPrice;
  final String paymentMethod;
  String? _cardNumber;
  String? _validUntil;
  String? _cvv;
  String? _cardHolder;
  final bool saveCardForFuture;
  final String promoCode;
  final DateTime paymentDate;
  final String? _transactionHash;

  PaymentData({
    this.id,
    required this.totalPrice,
    required this.paymentMethod,
    String? cardNumber,
    String? validUntil,
    String? cvv,
    String? cardHolder,
    required this.saveCardForFuture,
    required this.promoCode,
    required this.paymentDate,
    String? transactionHash,
  })  : _cardNumber = cardNumber,
        _validUntil = validUntil,
        _cvv = cvv,
        _cardHolder = cardHolder,
        _transactionHash = transactionHash;

  // Getter seguro para cardNumber
  String? get cardNumber {
    if (_cardNumber == null) return null;
    try {
      return EncryptionHelper().decryptText(_cardNumber!);
    } catch (e) {
      return _cardNumber;
    }
  }

  // Getter seguro para validUntil
  String? get validUntil {
    if (_validUntil == null) return null;
    try {
      return EncryptionHelper().decryptText(_validUntil!);
    } catch (e) {
      return _validUntil;
    }
  }

  // Getter seguro para cvv
  String? get cvv {
    if (_cvv == null) return null;
    try {
      return EncryptionHelper().decryptText(_cvv!);
    } catch (e) {
      return _cvv;
    }
  }

  // Getter seguro para cardHolder
  String? get cardHolder {
    if (_cardHolder == null) return null;
    try {
      return EncryptionHelper().decryptText(_cardHolder!);
    } catch (e) {
      return _cardHolder;
    }
  }

  String? get transactionHash => _transactionHash;

  // Versión segura para mostrar
  String getMaskedCardNumber() {
    if (_cardNumber == null) return 'N/A';
    final number = cardNumber;
    if (number == null) return '****';
    String cleaned = number.replaceAll(' ', '');
    if (cleaned.length <= 4) return cleaned;
    return '**** **** **** ${cleaned.substring(cleaned.length - 4)}';
  }

  Map<String, dynamic> toMap() {
    final encryptor = EncryptionHelper();
    return {
      'id': id,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'cardNumber': _cardNumber,
      'validUntil': _validUntil,
      'cvv': _cvv,
      'cardHolder': _cardHolder,
      'saveCardForFuture': saveCardForFuture ? 1 : 0,
      'promoCode': promoCode,
      'paymentDate': paymentDate.toIso8601String(),
      'transactionHash': _transactionHash,
    };
  }

  factory PaymentData.fromMap(Map<String, dynamic> map) {
    return PaymentData(
      id: map['id'],
      totalPrice: map['totalPrice'],
      paymentMethod: map['paymentMethod'] ?? 'Credit',
      cardNumber: map['cardNumber'],
      validUntil: map['validUntil'],
      cvv: map['cvv'],
      cardHolder: map['cardHolder'],
      saveCardForFuture: map['saveCardForFuture'] == 1,
      promoCode: map['promoCode'] ?? '',
      paymentDate: DateTime.parse(map['paymentDate']),
      transactionHash: map['transactionHash'],
    );
  }
}
