import "package:flutter/material.dart";
import "package:east_front_admin/widgets/admin_post_search_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:intl/intl.dart" hide TextDirection;
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "../../services/providers.dart";
import "../../services/firestore_service.dart";
import "../../services/auth_service.dart";
import "../../models/post_model.dart";
import "../../widgets/admin_drawer.dart";
import "package:url_launcher/url_launcher.dart";
import "../../widgets/app_video_player.dart";
import "../../widgets/app_audio_player.dart";

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _showComments = false;

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(postsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF2F2FA);
    final appBarColor = isDark ? const Color(0xFF1A1A3E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search Posts",
            onPressed: () => showSearch(
              context: context,
              delegate: AdminPostSearchDelegate(ref),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Sign Out",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Sign Out"),
                  content: const Text("Are you sure you want to sign out from the Admin Panel?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Sign Out", style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthService.instance.logout();
              }
            },
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 2),
            Row(
              children: [
                Image.asset(
                  'assets/icons/admin.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text("Admin Panel", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor, fontSize: 16), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 25),
                ref.watch(activeUsersCountProvider).when(
                  data: (count) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$count __Online",
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("New Post", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => context.push("/admin/create"),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Section
                posts.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (list) {
                    return _StatsRow(
                      posts: list,
                      isDark: isDark,
                      onCommentsTap: () {
                        setState(() {
                          _showComments = true;
                        });
                      },
                    );
                  },
                ),
                // Tab Selection Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showComments = false),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Posts",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: !_showComments ? cs.primary : textColor.withAlpha(120),
                              ),
                            ),
                            if (!_showComments)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () => setState(() => _showComments = true),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Latest Comments",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _showComments ? cs.primary : textColor.withAlpha(120),
                              ),
                            ),
                            if (_showComments)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_showComments) ...[
                  // Category Filter
                  categoriesAsync.when(
                    loading: () => const SizedBox(height: 54),
                    error: (_, __) => const SizedBox(height: 54),
                    data: (catsList) {
                      final cats = ["All", ...catsList.map((c) => c["name"] as String)];
                      return SizedBox(
                        height: 54,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: cats.length,
                          itemBuilder: (context, index) {
                            final cat = cats[index];
                            final isSelected = ref.watch(selectedCategoryProvider) == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat, style: GoogleFonts.inter(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) ref.read(selectedCategoryProvider.notifier).setCategory(cat);
                                },
                                selectedColor: Theme.of(context).colorScheme.primary,
                                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  // Post List
                  Expanded(
                    child: posts.when(
                      loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                      error: (e, _) => Center(child: Text("Error loading posts: $e", style: const TextStyle(color: Colors.redAccent))),
                      data: (list) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final now = DateTime.now();
                          for (final post in list) {
                            if (post.autoExpire && post.expireDate != null && post.expireDate!.isBefore(now)) {
                              FirestoreService.instance.deletePost(post.id).catchError((e) {
                                debugPrint("Failed to delete expired post: $e");
                              });
                            }
                          }
                        });
                        final selCat = ref.watch(selectedCategoryProvider);
                        final filtered = selCat == 'All' ? list : list.where((p) => p.categoryId == selCat).toList();
                        
                        final sorted = [...filtered]..sort((a, b) {
                          if (a.isPinned && !b.isPinned) return -1;
                          if (!a.isPinned && b.isPinned) return 1;
                          return 0;
                        });

                        if (sorted.isEmpty) {
                          return Center(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.article_outlined, size: 80, color: isDark ? Colors.white12 : Colors.black12),
                              const SizedBox(height: 16),
                              Text("No posts in \"$selCat\"", style: GoogleFonts.inter(fontSize: 18, color: isDark ? Colors.white38 : Colors.black38)),
                              const SizedBox(height: 8),
                              Text("Tap + to create one", style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black26)),
                            ]),
                          );
                        }
                        return RefreshIndicator(
                          color: Theme.of(context).colorScheme.primary,
                          onRefresh: () async => ref.refresh(postsProvider),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: sorted.length,
                            itemBuilder: (ctx, i) => PostAdminCard(post: sorted[i], isDark: isDark),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Latest Comments Widget
                  Expanded(
                    child: _LatestCommentsWidget(isDark: isDark, cs: cs, textColor: textColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends ConsumerStatefulWidget {
  final List<PostModel> posts;
  final bool isDark;
  final VoidCallback? onCommentsTap;

  const _StatsRow({
    required this.posts,
    required this.isDark,
    this.onCommentsTap,
  });

  @override
  ConsumerState<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends ConsumerState<_StatsRow> {
  final ScrollController _scrollController = ScrollController();
  bool _userInteracting = false;
  DateTime _lastInteractionTime = DateTime.now().subtract(const Duration(seconds: 10));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loop();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      if (_userInteracting || DateTime.now().difference(_lastInteractionTime).inSeconds < 3) {
        continue;
      }
      if (!_scrollController.hasClients) continue;

      double position = _scrollController.offset;
      final cycleWidth = 118.0 * 6; // 6 cards of 118px width each (110px card + 8px margin)

      if (position >= cycleWidth) {
        _scrollController.jumpTo(position - cycleWidth);
        position = _scrollController.offset;
      }

      await _scrollController.animateTo(
        position + 118.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onInteraction() {
    _lastInteractionTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.posts;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 72,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              if (notification.dragDetails != null) {
                setState(() {
                  _userInteracting = true;
                });
              }
            } else if (notification is ScrollUpdateNotification) {
              if (notification.dragDetails != null) {
                _onInteraction();
              }
            } else if (notification is ScrollEndNotification) {
              setState(() {
                _userInteracting = false;
                _onInteraction();
              });
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final cardIndex = index % 6;
              return _buildCardForIndex(cardIndex, context, list);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardForIndex(int index, BuildContext context, List<PostModel> list) {
    final totalPosts = list.length;
    final activePolls = list.where((p) => p.type == PostType.poll && !p.pollEnded).length;
    final totalViews = list.fold(0, (sum, p) => sum + p.views);
    final pinned = list.where((p) => p.isPinned).length;

    switch (index) {
      case 0:
        return _buildCard(
          label: "Posts", 
          value: "$totalPosts", 
          icon: Icons.article_outlined, 
          onTap: () => context.push("/admin/stats"),
        );
      case 1:
        return _buildCard(label: "Polls", value: "$activePolls", icon: Icons.poll_outlined);
      case 2:
        return _buildCard(label: "Pinned", value: "$pinned", icon: Icons.push_pin_outlined);
      case 3:
        return _buildCard(label: "Views", value: _compact(totalViews), icon: Icons.visibility_outlined);
      case 4:
        return StreamBuilder<int>(
          stream: FirestoreService.instance.getRegisteredUsersCount(),
          builder: (context, snapshot) {
            final usersCount = snapshot.data ?? 0;
            final isSuperAdmin = ref.watch(userRoleProvider).value == 'super_admin';
            return _buildCard(
              label: "Users", 
              value: isSuperAdmin ? "$usersCount" : "🔒", 
              icon: Icons.people_outline,
              onTap: isSuperAdmin ? () => context.push("/admin/users") : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Access Denied: Super Admin privileges required."))
                );
              },
            );
          },
        );
      case 5:
        return StreamBuilder<int>(
          stream: FirestoreService.instance.getCommentsCount(),
          builder: (context, snapshot) {
            final commentsCount = snapshot.data ?? 0;
            return _buildCard(
              label: "Comments", 
              value: "$commentsCount", 
              icon: Icons.comment_outlined,
              onTap: widget.onCommentsTap,
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCard({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1A1A3E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(120),
              width: 1.5,
            ),
            boxShadow: widget.isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16),
                  Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black87)),
                ],
              ),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return "$n";
  }
}

class PostAdminCard extends ConsumerWidget {
  final PostModel post;
  final bool isDark;
  const PostAdminCard({required this.post, required this.isDark, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardColor = isDark ? const Color(0xFF1A1A3E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final isUrdu = post.language == 'Urdu';
    final titleStyle = isUrdu
        ? GoogleFonts.notoNastaliqUrdu(fontWeight: FontWeight.bold, color: textColor, fontSize: 18)
        : GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor, fontSize: 15);
    final descStyle = isUrdu
        ? GoogleFonts.notoNastaliqUrdu(fontSize: 14, color: subTextColor)
        : GoogleFonts.inter(color: subTextColor, fontSize: 13);

    final roleAsync = ref.watch(userRoleProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isSuperAdmin = roleAsync.value == 'super_admin';
    final isAuthor = post.authorId == (user?.uid ?? '');
    final hasEditAccess = isSuperAdmin || isAuthor;

    return GestureDetector(
      onTap: () => context.push("/admin/post", extra: post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: post.isPinned ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white10 : Colors.black12), width: 1.5),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned Banner
            if (post.isPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(children: [
                  const Icon(Icons.push_pin, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text("Pinned Post", style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),

            // Multiple media scroll or single image
            if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty)
              ClipRRect(
                borderRadius: post.isPinned ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(14)),
                child: SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: post.mediaUrls!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(post.mediaUrls![i], width: 220, height: 144, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 220, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white38)),
                      ),
                    ),
                  ),
                ),
              )
            else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: post.isPinned ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  post.imageUrl!,
                  height: 160, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white38)),
                ),
              ),

            if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
              AppVideoPlayer(videoUrl: post.videoUrl!),

            if (post.type == PostType.audio && (post.audioUrl != null && post.audioUrl!.isNotEmpty || post.externalUrl != null && post.externalUrl!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: AppAudioPlayer(audioUrl: post.audioUrl ?? post.externalUrl!),
              ),

            if (post.type == PostType.pdf)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(15),
                  borderRadius: post.isPinned ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.picture_as_pdf, size: 24, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("PDF Document", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                          const SizedBox(height: 2),
                          Text("View or download file", style: GoogleFonts.inter(fontSize: 11, color: subTextColor)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 12),
                      label: Text("Open", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        if (post.pdfUrl != null && post.pdfUrl!.isNotEmpty) {
                          launchUrl(Uri.parse(post.pdfUrl!), mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
              ),

            if (post.type == PostType.audio)
              Container(
                height: 70, width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  borderRadius: post.isPinned ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.headphones, size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Text("Audio Clip", style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (post.categoryId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text(post.categoryId!.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    if (post.categoryId == "Books" && post.bookSubcategory != null)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('bookSubcategories').doc(post.bookSubcategory).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final name = snapshot.data!['name'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blueAccent.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                                child: Text(name.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    if (post.authorId.isNotEmpty)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(post.authorId).get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final name = data?['name'] ?? data?['email'] ?? 'Unknown Admin';
                            final role = data?['role'] ?? 'admin';
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                "by $name ($role)",
                                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    const Spacer(),
                    Text(
                      post.createdAt != null ? DateFormat("d MMM y").format(post.createdAt!) : "",
                      style: GoogleFonts.inter(fontSize: 11, color: subTextColor),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(post.title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(post.description, style: descStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  if (post.categoryId == 'Books' && post.externalUrl != null && post.externalUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            ),
                            onPressed: () => launchUrl(Uri.parse(post.externalUrl!), mode: LaunchMode.externalApplication),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.menu_book, size: 16),
                                  const SizedBox(width: 6),
                                  Text("Read Online", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            ),
                            onPressed: () {
                              final dl = _getGoogleDriveDownloadLink(post.externalUrl);
                              if (dl != null) launchUrl(Uri.parse(dl), mode: LaunchMode.externalApplication);
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.download, size: 16),
                                  const SizedBox(width: 6),
                                  Text("Download", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.visibility_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text("${post.views}", style: GoogleFonts.inter(color: subTextColor, fontSize: 12)),
                    const SizedBox(width: 16),
                    Icon(post.type == PostType.poll ? Icons.poll_outlined : _postTypeIcon(post.type), size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(post.type.name.toUpperCase(), style: GoogleFonts.inter(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (hasEditAccess)
                      PopupMenuButton<String>(
                        color: cardColor,
                        icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.primary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (v) async {
                          if (v == "edit") context.push("/admin/edit", extra: post);
                          if (v == "pin") await FirestoreService.instance.togglePinPost(post.id, !post.isPinned);
                          if (v == "delete") {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: cardColor,
                                title: Text("Delete Post", style: TextStyle(color: textColor)),
                                content: Text("Delete \"${post.title}\"?", style: TextStyle(color: subTextColor)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
                                ],
                              ),
                            );
                            if (ok == true) await FirestoreService.instance.deletePost(post.id);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: "edit", child: ListTile(leading: Icon(Icons.edit, color: subTextColor), title: Text("Edit", style: TextStyle(color: textColor)))),
                          PopupMenuItem(value: "pin", child: ListTile(leading: Icon(post.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: subTextColor), title: Text(post.isPinned ? "Unpin" : "Pin", style: TextStyle(color: textColor)))),
                          const PopupMenuItem(value: "delete", child: ListTile(leading: Icon(Icons.delete, color: Colors.redAccent), title: Text("Delete", style: TextStyle(color: Colors.redAccent)))),
                        ],
                      ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _postTypeIcon(PostType t) {
    switch (t) {
      case PostType.image: return Icons.image_outlined;
      case PostType.video: return Icons.videocam_outlined;
      case PostType.audio: return Icons.headphones_outlined;
      case PostType.pdf: return Icons.picture_as_pdf_outlined;
      case PostType.poll: return Icons.poll_outlined;
      case PostType.link: return Icons.link_outlined;
      default: return Icons.article_outlined;
    }
  }

  String? _getGoogleDriveDownloadLink(String? url) {
    if (url == null) return null;
    final regex = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return url;
  }
}

class _LatestCommentsWidget extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  final Color textColor;

  const _LatestCommentsWidget({
    required this.isDark,
    required this.cs,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.getLatestComments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading comments: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.comment_outlined, size: 80, color: isDark ? Colors.white24 : Colors.black12),
                const SizedBox(height: 16),
                Text("No comments found", style: GoogleFonts.inter(fontSize: 18, color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final text = data['text'] ?? '';
            final uid = data['uid'] ?? '';
            final userName = data['userName'] ?? 'User';
            final createdAt = data['createdAt'] as Timestamp?;
            
            final pathSegments = doc.reference.path.split('/');
            final postId = pathSegments.length >= 2 ? pathSegments[1] : '';

            return _CommentDashboardCard(
              postId: postId,
              commentId: doc.id,
              uid: uid,
              userName: userName,
              text: text,
              createdAt: createdAt,
              isDark: isDark,
              cs: cs,
              textColor: textColor,
            );
          },
        );
      },
    );
  }
}

class _CommentDashboardCard extends StatelessWidget {
  final String postId;
  final String commentId;
  final String uid;
  final String userName;
  final String text;
  final Timestamp? createdAt;
  final bool isDark;
  final ColorScheme cs;
  final Color textColor;

  const _CommentDashboardCard({
    required this.postId,
    required this.commentId,
    required this.uid,
    required this.userName,
    required this.text,
    required this.createdAt,
    required this.isDark,
    required this.cs,
    required this.textColor,
  });

  Future<void> _openPost(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final postDoc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
      if (context.mounted) Navigator.pop(context); // Dismiss loading dialog
      if (postDoc.exists) {
        final post = PostModel.fromJson(postDoc.id, postDoc.data()!);
        if (context.mounted) {
          context.push("/admin/post", extra: post);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post not found or has been deleted.")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Dismiss loading dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening post: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1A1A3E) : Colors.white;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isDark ? 0 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPost(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CommentAuthorName(
                    uid: uid,
                    fallbackName: userName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 13),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        createdAt != null ? _formatRelativeTime(createdAt!.toDate()) : 'Just now',
                        style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: cardColor,
                              title: const Text("Delete Comment"),
                              content: const Text("Are you sure you want to delete this comment?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await FirestoreService.instance.deleteComment(postId, commentId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Comment deleted successfully")),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: CommentPostTitle(
                      postId: postId,
                      style: GoogleFonts.inter(
                        color: subTextColor,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: GoogleFonts.inter(fontSize: 13, color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final count = difference.inMinutes;
      return '$count ${count == 1 ? "minute" : "minutes"} ago';
    } else if (difference.inHours < 24) {
      final count = difference.inHours;
      return '$count ${count == 1 ? "hour" : "hours"} ago';
    } else if (difference.inDays < 7) {
      final count = difference.inDays;
      return '$count ${count == 1 ? "day" : "days"} ago';
    } else {
      return DateFormat('MMM d, y • h:mm a').format(dateTime);
    }
  }
}

class CommentPostTitle extends StatefulWidget {
  final String postId;
  final TextStyle style;
  const CommentPostTitle({super.key, required this.postId, required this.style});
  @override
  State<CommentPostTitle> createState() => _CommentPostTitleState();
}

class _CommentPostTitleState extends State<CommentPostTitle> {
  static final Map<String, String> _titleCache = {};

  @override
  Widget build(BuildContext context) {
    if (_titleCache.containsKey(widget.postId)) {
      return Text(_titleCache[widget.postId]!, style: widget.style, overflow: TextOverflow.ellipsis, maxLines: 1);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('posts').doc(widget.postId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final title = data?['title'] as String? ?? 'Untitled Post';
          _titleCache[widget.postId] = title;
          return Text(title, style: widget.style, overflow: TextOverflow.ellipsis, maxLines: 1);
        }
        return Text('Loading post title...', style: widget.style, overflow: TextOverflow.ellipsis, maxLines: 1);
      },
    );
  }
}

class CommentAuthorName extends StatefulWidget {
  final String uid;
  final String fallbackName;
  final TextStyle style;
  const CommentAuthorName({super.key, required this.uid, required this.fallbackName, required this.style});
  @override
  State<CommentAuthorName> createState() => _CommentAuthorNameState();
}

class _CommentAuthorNameState extends State<CommentAuthorName> {
  static final Map<String, String> _nameCache = {};

  @override
  Widget build(BuildContext context) {
    if (widget.uid.isEmpty) {
      return Text(widget.fallbackName, style: widget.style);
    }
    if (_nameCache.containsKey(widget.uid)) {
      return Text(_nameCache[widget.uid]!, style: widget.style);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final name = data?['name'] as String?;
          if (name != null && name.isNotEmpty) {
            _nameCache[widget.uid] = name;
            return Text(name, style: widget.style);
          }
        }
        return Text(widget.fallbackName, style: widget.style);
      },
    );
  }
}
