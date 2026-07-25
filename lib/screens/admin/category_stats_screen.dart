import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "../../services/providers.dart";
import "../../models/post_model.dart";

class CategoryStatsScreen extends ConsumerWidget {
  const CategoryStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF2F2FA);
    final cardColor = isDark ? const Color(0xFF1A1A3E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "Category Analytics",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
              data: (postList) {
                return categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
                  data: (catList) {
                    // Extract category names
                    final catNames = catList.map((c) => c["name"] as String).toList();
                    
                    // Map categories to post counts
                    final Map<String, List<PostModel>> groupedPosts = {};
                    for (final name in catNames) {
                      groupedPosts[name] = [];
                    }
                    
                    final List<PostModel> uncategorizedPosts = [];
                    for (final p in postList) {
                      final cat = p.categoryId;
                      if (cat != null && groupedPosts.containsKey(cat)) {
                        groupedPosts[cat]!.add(p);
                      } else {
                        uncategorizedPosts.add(p);
                      }
                    }

                    // Build visual data items
                    final items = <_ChartItemData>[];
                    for (final entry in groupedPosts.entries) {
                      items.add(_ChartItemData(
                        name: entry.key,
                        posts: entry.value,
                      ));
                    }
                    
                    if (uncategorizedPosts.isNotEmpty) {
                      items.add(_ChartItemData(
                        name: "Uncategorized",
                        posts: uncategorizedPosts,
                      ));
                    }

                    // Sort items by post count descending
                    items.sort((a, b) => b.posts.length.compareTo(a.posts.length));

                    // Calculate stats
                    final totalPosts = postList.length;
                    final totalViews = postList.fold<int>(0, (sum, p) => sum + p.views);
                    final averageViews = totalPosts == 0 ? 0.0 : totalViews / totalPosts;
                    final maxPostCount = items.isEmpty ? 0 : items.first.posts.length;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Summary Stats Cards Row
                        Row(
                          children: [
                            _buildSummaryCard(
                              title: "Total Posts",
                              value: "$totalPosts",
                              icon: Icons.article_outlined,
                              cardColor: cardColor,
                              textColor: textColor,
                              primaryColor: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            _buildSummaryCard(
                              title: "Avg Views",
                              value: averageViews.toStringAsFixed(1),
                              icon: Icons.trending_up,
                              cardColor: cardColor,
                              textColor: textColor,
                              primaryColor: Colors.teal,
                            ),
                            const SizedBox(width: 12),
                            _buildSummaryCard(
                              title: "Categories",
                              value: "${groupedPosts.length}",
                              icon: Icons.category_outlined,
                              cardColor: cardColor,
                              textColor: textColor,
                              primaryColor: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Graph Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(20)),
                            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Category Post Distribution",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Visual representation of post counts in each category",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: subTextColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (items.isEmpty)
                                const Center(child: Text("No data available"))
                              else
                                ...items.map((item) {
                                  final count = item.posts.length;
                                  final percent = totalPosts == 0 ? 0.0 : count / totalPosts;
                                  final widthPercent = maxPostCount == 0 ? 0.0 : count / maxPostCount;
                                  final viewsSum = item.posts.fold<int>(0, (sum, p) => sum + p.views);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 18.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "$count (${(percent * 100).toStringAsFixed(1)}%)",
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 800),
                                          curve: Curves.easeOutCubic,
                                          tween: Tween<double>(begin: 0.0, end: widthPercent),
                                          builder: (context, val, child) {
                                            return FractionallySizedBox(
                                              widthFactor: val.clamp(0.0, 1.0),
                                              child: Container(
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Theme.of(context).colorScheme.primary,
                                                      Theme.of(context).colorScheme.primary.withAlpha(160),
                                                    ],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Views: $viewsSum",
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              "Avg Views: ${count == 0 ? 0.0 : (viewsSum / count).toStringAsFixed(1)}",
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor.withAlpha(30),
              child: Icon(icon, color: primaryColor, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartItemData {
  final String name;
  final List<PostModel> posts;
  _ChartItemData({required this.name, required this.posts});
}
