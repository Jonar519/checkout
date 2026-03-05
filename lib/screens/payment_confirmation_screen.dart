import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/payment_data.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final PaymentData payment;

  const PaymentConfirmationScreen({Key? key, required this.payment})
      : super(key: key);

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

  String _getLastFourDigits(String cardNumber) {
    if (cardNumber == 'N/A') return 'N/A';
    String numbers = cardNumber.replaceAll(' ', '');
    if (numbers.length >= 4) {
      return numbers.substring(numbers.length - 4);
    }
    return numbers;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Edit',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Information
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Edit',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Card holder', payment.cardHolder),
                  if (payment.cardNumber != 'N/A')
                    _buildInfoRow(
                      'Card ending',
                      '**${_getLastFourDigits(payment.cardNumber)}',
                    ),
                  _buildInfoRow(
                      'Total amount', _formatPrice(payment.totalPrice)),
                  _buildInfoRow('Payment method', payment.paymentMethod),
                  _buildInfoRow('Date', dateFormat.format(payment.paymentDate)),
                  if (payment.saveCardForFuture)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Tarjeta guardada para futuros pagos',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Use Promo Code
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Use promo code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PROMO20-08',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¡Pago exitoso!'),
                      content: Text(
                        'Tu pago de ${_formatPrice(payment.totalPrice)} ha sido procesado correctamente.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          },
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Pay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
