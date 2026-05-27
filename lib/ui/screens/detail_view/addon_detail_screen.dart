import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AddonDetailScreen extends StatelessWidget {
  final String htmlContent;

  const AddonDetailScreen({super.key, required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add-On Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: htmlContent.isNotEmpty
            ? Html(
                data: htmlContent,
                style: {
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(14.0),
                    color: const Color(0xFF151D51),
                    lineHeight: const LineHeight(1.4),
                  ),
                },
              )
            : const Text(
                'No details available for this add-on.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
      ),
    );
  }
}
