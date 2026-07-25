import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/providers.dart';
import '../screens/admin/admin_dashboard.dart';

class AdminPostSearchDelegate extends SearchDelegate<void> {
  final WidgetRef ref;
  AdminPostSearchDelegate(this.ref);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (query.trim().isEmpty) {
      return const Center(child: Text('Type to search posts...'));
    }
    final postsAsync = ref.watch(postsProvider);
    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        final filtered = list.where((p) {
          final titleMatch = p.title.toLowerCase().contains(query.toLowerCase());
          final descMatch = p.description.toLowerCase().contains(query.toLowerCase());
          return titleMatch || descMatch;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No posts found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (_, index) {
            return PostAdminCard(
              post: filtered[index],
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}
