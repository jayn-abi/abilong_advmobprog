import 'package:flutter/material.dart';

class ArticleDialogue extends StatefulWidget {
  final bool isGlobalLoading;
  final Future<void> Function(Map<String, dynamic> payload, BuildContext ctx) onSave;

  const ArticleDialogue({
    Key? key,
    required this.isGlobalLoading,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ArticleDialogue> createState() => _ArticleDialogueState();
}

class _ArticleDialogueState extends State<ArticleDialogue> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final contentController = TextEditingController();
  bool isActive = true;
  bool isSaving = false; 

  List<String> _toList(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

Future<void> _handleSave(BuildContext ctx) async {
  if (isSaving) return;
  if (!formKey.currentState!.validate()) return;

  setState(() => isSaving = true);

  final payload = {
    'title': titleController.text.trim(),
    'name': authorController.text.trim(),
    'content': _toList(contentController.text),
    'isActive': isActive,
  };

  try {
    await widget.onSave(payload, ctx);
  } catch (_) {
    
  } finally {
    if (mounted) {
      
      await Future.delayed(const Duration(seconds: 10));
      setState(() => isSaving = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Article'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: authorController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Author / Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contentController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content (one per line or comma-separated)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null) return 'At least one content item';
                  final items = v
                      .trim()
                      .split(RegExp(r'[\n,]'))
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
                  return items.isEmpty ? 'At least one content item' : null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: (widget.isGlobalLoading || isSaving)
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (widget.isGlobalLoading || isSaving)
              ? null
              : () => _handleSave(context),
          child: isSaving
              ? const Text(
                  "Saving...",
                  style: TextStyle(color: Colors.grey),
                )
              : const Text("Save"),
        ),
      ],
    );
  }
}
