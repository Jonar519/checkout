import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_data.dart';
import '../models/saved_payment_method.dart';
import '../database/database_helper.dart';
import '../utils/encryption_helper.dart';
import '../widgets/custom_button.dart';
import 'payment_confirmation_screen.dart';

class PaymentDataScreen extends StatefulWidget {
  final double totalPrice;

  const PaymentDataScreen({Key? key, required this.totalPrice})
      : super(key: key);

  @override
  _PaymentDataScreenState createState() => _PaymentDataScreenState();
}

class _PaymentDataScreenState extends State<PaymentDataScreen> {
  String _selectedPaymentMethod = 'Credit';
  bool _useSavedMethod = false;
  SavedPaymentMethod? _selectedSavedMethod;
  List<SavedPaymentMethod> _savedMethods = [];

  final _cardNumberController = TextEditingController();
  final _validUntilController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _paypalEmailController = TextEditingController();
  bool _saveCardForFuture = false;

  final List<String> _paymentMethods = ['PayPal', 'Credit', 'Wallet'];
  final EncryptionHelper _encryptor = EncryptionHelper();

  @override
  void initState() {
    super.initState();
    _initializeEncryption();
  }

  Future<void> _initializeEncryption() async {
    await _encryptor.initialize();
    _loadSavedMethods();
    _setupCardNumberFormatter();
    _setupValidUntilFormatter();
  }

  Future<void> _loadSavedMethods() async {
    final methods = await DatabaseHelper().getSavedPaymentMethods();
    setState(() {
      _savedMethods = methods;
      if (methods.isNotEmpty) {
        _selectedSavedMethod = methods.firstWhere(
          (m) => m.isDefault,
          orElse: () => methods.first,
        );
      }
    });
  }

