import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "../../services/firestore_service.dart";

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _dialogCtrl = TextEditingController();

  void _showAddDialog() {
    _dialogCtrl.clear();
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16162D) : Colors.white,
          title: Text("Add Category", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _dialogCtrl,
            decoration: const InputDecoration(hintText: "Enter category name"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final name = _dialogCtrl.text.trim();
                if (name.isNotEmpty) {
                  final snap = await FirebaseFirestore.instance.collection('categories').get();
                  await FirestoreService.instance.addCategory(name, position: snap.docs.length);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(String id, String currentName) {
    _dialogCtrl.text = currentName;
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16162D) : Colors.white,
          title: Text("Edit Category", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _dialogCtrl,
            decoration: const InputDecoration(hintText: "Enter category name"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final name = _dialogCtrl.text.trim();
                if (name.isNotEmpty) {
                  await FirestoreService.instance.updateCategory(id, name);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16162D) : Colors.white,
          title: Text("Delete Category", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete '$name'? Existing posts in this category will remain, but the filter will be removed."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                await FirestoreService.instance.deleteCategory(id);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Categories Management", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService.instance.getCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: isDark ? Colors.white30 : Colors.black26),
                        const SizedBox(height: 16),
                        Text("No categories added yet.", style: GoogleFonts.inter(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text("Tap + to add your first category", style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final items = List<Map<String, dynamic>>.from(list);
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);
                    await FirestoreService.instance.updateCategoriesOrder(items);
                  },
                  itemBuilder: (context, index) {
                    final cat = list[index];
                    final id = cat["id"] as String;
                    final name = cat["name"] as String;

                    return Card(
                      key: ValueKey(id),
                      color: isDark ? const Color(0xFF16162D) : Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.drag_handle, color: Colors.grey),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: cs.primary.withAlpha(20),
                              child: Icon(Icons.category_outlined, color: cs.primary),
                            ),
                          ],
                        ),
                        title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                              onPressed: () => _showEditDialog(id, name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(id, name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: cs.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
