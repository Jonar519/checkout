class PaymentData {
  final int? id;
  final double totalPrice;
  final String paymentMethod;
  final String cardNumber;
  final String validUntil;
  final String cvv;
  final String cardHolder;
  final bool saveCardForFuture;
  final String promoCode;
  final DateTime paymentDate;

  PaymentData({
    this.id,
    required this.totalPrice,
    required this.paymentMethod,
    required this.cardNumber,
    required this.validUntil,
    required this.cvv,
    required this.cardHolder,
    required this.saveCardForFuture,
    required this.promoCode,
    required this.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'cardNumber': cardNumber,
      'validUntil': validUntil,
      'cvv': cvv,
      'cardHolder': cardHolder,
      'saveCardForFuture': saveCardForFuture ? 1 : 0,
      'promoCode': promoCode,
      'paymentDate': paymentDate.toIso8601String(),
    };
  }

  factory PaymentData.fromMap(Map<String, dynamic> map) {
    return PaymentData(
      id: map['id'],
      totalPrice: map['totalPrice'],
      paymentMethod: map['paymentMethod'] ?? 'Credit',
      cardNumber: map['cardNumber'] ?? '',
      validUntil: map['validUntil'] ?? '',
      cvv: map['cvv'] ?? '',
      cardHolder: map['cardHolder'] ?? '',
      saveCardForFuture: map['saveCardForFuture'] == 1,
      promoCode: map['promoCode'] ?? '',
      paymentDate: DateTime.parse(map['paymentDate']),
    );
  }
}
