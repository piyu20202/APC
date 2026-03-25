import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/utils/logger.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Logger.info('Loading PDF: ${widget.title}');
    Logger.info('PDF URL: ${widget.pdfUrl}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.pdfUrl,
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              final errorMsg = details.error?.toString() ?? 'Unknown error';
              Logger.error('PDF load failed: $errorMsg', details.error);
              
              setState(() {
                _isLoading = false;
                _errorMessage = _parseErrorMessage(errorMsg);
              });
              
              _showErrorSnackbar(_errorMessage!);
            },
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _isLoading = false;
              });
              Logger.info('PDF loaded successfully: ${widget.title}');
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null && !_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _parseErrorMessage(String error) {
    if (error.contains('404')) {
      return 'PDF not found on server (404).\n\nThe file may have been moved or deleted.';
    } else if (error.contains('403')) {
      return 'Access denied (403).\n\nYou do not have permission to view this file.';
    } else if (error.contains('500') || error.contains('502') || error.contains('503')) {
      return 'Server error.\n\nPlease try again later.';
    } else if (error.contains('timeout') || error.contains('Timeout')) {
      return 'Connection timeout.\n\nThe server took too long to respond. Please check your internet connection.';
    } else if (error.contains('SocketException') || error.contains('Network')) {
      return 'Network error.\n\nPlease check your internet connection.';
    } else {
      return 'Failed to load PDF: $error';
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
