import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme.dart';

/// Parses rosterflow://join?code=XXX&role=coach|parent and returns code if valid.
String? parseJoinPayload(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final uri = Uri.parse(raw);
    if (uri.scheme != 'rosterflow' || uri.host != 'join') return null;
    final code = uri.queryParameters['code'];
    return code != null && code.isNotEmpty ? code : null;
  } catch (_) {
    return null;
  }
}

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController();
  StreamSubscription<BarcodeCapture>? _sub;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _sub = _controller.barcodes.listen((capture) {
      final barcodes = capture.barcodes;
      if (barcodes.isEmpty || _handled) return;
      for (final b in barcodes) {
        final code = parseJoinPayload(b.rawValue);
        if (code != null) {
          _handled = true;
          if (mounted) {
            context.go('/teams/join', extra: {'code': code});
          }
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scan QR code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: MobileScanner(controller: _controller),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: Colors.black87,
        child: Text(
          'Point your camera at a coach or parent invite QR code.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
