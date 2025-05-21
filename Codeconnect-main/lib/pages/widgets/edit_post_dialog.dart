import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nitd_code/ui/pallete.dart';

class EditPostDialog extends StatefulWidget {
  final String postId;
  final String initialTitle;
  final String initialContent;
  final List<String> initialTags;
  final FirebaseFirestore firestore;

  const EditPostDialog({
    super.key,
    required this.postId,
    required this.initialTitle,
    required this.initialContent,
    required this.initialTags,
    required this.firestore,
  });

  @override
  _EditPostDialogState createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _tagController = TextEditingController();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _updatePost() async {
    try {
      if (_titleController.text.isEmpty ||
          _contentController.text.isEmpty ||
          _tags.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Title, content and tags cannot be empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await widget.firestore.collection('posts').doc(widget.postId).update({
        'title': _titleController.text,
        'content': _contentController.text,
        'tags': _tags,
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Dialog(
          backgroundColor: Pallete.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500, // Set max width for responsiveness
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Pallete.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStyledTextField(_titleController, 'Title'),
                    const SizedBox(height: 12),
                    _buildStyledTextField(_contentController, 'Content'),
                    const SizedBox(height: 12),

                    // Tags Section
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag,
                              style:
                                  const TextStyle(color: Pallete.whiteColor)),
                          backgroundColor: Pallete.gradient2.withOpacity(0.75),
                          deleteIcon:
                              const Icon(Icons.close, color: Pallete.gradient2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                                color: Pallete.gradient2, width: 1),
                          ),
                          onDeleted: () {
                            setState(() {
                              _tags.remove(tag);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Tag Input Field
                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildStyledTextField(_tagController, 'Add Tag'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add, color: Pallete.gradient2),
                          onPressed: () {
                            if (_tagController.text.isNotEmpty) {
                              setState(() {
                                _tags.add(_tagController.text);
                                _tagController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Pallete.gradient3,
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _updatePost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Pallete.gradient2,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// Helper function for text fields
  Widget _buildStyledTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Pallete.gradient2, // Slight color pop
        ),
        hintText: "Type your $label here...",
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Pallete.borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Pallete.gradient1, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Pallete.gradient2, width: 1.5),
        ),
        filled: true,
        fillColor: Pallete.backgroundColor.withOpacity(0.5),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Pallete.whiteColor,
      ),
      cursorColor: Pallete.gradient1,
    );
  }
}
