import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/providers.dart';

class AdminCategorySearchDelegate extends SearchDelegate<void> {
  final WidgetRef ref;
  AdminCategorySearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final async = ref.watch(categoriesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading categories')),
      data: (list) {
        final filtered = list.where((c) {
          final name = (c['name'] as String).toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('No categories found'));
        }
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, index) {
            final cat = filtered[index];
            final catName = cat['name'] as String;
            return ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(catName, style: GoogleFonts.inter()),
              onTap: () {
                // Apply category filter in admin dashboard
                ref.read(selectedCategoryProvider.notifier).setCategory(catName);
                close(context, null);
                // Optionally navigate to admin dashboard root to reflect filter
                context.go('/admin');
              },
            );
          },
        );
      },
    );
  }
}
