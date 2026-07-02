import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/barcode_scanner_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  CameraController? _controller;
  final _scannerService = BarcodeScannerService();
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final controller = await _scannerService.initializeCamera();

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _scanImage() async {
    final controller = _controller;
    if (controller == null || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final value = await _scannerService.captureAndScanBarcode(controller);

      if (!mounted) return;

      if (value == null) {
        setState(() {
          _error = 'No barcode detected. Please try again.';
          _isProcessing = false;
        });
        return;
      }

      context.pop(value);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to scan barcode. Please try again.';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (controller != null && controller.value.isInitialized)
              Positioned.fill(child: CameraPreview(controller))
            else
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
            Positioned(
              left: 24,
              right: 24,
              top: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Barcode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                width: 260,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDFA890), width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: Column(
                children: [
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF272A2F)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  GestureDetector(
                    onTap: _isInitializing || _isProcessing ? null : _scanImage,
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFA890),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Capture Barcode',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
