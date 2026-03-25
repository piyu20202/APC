import 'package:flutter/material.dart';
import '../../../data/services/manuals_service.dart';
import '../../../core/utils/logger.dart';
import 'pdf_viewer_page.dart';

class ManualsListViewPage extends StatefulWidget {
  final String type;
  final String title;
  final String? currentPath;

  const ManualsListViewPage({
    super.key,
    required this.type,

    required this.title,
    this.currentPath,
  });

  @override
  State<ManualsListViewPage> createState() => _ManualsListViewPageState();
}

class _ManualsListViewPageState extends State<ManualsListViewPage> {
  List<ManualItem> rootManuals = [];
  List<ManualItem> currentList = [];
  List<String> pathHistoryNames = [];
  List<List<ManualItem>> pathHistoryLists = [];
  bool isLoading = true;
  final ManualsService _manualsService = ManualsService();

  @override
  void initState() {
    super.initState();
    _loadManuals();
  }

  Future<void> _loadManuals() async {
    setState(() => isLoading = true);
    try {
      final data = await _manualsService.getManuals(widget.type);
      if (mounted) {
        setState(() {
          rootManuals = data;
          currentList = data;
          isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading manuals', e);
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _navigateToFolder(ManualItem folder) {
    if (folder.children != null) {
      setState(() {
        pathHistoryLists.add(currentList);
        pathHistoryNames.add(folder.name);
        currentList = folder.children!;
      });
    }
  }

  void navigateBack() {
    if (pathHistoryLists.isEmpty) {
      Navigator.pop(context);
    } else {
      setState(() {
        currentList = pathHistoryLists.removeLast();
        pathHistoryNames.removeLast();
      });
    }
  }

  String get currentTitle {
    if (pathHistoryNames.isEmpty) return widget.title;
    return pathHistoryNames.last;
  }

  void _openPdf(String url) {
    final trimmed = url.trim();

    // Validate URL
    var parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.scheme.isEmpty) {
      parsed = Uri.tryParse('https://$trimmed');
    }

    if (parsed == null) {
      Logger.error('Invalid URL for PDF: $url');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL for PDF')),
        );
      }
      return;
    }

    try {
      // Navigate to PDF viewer page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            pdfUrl: parsed.toString(),
            title: currentTitle,
          ),
        ),
      );
    } catch (e) {
      Logger.error('Failed to navigate to PDF viewer', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open PDF')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = currentList;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: navigateBack,
        ),
        title: Text(
          currentTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          if (pathHistoryLists.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.home, color: Colors.black),
              onPressed: () {
                setState(() {
                  currentList = rootManuals;
                  pathHistoryLists.clear();
                  pathHistoryNames.clear();
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // File list
                Expanded(
                  child: currentList.isEmpty 
                    ? const Center(child: Text('No content found'))
                    : ListView.builder(
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final item = currentList[index];
                      return _buildListItem(item, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildListItem(ManualItem item, int index) {
    final isFolder = item.isFolder;
    final isEven = index % 2 == 0;

    return Container(
      color: isEven ? Colors.grey[50] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: isFolder
            ? const Icon(Icons.folder, color: Colors.black, size: 32)
            : const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
        title: Text(
          item.name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: isFolder && (item.children?.isNotEmpty ?? false)
            ? Text(
                '${item.children!.length} ITEMS',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              )
            : !isFolder ? const Text(
                'TAP TO OPEN IN BROWSER',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ) : null,
        trailing: isFolder
            ? const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
            : const Icon(Icons.open_in_browser, color: Colors.black, size: 24),
        onTap: isFolder
            ? () => _navigateToFolder(item)
            : () => item.url != null ? _openPdf(item.url!) : null,
      ),
    );
  }
}
