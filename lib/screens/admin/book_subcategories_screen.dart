import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "../../services/firestore_service.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/providers.dart';
import 'admin_dashboard.dart';
import '../../models/post_model.dart';

class BookSubcategoriesScreen extends ConsumerStatefulWidget {
  const BookSubcategoriesScreen({super.key});

  @override
  ConsumerState<BookSubcategoriesScreen> createState() => _BookSubcategoriesScreenState();
}

class _BookSubcategoriesScreenState extends ConsumerState<BookSubcategoriesScreen> {
  String? _selectedFolderId; // null means all
  final TextEditingController _dialogCtrl = TextEditingController();
  int _currentTab = 0; // 0: View Books, 1: Manage Folders

  void _showAddDialog() {
    _dialogCtrl.clear();
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16162D) : Colors.white,
          title: Text("Add Subcategory", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _dialogCtrl,
            decoration: const InputDecoration(hintText: "Enter subcategory name"),
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
                  final snap = await FirebaseFirestore.instance.collection('bookSubcategories').get();
                  await FirestoreService.instance.addBookSubcategory(name, position: snap.docs.length);
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
          title: Text("Edit Subcategory", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _dialogCtrl,
            decoration: const InputDecoration(hintText: "Enter subcategory name"),
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
                  await FirestoreService.instance.updateBookSubcategory(id, name);
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
          title: Text("Delete Subcategory", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete '$name'? Books assigned to it will remain uncategorized."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                await FirestoreService.instance.deleteBookSubcategory(id);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFolderCard({
    required BuildContext context,
    required String name,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? cs.primary.withAlpha(20) 
              : (isDark ? const Color(0xFF16162D) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primary : (isDark ? Colors.white10 : Colors.black12),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(color: cs.primary.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))
            else
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.folder : Icons.folder_open,
              color: isSelected ? cs.primary : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? cs.primary : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? cs.primary.withAlpha(30) : (isDark ? Colors.white10 : Colors.black12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count Books",
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? cs.primary : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewBooksTab(AsyncValue<List<PostModel>> postsAsync, bool isDark, ColorScheme cs) {
    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.redAccent))),
      data: (list) {
        final now = DateTime.now();
        final activePosts = list.where((p) => p.expireDate == null || p.expireDate!.isAfter(now)).toList();
        final catPosts = activePosts.where((p) => p.categoryId == "Books").toList();

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService.instance.getBookSubcategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final subcategories = snapshot.data ?? [];

            // Group books by subcategory to get counts
            final counts = <String, int>{};
            for (final sub in subcategories) {
              counts[sub["id"]] = 0;
            }
            int generalCount = 0;
            int allCount = catPosts.length;

            for (final post in catPosts) {
              final subId = post.bookSubcategory;
              if (subId != null && counts.containsKey(subId)) {
                counts[subId] = counts[subId]! + 1;
              } else {
                generalCount++;
              }
            }

            // Folder Items List
            final folderItems = [
              {"id": "all", "name": "All", "count": allCount},
              ...subcategories.map((sub) => {
                "id": sub["id"] as String,
                "name": sub["name"] as String,
                "count": counts[sub["id"]] ?? 0,
              }),
              if (generalCount > 0)
                {"id": "general", "name": "General Books", "count": generalCount},
            ];

            // Filter books list based on selected folder ID
            final selectedFolderId = _selectedFolderId ?? "all";
            final filteredBooks = catPosts.where((post) {
              if (selectedFolderId == "all") return true;
              if (selectedFolderId == "general") return post.bookSubcategory == null;
              return post.bookSubcategory == selectedFolderId;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Subcategories",
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: folderItems.length,
                    itemBuilder: (context, index) {
                      final item = folderItems[index];
                      final id = item["id"] as String;
                      final name = item["name"] as String;
                      final count = item["count"] as int;
                      final isSelected = selectedFolderId == id;
                      return _buildFolderCard(
                        context: context,
                        name: name,
                        count: count,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _selectedFolderId = id == "all" ? null : id;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Books List (${filteredBooks.length})",
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  if (filteredBooks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text("No books in this subcategory", style: GoogleFonts.inter(color: Colors.grey)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredBooks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return PostAdminCard(post: filteredBooks[index], isDark: isDark);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildManageFoldersTab(bool isDark, ColorScheme cs) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.instance.getBookSubcategories(),
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
                Text("No subcategories added yet.", style: GoogleFonts.inter(color: Colors.grey)),
                const SizedBox(height: 8),
                Text("Tap + to add your first book subcategory", style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
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
            await FirestoreService.instance.updateBookSubcategoriesOrder(items);
          },
          itemBuilder: (context, index) {
            final sub = list[index];
            final id = sub["id"] as String;
            final name = sub["name"] as String;

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
                      child: Icon(Icons.bookmark_outline, color: cs.primary),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Book Management", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: _AdminBookSearchDelegate(ref),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentTab == 1
          ? FloatingActionButton(
              tooltip: "Add Subcategory",
              backgroundColor: cs.primary,
              onPressed: _showAddDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text("View Books"), icon: Icon(Icons.book_outlined)),
                      ButtonSegment(value: 1, label: Text("Manage Folders"), icon: Icon(Icons.folder_outlined)),
                    ],
                    selected: {_currentTab},
                    onSelectionChanged: (set) => setState(() => _currentTab = set.first),
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: _currentTab == 0
                      ? _buildViewBooksTab(postsAsync, isDark, cs)
                      : _buildManageFoldersTab(isDark, cs),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminBookSearchDelegate extends SearchDelegate<void> {
  final WidgetRef ref;
  _AdminBookSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (query.trim().isEmpty) {
      return const Center(child: Text('Type to search books...'));
    }
    final postsAsync = ref.watch(postsProvider);
    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        final now = DateTime.now();
        final active = list.where((p) => p.expireDate == null || p.expireDate!.isAfter(now)).toList();
        final books = active.where((p) => p.categoryId == "Books").toList();
        final filtered = books.where((p) {
          final titleMatch = p.title.toLowerCase().contains(query.toLowerCase());
          final descMatch = p.description.toLowerCase().contains(query.toLowerCase());
          return titleMatch || descMatch;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No books found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (_, index) {
            return PostAdminCard(post: filtered[index], isDark: isDark);
          },
        );
      },
    );
  }
}
