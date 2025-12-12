import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../db/database_helper.dart';
import '../widgets/add_contact_dialog.dart';

// --- 2. CONTACTS SCREEN ---
// Manage emergency contacts.
class ContactsPage extends StatefulWidget {
  final bool isSelectionMode;
  const ContactsPage({super.key, this.isSelectionMode = false});
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _refreshContacts();
  }

  // Load contacts from DB
  void _refreshContacts() async {
    final data = await DatabaseHelper.instance.readAllContacts();
    setState(() => _contacts = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isSelectionMode ? context.loc.translate('pick_contact') : context.loc.translate('select_contacts'))),
      body: _contacts.isEmpty
        ? Center(child: Text(context.loc.translate('no_contacts')))
        : ListView.builder(
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              final isSelected = contact['is_selected'] == 1;
              return ListTile(
                onTap: widget.isSelectionMode ? () => Navigator.pop(context, contact) : null,
                leading: CircleAvatar(child: Text(contact['name'][0])),
                title: Text(contact['name']),
                subtitle: Text(contact['number']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (val) async {
                          await DatabaseHelper.instance.toggleSelection(contact['id'], val!);
                          _refreshContacts();
                        },
                      ),
                    if (!widget.isSelectionMode)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(
                            title: Text(context.loc.translate('delete_confirm')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("No")),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Yes")),
                            ],
                          ));
                          if (confirm == true) {
                            await DatabaseHelper.instance.deleteContact(contact['id']);
                            _refreshContacts();
                          }
                        },
                      ),
                    if (widget.isSelectionMode)
                      const Icon(Icons.check_circle_outline)
                  ],
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AddContactDialog(onContactAdded: _refreshContacts),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
