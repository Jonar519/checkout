class SavedPaymentMethod {
  final int? id;
  final String paymentMethod;
  final String? cardNumber;
  final String? cardHolder;
  final String? validUntil;
  final String? email;
  final double? balance;
  final bool isDefault;
  final DateTime savedDate;

  SavedPaymentMethod({
    this.id,
    required this.paymentMethod,
    this.cardNumber,
    this.cardHolder,
    this.validUntil,
    this.email,
    this.balance,
    required this.isDefault,
    required this.savedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentMethod': paymentMethod,
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'validUntil': validUntil,
      'email': email,
      'balance': balance,
      'isDefault': isDefault ? 1 : 0,
      'savedDate': savedDate.toIso8601String(),
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
    );
  }

  String getDisplayName() {
    if (paymentMethod == 'Credit' && cardNumber != null) {
      return '•••• ${cardNumber!.replaceAll(' ', '').substring(cardNumber!.length - 4)}';
    } else if (paymentMethod == 'PayPal' && email != null) {
      return email!;
    } else if (paymentMethod == 'Wallet') {
      return 'Wallet';
    }
    return paymentMethod;
  }
}
