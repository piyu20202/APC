import 'package:flutter/material.dart';

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
  String currentPath = '';

  @override
  void initState() {
    super.initState();
    currentPath = widget.currentPath ?? '';
  }

  // Sample data structure matching the reference images
  final Map<String, dynamic> fileSystem = {
    '': {
      'folders': [
        {
          'name': '01- Swing Gate Manuals',
          'fileCount': 16,
          'size': '52.89MB',
          'path': 'swing_gate',
        },
        {
          'name': '02- Sliding Gate Manuals',
          'fileCount': 5,
          'size': '43.35MB',
          'path': 'sliding_gate',
        },
        {
          'name': '03- Boom Gate Systems',
          'fileCount': 8,
          'size': '35.19MB',
          'path': 'boom_gate',
        },
        {
          'name': '04- Keypads & Push Buttons',
          'fileCount': 8,
          'size': '25.31MB',
          'path': 'keypads',
        },
        {
          'name': '05- Electric & Magnetic Locks',
          'fileCount': 3,
          'size': '3.5MB',
          'path': 'locks',
        },
        {
          'name': '06- Video Intercom Systems',
          'fileCount': 4,
          'size': '64.48MB',
          'path': 'intercom',
        },
      ],
      'files': [],
    },
    'swing_gate': {
      'folders': [
        {
          'name': '01- Roger Technology',
          'fileCount': 9,
          'size': '20.74MB',
          'path': 'swing_gate/roger_tech',
        },
      ],
      'files': [
        {
          'name': '01- APC-Logico 24 v1.1.09 Control Panel Manual.pdf',
          'size': '4MB',
          'lastModified': 'FRI. JUNE 21ST, 2024 - 01:14AM',
        },
        {
          'name': '02- APC-Simply24 v4.01.01 Control Panel User Manuel.pdf',
          'size': '2.2MB',
          'lastModified': 'THU. JUNE 26TH, 2025 - 02:12AM',
        },
        {
          'name': '03- APC-CBSW24 v1.6 Control Panel Manual.pdf',
          'size': '1.76MB',
          'lastModified': 'WED. FEBRUARY 24TH, 2021 - 11:27PM',
        },
      ],
    },
    'swing_gate/roger_tech': {
      'folders': [],
      'files': [
        {
          'name': 'Roger Technology Installation Guide.pdf',
          'size': '3.2MB',
          'lastModified': 'MON. JANUARY 15TH, 2024 - 10:30AM',
        },
        {
          'name': 'Roger Technology User Manual.pdf',
          'size': '2.8MB',
          'lastModified': 'FRI. DECEMBER 20TH, 2023 - 03:45PM',
        },
        {
          'name': 'Roger Technology Troubleshooting.pdf',
          'size': '1.9MB',
          'lastModified': 'WED. NOVEMBER 8TH, 2023 - 09:15AM',
        },
      ],
    },
    'sliding_gate': {
      'folders': [],
      'files': [
        {
          'name': 'Sliding Gate Installation Manual.pdf',
          'size': '8.5MB',
          'lastModified': 'TUE. MARCH 12TH, 2024 - 02:20PM',
        },
        {
          'name': 'Sliding Gate Maintenance Guide.pdf',
          'size': '6.2MB',
          'lastModified': 'THU. FEBRUARY 28TH, 2024 - 11:10AM',
        },
      ],
    },
    'boom_gate': {
      'folders': [],
      'files': [
        {
          'name': 'Boom Gate System Manual.pdf',
          'size': '12.3MB',
          'lastModified': 'MON. APRIL 1ST, 2024 - 08:45AM',
        },
        {
          'name': 'Boom Gate Safety Procedures.pdf',
          'size': '4.1MB',
          'lastModified': 'FRI. MARCH 22ND, 2024 - 04:30PM',
        },
      ],
    },
    'keypads': {
      'folders': [],
      'files': [
        {
          'name': 'Keypad Installation Guide.pdf',
          'size': '5.8MB',
          'lastModified': 'WED. MAY 8TH, 2024 - 01:15PM',
        },
        {
          'name': 'Push Button Manual.pdf',
          'size': '3.2MB',
          'lastModified': 'TUE. APRIL 30TH, 2024 - 10:45AM',
        },
      ],
    },
    'locks': {
      'folders': [],
      'files': [
        {
          'name': 'Electric Lock Installation.pdf',
          'size': '2.1MB',
          'lastModified': 'THU. JUNE 6TH, 2024 - 03:20PM',
        },
        {
          'name': 'Magnetic Lock Guide.pdf',
          'size': '1.4MB',
          'lastModified': 'MON. MAY 27TH, 2024 - 09:30AM',
        },
      ],
    },
    'intercom': {
      'folders': [],
      'files': [
        {
          'name': 'Video Intercom Installation.pdf',
          'size': '18.7MB',
          'lastModified': 'FRI. JULY 12TH, 2024 - 02:45PM',
        },
        {
          'name': 'Intercom System Manual.pdf',
          'size': '15.2MB',
          'lastModified': 'WED. JULY 3RD, 2024 - 11:20AM',
        },
      ],
    },
  };

  List<Map<String, dynamic>> get currentItems {
    final data = fileSystem[currentPath] ?? {'folders': [], 'files': []};
    final folders = (data['folders'] as List).cast<Map<String, dynamic>>();
    final files = (data['files'] as List).cast<Map<String, dynamic>>();

    // Combine folders and files, folders first
    final allItems = <Map<String, dynamic>>[];
    allItems.addAll(folders.map((folder) => {...folder, 'type': 'folder'}));
    allItems.addAll(files.map((file) => {...file, 'type': 'file'}));

    return allItems;
  }

  String get currentTitle {
    if (currentPath.isEmpty) return widget.title;

    final pathParts = currentPath.split('/');
    final lastPart = pathParts.last;

    // Find the folder name from the file system
    for (final entry in fileSystem.entries) {
      if (entry.key == currentPath) {
        final folders = (entry.value['folders'] as List)
            .cast<Map<String, dynamic>>();
        for (final folder in folders) {
          if (folder['path'] == currentPath) {
            return folder['name'];
          }
        }
      }
    }

    return lastPart
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  void navigateToFolder(String path) {
    setState(() {
      currentPath = path;
    });
  }

  void navigateBack() {
    if (currentPath.isEmpty) {
      Navigator.pop(context);
    } else {
      final pathParts = currentPath.split('/');
      pathParts.removeLast();
      setState(() {
        currentPath = pathParts.join('/');
      });
    }
  }

  void downloadFile(String fileName) {
    // TODO: Implement file download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $fileName...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = currentItems;

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
          if (currentPath.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.home, color: Colors.black),
              onPressed: () {
                setState(() {
                  currentPath = '';
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // File list
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildListItem(item, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, int index) {
    final isFolder = item['type'] == 'folder';
    final isEven = index % 2 == 0;

    return Container(
      color: isEven ? Colors.grey[50] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: isFolder
            ? const Icon(Icons.folder, color: Colors.black, size: 32)
            : const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
        title: Text(
          item['name'],
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: isFolder
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['fileCount']} FILES',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'SIZE: ${item['size']}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIZE: ${item['size']}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'LAST MODIFIED: ${item['lastModified']}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
        trailing: isFolder
            ? const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
            : IconButton(
                icon: const Icon(Icons.download, color: Colors.black, size: 24),
                onPressed: () => downloadFile(item['name']),
              ),
        onTap: isFolder
            ? () => navigateToFolder(item['path'])
            : () => downloadFile(item['name']),
      ),
    );
  }
}
