import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';
import 'purchases_screen.dart';
import 'qr_payment_confirmed_screen.dart';
import 'qr_payment_rejected_screen.dart';

class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  final List<PurchaseItem> items;
  final double totalAmount;

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  final ApiService _apiService = ApiService();

  String? _qrImageUrl;
  String? _reference;
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initQrPayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initQrPayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = widget.items.map((item) {
        final unitPrice = double.tryParse(
              item.price.replaceAll('R', '').replaceAll(',', ''),
            ) ??
            0.0;
        return {
          'itemId': item.itemId,
          'name': item.name,
          'type': item.type,
          'quantity': item.quantity,
          'unitPrice': unitPrice,
        };
      }).toList();

      final result = await _apiService.createQrTransaction(
        items: items,
        amountTotal: widget.totalAmount,
      );

      setState(() {
        _qrImageUrl = result['qrImageUrl'] as String;
        _reference = result['reference'] as String;
        _isLoading = false;
      });

      _startPolling();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_reference == null || !mounted) return;
      try {
        final status = await _apiService.verifyPayment(_reference!);
        if (!mounted) return;
        if (status == 'completed') {
          _pollTimer?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => QRPaymentConfirmedScreen(
                items: widget.items,
                totalAmount: widget.totalAmount,
              ),
            ),
          );
        } else if (status == 'failed') {
          _pollTimer?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => QRPaymentRejectedScreen(
                items: widget.items,
                totalAmount: widget.totalAmount,
              ),
            ),
          );
        }
      } catch (_) {
        // Silently ignore poll errors — keep trying
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Point of Sale',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Service / Product',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            ...widget.items.map((item) {
              final unitPrice =
                  double.tryParse(item.price.replaceAll('R', '').replaceAll(',', '')) ?? 0.0;
              final lineTotal = unitPrice * item.quantity;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.name} x${item.quantity}',
                            style: const TextStyle(
                              color: Color(0xFF272A2F),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.barcode.isNotEmpty)
                            Text(
                              item.barcode,
                              style: const TextStyle(
                                color: Color(0xFF9B9B9B),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'R${lineTotal % 1 == 0 ? lineTotal.toInt() : lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF272A2F),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            const Text(
              'Amount to be paid:',
              style: TextStyle(
                color: Color(0xFF272A2F),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'R${widget.totalAmount.toInt()}',
                style: const TextStyle(
                  color: Color(0xFF272A2F),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                    SizedBox(height: 16),
                    Text(
                      'Generating QR code...',
                      style: TextStyle(color: Color(0xFF6C7078), fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFE55353), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFE55353), fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _initQrPayment,
                      child: const Text('Try Again',
                          style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.network(
                        _qrImageUrl!,
                        width: 280,
                        height: 280,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.qr_code_2,
                          size: 280,
                          color: Color(0xFF272A2F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Waiting for payment...',
                        style: TextStyle(color: Color(0xFF6C7078), fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Customer must scan with SnapScan or their banking app',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
