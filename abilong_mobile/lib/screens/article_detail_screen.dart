import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/article_model.dart';
// import '../services/article_service.dart'; // 👈 uncomment if you have API service

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article.title);
    _nameController = TextEditingController(text: widget.article.name);
    _contentController = TextEditingController(
      text: widget.article.content.join("\n"),
    );
    _isActive = widget.article.isActive;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Loading popup
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text("Updating article..."),
            ],
          ),
        ),
      ),
    );
  }

 
  Future<void> saveChanges() async {
    final updatedArticle = Article(
      aid: widget.article.aid,
      name: _nameController.text,
      isActive: _isActive,
      title: _titleController.text,
      content: _contentController.text
          .split(RegExp(r'[\n,]+'))
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList(),
    );

    _showLoadingDialog(context); 

    try {
      
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Replace with your API call
      // await ArticleService().updateArticle(updatedArticle);

      if (mounted) {
        Navigator.of(context).pop(); 
        Navigator.of(context).pop(updatedArticle); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Article updated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e")),
        );
      }
    }
  }

  void cancelEdit() {
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.title.isEmpty ? "Add Article" : widget.article.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180.h,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 50),
              ),
              SizedBox(height: 16.h),

              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Author / Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),

              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "Content (one item per line or comma-separated)",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Active"),
                  Switch(
                    activeColor: Colors.green,
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text("Save Changes"),
                  onPressed: saveChanges,
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text("Cancel"),
                  onPressed: cancelEdit,
                ),
              ),
              SizedBox(height: 12.h),

              const Text(
                "Tip: Separate multiple content items using new lines or commas.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
