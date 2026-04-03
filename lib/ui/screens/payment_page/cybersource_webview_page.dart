import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CybersourceWebViewPage extends StatefulWidget {
  final String captureContext;
  final int orderId;
  final String orderNumber;
  final double amount;

  const CybersourceWebViewPage({
    super.key,
    required this.captureContext,
    required this.orderId,
    required this.orderNumber,
    required this.amount,
  });

  @override
  State<CybersourceWebViewPage> createState() => _CybersourceWebViewPageState();
}

class _CybersourceWebViewPageState extends State<CybersourceWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Cybersource WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            
            if (url.contains('success')) {
              final uri = Uri.parse(request.url);
              // Try to find token in various possible parameters
              final token = uri.queryParameters['token'] ?? 
                            uri.queryParameters['payment_token'] ?? 
                            uri.queryParameters['transaction_id'];
              
              Navigator.pop(context, {
                'success': true, 
                'token': token,
              });
              return NavigationDecision.prevent;
            } else if (url.contains('cancel') || url.contains('error') || url.contains('fail')) {
              Navigator.pop(context, {'success': false});
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Load with POST parameters. 
    // Usually captureContext is passed as a named parameter or the whole body.
    // Based on "Pass captureContext data as POST parameters", we'll treat it as standard form data.
    _controller.loadRequest(
      Uri.parse('https://secureacceptance.cybersource.com/checkout'),
      method: LoadRequestMethod.post,
      body: utf8.encode(widget.captureContext),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to leave? Your payment progress will be lost.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context, {'success': false});
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Payment'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context, {'success': false});
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
