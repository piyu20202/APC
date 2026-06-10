import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// PayPal JS SDK WebView — SDD Section 4.2
///
/// Flutter opens a Laravel-hosted payment page that contains the full
/// PayPal JS SDK (PayPal, Pay in 4, ACDC, Apple Pay, Google Pay).
/// Results come back via the [PayPalResult] JavaScript channel.
///
/// Usage:
///   final result = await Navigator.push<Map<String, dynamic>>(
///     context,
///     MaterialPageRoute(
///       builder: (_) => PaymentWebView(
///         amount: 349.00,
///         currency: 'AUD',
///         orderRef: 'APC-12345',
///         onPaymentResult: (result) { ... },
///       ),
///     ),
///   );
class PaymentWebView extends StatefulWidget {
  final double amount;
  final String currency;
  final String orderRef;

  /// Called when JS page posts to window.PayPalResult
  /// result keys: { status, orderId, error }
  final void Function(Map<String, dynamic> result) onPaymentResult;

  /// Base URL of your Laravel backend (no trailing slash)
  /// e.g. 'https://www.gurgaonit.com/apc_production_dev'
  final String backendBaseUrl;

  const PaymentWebView({
    super.key,
    required this.amount,
    required this.currency,
    required this.orderRef,
    required this.onPaymentResult,
    this.backendBaseUrl =
        'https://www.gurgaonit.com/apc_production_dev/payment/paypal/MzMwMDM=',
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ── JavaScript channel: "PayPalResult" ──
      // JS page calls: window.PayPalResult.postMessage(JSON.stringify({...}))
      ..addJavaScriptChannel(
        'PayPalResult',
        onMessageReceived: (JavaScriptMessage message) {
          if (_hasPopped) return;
          try {
            final Map<String, dynamic> result =
                jsonDecode(message.message) as Map<String, dynamic>;
            debugPrint('PayPalResult received: $result');
            widget.onPaymentResult(result);
            _hasPopped = true;
            if (mounted) Navigator.of(context).pop(result);
          } catch (e) {
            debugPrint('PayPalResult parse error: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          '${widget.backendBaseUrl}/payment'
          '?amount=${widget.amount.toStringAsFixed(2)}'
          '&currency=${widget.currency}'
          '&ref=${Uri.encodeComponent(widget.orderRef)}',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        title: const Text(
          'Secure Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (!_hasPopped) {
              _hasPopped = true;
              Navigator.of(context).pop({'status': 'cancelled'});
            }
          },
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF003087)),
            ),
        ],
      ),
    );
  }
}
