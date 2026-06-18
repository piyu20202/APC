import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/network/api_endpoints.dart';

/// PayPal JS SDK WebView — SDD Section 4.2 (With URL Console Log)
class PaymentWebView extends StatefulWidget {
  final double amount;
  final String currency;
  final String orderRef;

  /// Called when JS page posts to window.PayPalResult
  final void Function(Map<String, dynamic> result) onPaymentResult;

  /// Base URL of your Laravel backend
  final String backendBaseUrl;

  const PaymentWebView({
    super.key,
    required this.amount,
    required this.currency,
    required this.orderRef,
    required this.onPaymentResult,
    this.backendBaseUrl = ApiEndpoints.paymentPageWebUrl,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPopped = false;

  // ── URL patterns: Laravel in URLs pe redirect karta hai ──────────────────
  static const List<String> _successUrlPatterns = [
    'checkout/payment/return', // ← confirmed from logs
    'payment/return',
    'payment/success',
    'order/success',
    'order-success',
  ];

  static const List<String> _failureUrlPatterns = [
    'checkout/payment/cancel',
    'payment/cancel',
    'payment/failure',
    'payment/failed',
    'payment/error',
  ];

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// URL check karke success/failure detect karta hai
  void _handleUrlChange(String url) {
    debugPrint('🌐 WebView URL: $url');
    final lower = url.toLowerCase();

    for (final p in _successUrlPatterns) {
      if (lower.contains(p)) {
        debugPrint('✅ SUCCESS URL matched [$p]: $url');
        _popWithResult({
          'status': 'COMPLETED',
          'source': 'url_redirect',
          'returnUrl': url,
        });
        return;
      }
    }

    for (final p in _failureUrlPatterns) {
      if (lower.contains(p)) {
        debugPrint('❌ FAILURE URL matched [$p]: $url');
        _popWithResult({
          'status': 'FAILED',
          'source': 'url_redirect',
          'returnUrl': url,
        });
        return;
      }
    }
  }

  void _popWithResult(Map<String, dynamic> result) {
    if (!_hasPopped && mounted) {
      _hasPopped = true;
      widget.onPaymentResult(result);
      Navigator.of(context).pop(result);
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
            _handleUrlChange(url); // redirect fast ho to yahan catch hoga
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            _handleUrlChange(url); // page load hone par check
          },
          onNavigationRequest: (NavigationRequest request) {
            _handleUrlChange(request.url); // sabse pehle yahan aata hai
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'PayPalResult',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('Received message from PayPal JS SDK: ${message.message}');
          try {
            final Map<String, dynamic> result = jsonDecode(message.message);
            _popWithResult(result); // JS channel se aaye to directly pop
          } catch (e) {
            debugPrint('Error parsing JavaScript channel message: $e');
          }
        },
      );

    _loadPaymentPage();
  }

  void _loadPaymentPage() {
    final finalUrl =
        '${widget.backendBaseUrl}/order-payment/${widget.orderRef}';

    // 🔥 Yahan console me poora URL print hoga
    debugPrint('**************************************************');
    debugPrint('🚀 LOADING WEBVIEW URL: $finalUrl');
    debugPrint('**************************************************');

    _controller.loadRequest(Uri.parse(finalUrl));
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
            _popWithResult({'status': 'cancelled'});
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
