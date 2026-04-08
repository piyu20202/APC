import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TrackingInfoPage extends StatelessWidget {
  final String heading;
  final String info;

  const TrackingInfoPage({
    super.key,
    required this.heading,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A365D),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading.isNotEmpty)
                  Html(
                    data: heading,
                    style: {
                      "body": Style(
                        fontSize: FontSize(18),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A365D),
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 8),
                      ),
                    },
                  ),
                const SizedBox(height: 12),
                _buildInfoText(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(BuildContext context) {
    final content = info.isNotEmpty
        ? info
        : '<p>No shipment tracking information available for this order.</p>';

    return Html(
      data: content,
      onLinkTap: (url, _, __) {
        if (url != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TrackingWebViewPage(url: url),
            ),
          );
        }
      },
      style: {
        "body": Style(
          fontSize: FontSize(15),
          lineHeight: const LineHeight(1.4),
          color: Colors.black87,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "a": Style(
          color: Colors.blue,
          textDecoration: TextDecoration.underline,
        ),
        "p": Style(
          margin: Margins.only(bottom: 8),
        ),
      },
    );
  }
}

class TrackingWebViewPage extends StatefulWidget {
  final String url;

  const TrackingWebViewPage({super.key, required this.url});

  @override
  State<TrackingWebViewPage> createState() => _TrackingWebViewPageState();
}

class _TrackingWebViewPageState extends State<TrackingWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A365D),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