  void _setupCardNumberFormatter() {
    _cardNumberController.addListener(() {
      String text = _cardNumberController.text.replaceAll(' ', '');
      if (text.length > 16) {
        text = text.substring(0, 16);
      }

      String formatted = '';
      for (int i = 0; i < text.length; i++) {
        if (i > 0 && i % 4 == 0) {
          formatted += ' ';
        }
        formatted += text[i];
      }

      if (_cardNumberController.text != formatted) {
        _cardNumberController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  void _setupValidUntilFormatter() {
    _validUntilController.addListener(() {
      String text = _validUntilController.text.replaceAll('/', '');
      if (text.length > 4) {
        text = text.substring(0, 4);
      }

      String formatted = '';
      for (int i = 0; i < text.length; i++) {
        if (i == 2) {
          formatted += '/';
        }
        formatted += text[i];
      }

      if (_validUntilController.text != formatted) {
        _validUntilController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  String _formatPrice(double price) {
    try {
      final formatter = NumberFormat.currency(
        locale: 'es_CO',
        symbol: '\$',
        decimalDigits: 0,
      );
      return formatter.format(price);
    } catch (e) {
      String priceStr = price.toStringAsFixed(0);
      String formatted = '';
      int count = 0;
      for (int i = priceStr.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) {
          formatted = '.$formatted';
        }
        formatted = priceStr[i] + formatted;
        count++;
      }
      return '\$ $formatted';
    }
  }

  Widget _buildSavedMethodsSection() {
    if (_savedMethods.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Métodos guardados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._savedMethods.map((method) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSavedMethod = method;
                  _useSavedMethod = true;
                  _selectedPaymentMethod = method.paymentMethod;

                  // Mostrar solo últimos dígitos por seguridad
                  if (method.paymentMethod == 'Credit') {
                    _cardNumberController.text = method.getMaskedDisplay();
                    _cardHolderController.text = method.cardHolder ?? '';
                    _validUntilController.text = method.validUntil ?? '';
                  } else if (method.paymentMethod == 'PayPal') {
                    _paypalEmailController.text = method.email ?? '';
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedSavedMethod?.id == method.id
                      ? Colors.blue
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedSavedMethod?.id == method.id
                        ? Colors.blue
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      method.paymentMethod == 'PayPal'
                          ? Icons.payment
                          : method.paymentMethod == 'Wallet'
                              ? Icons.account_balance_wallet
                              : Icons.credit_card,
                      color: _selectedSavedMethod?.id == method.id
                          ? Colors.white
                          : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.getMaskedDisplay(),
                            style: TextStyle(
                              color: _selectedSavedMethod?.id == method.id
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (method.paymentMethod == 'Credit' &&
                              method.cardHolder != null)
                            Text(
                              method.cardHolder!,
                              style: TextStyle(
                                color: _selectedSavedMethod?.id == method.id
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (method.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedSavedMethod?.id == method.id
                              ? Colors.white
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            color: _selectedSavedMethod?.id == method.id
                                ? Colors.orange
                                : Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          if (_useSavedMethod)
            TextButton(
              onPressed: () {
                setState(() {
                  _useSavedMethod = false;
                  _selectedSavedMethod = null;
                  _clearFields();
                });
              },
              child: const Text('Usar nuevo método'),
            ),
        ],
      ),
    );
  }

  void _clearFields() {
    _cardNumberController.clear();
    _validUntilController.clear();
    _cvvController.clear();
    _cardHolderController.clear();
    _paypalEmailController.clear();
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _paymentMethods.map((method) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method;
                    _useSavedMethod = false;
                    _selectedSavedMethod = null;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == method && !_useSavedMethod
                        ? Colors.blue
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _selectedPaymentMethod == method && !_useSavedMethod
                              ? Colors.blue
                              : Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedPaymentMethod == method && !_useSavedMethod)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      Text(
                        method,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedPaymentMethod == method &&
                                  !_useSavedMethod
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPayPalContent() {
    if (_useSavedMethod && _selectedSavedMethod != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          children: [
            const Icon(Icons.payment, size: 50, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              _selectedSavedMethod!.getMaskedDisplay(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Método guardado'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.payment, size: 50, color: Colors.blue),
          const SizedBox(height: 12),
          const Text(
            'PayPal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _paypalEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'tu@email.com',
              labelText: 'Email de PayPal',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Serás redirigido a PayPal para completar el pago',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet,
              size: 50, color: Colors.green),
          const SizedBox(height: 12),
          const Text(
            'Wallet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Paga con tu saldo disponible en Wallet',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo disponible:'),
                Text(
                  _formatPrice(500000),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardContent() {
    if (_useSavedMethod && _selectedSavedMethod != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            const Icon(Icons.credit_card, size: 50, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              _selectedSavedMethod!.getMaskedDisplay(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedSavedMethod!.cardHolder ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Vence: ${_selectedSavedMethod!.validUntil}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Datos encriptados',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Text(
          'Card number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          maxLength: 19,
          obscureText: true, // Ocultar mientras se escribe
          decoration: InputDecoration(
            hintText: '**** **** **** ****',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.credit_card),
            counterText: '',
          ),
          onChanged: (value) {
            String filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (filtered.length > 16) filtered = filtered.substring(0, 16);

            String formatted = '';
            for (int i = 0; i < filtered.length; i++) {
              if (i > 0 && i % 4 == 0) formatted += ' ';
              formatted += filtered[i];
            }

            if (value != formatted) {
              _cardNumberController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Valid until',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _validUntilController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      counterText: '',
                    ),
                    onChanged: (value) {
                      String filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (filtered.length > 4)
                        filtered = filtered.substring(0, 4);

                      String formatted = '';
                      for (int i = 0; i < filtered.length; i++) {
                        if (i == 2) formatted += '/';
                        formatted += filtered[i];
                      }

                      if (value != formatted) {
                        _validUntilController.value = TextEditingValue(
                          text: formatted,
                          selection:
                              TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CVV',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 3,
                    decoration: InputDecoration(
                      hintText: '***',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      counterText: '',
                    ),
                    onChanged: (value) {
                      String filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (filtered.length > 3)
                        filtered = filtered.substring(0, 3);

                      if (value != filtered) {
                        _cvvController.value = TextEditingValue(
                          text: filtered,
                          selection:
                              TextSelection.collapsed(offset: filtered.length),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Card holder',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _cardHolderController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Your name and surname',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _saveCardForFuture,
              onChanged: (value) {
                setState(() {
                  _saveCardForFuture = value ?? false;
                });
              },
            ),
            const Expanded(
              child: Text(
                'Save card data for future payments',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _validateFields() {
    if (_useSavedMethod && _selectedSavedMethod != null) {
      return true;
    }

    if (_selectedPaymentMethod == 'PayPal') {
      if (_paypalEmailController.text.isEmpty) {
        _showError('Por favor ingresa tu email de PayPal');
        return false;
      }
      if (!_paypalEmailController.text.contains('@')) {
        _showError('Por favor ingresa un email válido');
        return false;
      }
      return true;
    }

    if (_selectedPaymentMethod == 'Wallet') {
      return true;
    }

    String cardNumber = _cardNumberController.text.replaceAll(' ', '');
    if (cardNumber.length != 16) {
      _showError('El número de tarjeta debe tener 16 dígitos');
      return false;
    }

    String validUntil = _validUntilController.text.replaceAll('/', '');
    if (validUntil.length != 4) {
      _showError('La fecha de expiración debe ser MM/YY');
      return false;
    }

    int month = int.parse(validUntil.substring(0, 2));
    if (month < 1 || month > 12) {
      _showError('El mes debe estar entre 01 y 12');
      return false;
    }

    int year = int.parse('20${validUntil.substring(2, 4)}');
    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      _showError('La tarjeta está vencida');
      return false;
    }

    if (_cvvController.text.length != 3) {
      _showError('El CVV debe tener 3 dígitos');
      return false;
    }

    if (_cardHolderController.text.isEmpty) {
      _showError('El nombre del titular es requerido');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_validateFields()) return;

    PaymentData payment;

    if (_useSavedMethod && _selectedSavedMethod != null) {
      // Usar método guardado (los datos ya están encriptados)
      payment = PaymentData(
        totalPrice: widget.totalPrice,
        paymentMethod: _selectedSavedMethod!.paymentMethod,
        cardNumber: _selectedSavedMethod!.cardNumber,
        validUntil: _selectedSavedMethod!.validUntil,
        cvv: '***', // No guardamos CVV
        cardHolder: _selectedSavedMethod!.cardHolder,
        saveCardForFuture: false,
        promoCode: '',
        paymentDate: DateTime.now(),
      );
    } else {
      // Encriptar datos antes de guardar
      String? encryptedCardNumber;
      String? encryptedValidUntil;
      String? encryptedCvv;
      String? encryptedCardHolder;
      String? encryptedEmail;
      String? cardHash;

      if (_selectedPaymentMethod == 'Credit') {
        encryptedCardNumber =
            _encryptor.encryptText(_cardNumberController.text);
        encryptedValidUntil =
            _encryptor.encryptText(_validUntilController.text);
        encryptedCvv = _encryptor.encryptText(_cvvController.text);
        encryptedCardHolder =
            _encryptor.encryptText(_cardHolderController.text);
        cardHash = _encryptor.hashData(_cardNumberController.text);
      } else if (_selectedPaymentMethod == 'PayPal') {
        encryptedEmail = _encryptor.encryptText(_paypalEmailController.text);
      }

      payment = PaymentData(
        totalPrice: widget.totalPrice,
        paymentMethod: _selectedPaymentMethod,
        cardNumber: encryptedCardNumber,
        validUntil: encryptedValidUntil,
        cvv: encryptedCvv,
        cardHolder: encryptedCardHolder,
        saveCardForFuture: _saveCardForFuture,
        promoCode: '',
        paymentDate: DateTime.now(),
      );

      // Guardar método para futuro si se solicita
      if (_saveCardForFuture) {
        final savedMethod = SavedPaymentMethod(
          paymentMethod: _selectedPaymentMethod,
          cardNumber: encryptedCardNumber,
          cardHolder: encryptedCardHolder,
          validUntil: encryptedValidUntil,
          email: encryptedEmail,
          balance: _selectedPaymentMethod == 'Wallet' ? 500000.0 : null,
          isDefault: _savedMethods.isEmpty,
          savedDate: DateTime.now(),
          cardHash: cardHash,
        );
        await DatabaseHelper().insertSavedPaymentMethod(savedMethod);
      }
    }

    await DatabaseHelper().insertPayment(payment);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationScreen(
          payment: payment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Data'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total price',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(widget.totalPrice),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSavedMethodsSection(),
            if (!_useSavedMethod) ...[
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),
            ],
            if (_selectedPaymentMethod == 'PayPal') ...[
              _buildPayPalContent(),
            ] else if (_selectedPaymentMethod == 'Wallet') ...[
              _buildWalletContent(),
            ] else ...[
              _buildCreditCardContent(),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'Proceed to confirm',
              onPressed: _processPayment,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _validUntilController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _paypalEmailController.dispose();
    super.dispose();
  }
}
