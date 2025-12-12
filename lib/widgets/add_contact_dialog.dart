import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../db/database_helper.dart';

// --- ADD CONTACT DIALOG ---
// A dialog to add a new contact, ensuring resources are disposed.
class AddContactDialog extends StatefulWidget {
  final VoidCallback onContactAdded;

  const AddContactDialog({super.key, required this.onContactAdded});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _numCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.translate('add_contact')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(labelText: context.loc.translate('caller_name')),
          ),
          TextField(
            controller: _numCtrl,
            decoration: InputDecoration(labelText: context.loc.translate('caller_number')),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_nameCtrl.text.isNotEmpty && _numCtrl.text.isNotEmpty) {
              await DatabaseHelper.instance.createContact({
                'name': _nameCtrl.text,
                'number': _numCtrl.text,
                'relation': 'Friend',
                'is_selected': 1
              });
              widget.onContactAdded();
              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
