import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../services/evidence_manager.dart';
import '../widgets/video_player_widget.dart';

// --- 5. EVIDENCE ACCESS ---
// Screen to view and manage recorded evidence files.
class EvidenceAccessScreen extends StatefulWidget {
  const EvidenceAccessScreen({super.key});
  @override
  State<EvidenceAccessScreen> createState() => _EvidenceAccessScreenState();
}

class _EvidenceAccessScreenState extends State<EvidenceAccessScreen> {
  List<Map<String, String>> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  // Load files from EvidenceManager
  void _loadFiles() {
    setState(() {
      _files = EvidenceManager().getEvidenceFiles();
    });
  }

  // Open video player dialog
  void _openFile(String path) {
    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: VideoPlayerWidget(videoPath: path),
      )
    );
  }

  // Confirm and delete file
  void _deleteFile(String path) async {
    bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(context.loc.translate('delete_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("No")),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Yes")),
      ],
    ));
    if (confirm == true) {
      await EvidenceManager().deleteEvidence(path);
      _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('evidence_access'))),
      body: _files.isEmpty
          ? Center(child: Text(loc.translate('evidence_empty')))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return ListTile(
                  leading: const Icon(Icons.video_library, color: Colors.purple),
                  title: Text(file['filename']!),
                  subtitle: Text("${file['date']} • ${file['duration']}\nSaved to Gallery"),
                  onTap: () => _openFile(file['path']!),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFile(file['path']!),
                  ),
                );
              },
            ),
    );
  }
}
