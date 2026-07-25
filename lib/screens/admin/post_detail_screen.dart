import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../../services/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_video_player.dart';
import '../../widgets/app_audio_player.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : Colors.grey[100];
    final cardColor = isDark ? const Color(0xFF1A1A3E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;

    final roleAsync = ref.watch(userRoleProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isSuperAdmin = roleAsync.value == 'super_admin';
    final isAuthor = widget.post.authorId == (user?.uid ?? '');
    final hasEditAccess = isSuperAdmin || isAuthor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
        title: Text("Post Details", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
        actions: [
          if (hasEditAccess)
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              onPressed: () => context.push("/admin/edit", extra: widget.post),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post metadata and content
                  _buildPostContent(textColor, subTextColor, cardColor, isDark),
                  const SizedBox(height: 24),
                  // Reactions
                  Text("Reactions", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                  const SizedBox(height: 8),
                  _buildReactions(),
                  const SizedBox(height: 24),
                  // Comments Management
                  Text("Comments Management", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                  const SizedBox(height: 8),
                  _buildComments(cardColor, textColor, subTextColor, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent(Color textColor, Color subTextColor, Color cardColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.categoryId != null)
            Wrap(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                  child: Text(widget.post.categoryId!, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
                if (widget.post.categoryId == "Books" && widget.post.bookSubcategory != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('bookSubcategories').doc(widget.post.bookSubcategory).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final name = snapshot.data!['name'] as String;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: Colors.blueAccent.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                          child: Text(name.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                if (widget.post.authorId.isNotEmpty)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(widget.post.authorId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        final name = data?['name'] ?? data?['email'] ?? 'Unknown Admin';
                        final role = data?['role'] ?? 'admin';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: Colors.grey.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                          child: Text("BY $name ($role)".toUpperCase(), style: GoogleFonts.inter(fontSize: 12, color: textColor.withAlpha(180), fontWeight: FontWeight.bold)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          // Urdu / RTL support
          Builder(builder: (ctx) {
            final isUrdu = widget.post.language == 'Urdu';
            final textDir = isUrdu ? TextDirection.rtl : TextDirection.ltr;
            final titleStyle = isUrdu
                ? GoogleFonts.notoNastaliqUrdu(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)
                : GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textColor);
            final descStyle = isUrdu
                ? GoogleFonts.notoNastaliqUrdu(fontSize: 15, color: subTextColor, height: 1.6)
                : GoogleFonts.inter(fontSize: 15, color: subTextColor, height: 1.6);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Directionality(
                textDirection: textDir,
                child: SizedBox(width: double.infinity, child: Text(widget.post.title, style: titleStyle)),
              ),
              const SizedBox(height: 8),
              Directionality(
                textDirection: textDir,
                child: SizedBox(width: double.infinity, child: Text(widget.post.description, style: descStyle)),
              ),
            ]);
          }),
          const SizedBox(height: 16),
          // View Count
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text("${widget.post.views} Views", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Text(widget.post.createdAt != null ? DateFormat('MMM d, y • h:mm a').format(widget.post.createdAt!) : '', style: GoogleFonts.inter(fontSize: 12, color: subTextColor)),
            ],
          ),
          const Divider(height: 32),
          // Poll ended / End Poll button
          if (widget.post.type == PostType.poll) ...[
            Row(
              children: [
                if (widget.post.pollEnded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                    child: Text("Poll Ended", style: GoogleFonts.inter(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Colors.orange),
                    label: Text("Finish Poll", style: GoogleFonts.inter(fontSize: 12, color: Colors.orange)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    onPressed: () async {
                      await FirestoreService.instance.endPoll(widget.post.id);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Poll ended successfully")));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Media/Content
          _buildMediaLayout(),
        ],
      ),
    );
  }

  Widget _buildMediaLayout() {
    switch (widget.post.type) {
      case PostType.image:
        return widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(widget.post.imageUrl!, fit: BoxFit.cover, width: double.infinity))
            : const SizedBox();
      case PostType.video:
        return widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty
            ? AppVideoPlayer(videoUrl: widget.post.videoUrl!)
            : const SizedBox();
      case PostType.audio:
        return widget.post.audioUrl != null && widget.post.audioUrl!.isNotEmpty
            ? AppAudioPlayer(audioUrl: widget.post.audioUrl!)
            : const SizedBox();
      case PostType.pdf:
        return widget.post.pdfUrl != null && widget.post.pdfUrl!.isNotEmpty
            ? Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: Text("Open & Read PDF File", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () {
                    launchUrl(Uri.parse(widget.post.pdfUrl!), mode: LaunchMode.externalApplication);
                  },
                ),
              )
            : const SizedBox();
      case PostType.poll:
        return _buildPollCharts();
      default:
        if (widget.post.categoryId == 'Books' && widget.post.externalUrl != null && widget.post.externalUrl!.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Icon(Icons.menu_book, size: 64, color: Colors.amberAccent),
                const SizedBox(height: 12),
                Text(widget.post.title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 6),
                Text("This item is part of the digital library.", style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3C72),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          launchUrl(Uri.parse(widget.post.externalUrl!), mode: LaunchMode.externalApplication);
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book),
                              const SizedBox(width: 6),
                              Text("Read Online", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final dlLink = _getGoogleDriveDownloadLink(widget.post.externalUrl);
                          if (dlLink != null) {
                            launchUrl(Uri.parse(dlLink), mode: LaunchMode.externalApplication);
                          }
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.download),
                              const SizedBox(width: 6),
                              Text("Download", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        if (widget.post.externalUrl != null && widget.post.externalUrl!.isNotEmpty) {
          return InkWell(
            onTap: () => launchUrl(Uri.parse(widget.post.externalUrl!), mode: LaunchMode.externalApplication),
            child: Text(widget.post.externalUrl!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
          );
        }
        return const SizedBox();
    }
  }

  Widget _buildPollCharts() {
    if (widget.post.pollOptions == null || widget.post.pollOptions!.isEmpty) return const SizedBox();
    int totalVotes = widget.post.pollOptions!.fold(0, (sum, item) => sum + item.votes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Poll Results ($totalVotes votes)", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...widget.post.pollOptions!.map((opt) {
          int v = opt.votes;
          double pct = totalVotes == 0 ? 0 : v / totalVotes;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(opt.text, style: const TextStyle(fontSize: 14)),
                    Text("$v (${(pct * 100).toStringAsFixed(1)}%)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey.withAlpha(50),
                  color: Theme.of(context).colorScheme.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReactions() {
    const Map<String, String> reactionEmojis = {
      'Like': '👍',
      'Love': '❤️',
      'Haha': '😆',
      'Wow': '😮',
      'Sad': '😢',
      'Angry': '😡',
    };

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.getReactions(widget.post.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snapshot.hasError) {
          return Text("Error loading reactions", style: TextStyle(color: Colors.red[300], fontSize: 13));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("No reactions yet.", style: TextStyle(color: Colors.grey)),
          );
        }
        final Map<String, int> counts = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] as String? ?? '';
          if (type.isNotEmpty) counts[type] = (counts[type] ?? 0) + 1;
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: counts.entries.map((e) {
            final emoji = reactionEmojis[e.key] ?? e.key;
            return Chip(
              label: Text("$emoji  ${e.value}", style: GoogleFonts.inter(fontSize: 12)),
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildComments(Color cardColor, Color textColor, Color subTextColor, bool isDark) {
    if (widget.post.commentsEnabled == false) {
      return Text("Comments are disabled for this post.", style: TextStyle(color: subTextColor));
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.getComments(widget.post.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snapshot.hasError) {
          return Text("Error loading comments: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent, fontSize: 13));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("No comments yet.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final c = docs[index];
            final data = c.data() as Map<String, dynamic>;
            final text = data['text'] ?? '';
            final uid = data['uid'] ?? 'Unknown User';
            final createdAt = data['createdAt'] as Timestamp?;
            final adminReply = data['adminReply'] as String?;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white12 : Colors.black12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 12, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 16, color: Colors.white)),
                      const SizedBox(width: 8),
                      CommentAuthorName(
                        uid: uid,
                        fallbackName: data['userName'] as String? ?? "User ${uid.length > 5 ? uid.substring(0, 5) : uid}",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                        onPressed: () => _deleteComment(c.id),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(text, style: TextStyle(color: subTextColor)),
                  const SizedBox(height: 8),
                  if (createdAt != null) Text(DateFormat('MMM d, y • h:mm a').format(createdAt.toDate()), style: TextStyle(fontSize: 10, color: subTextColor)),
                  
                  if (adminReply != null && adminReply.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, size: 14, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text("Admin Reply", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(adminReply, style: TextStyle(fontSize: 13, color: textColor)),
                        ],
                      ),
                    ),
                  ],

                  if (adminReply == null || adminReply.isEmpty) ...[
                    const Divider(),
                    _AdminReplyWidget(postId: widget.post.id, commentId: c.id),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteComment(String commentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Comment"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await FirestoreService.instance.deleteComment(widget.post.id, commentId);
    }
  }
}

class _AdminReplyWidget extends StatefulWidget {
  final String postId;
  final String commentId;
  const _AdminReplyWidget({required this.postId, required this.commentId});
  @override
  State<_AdminReplyWidget> createState() => _AdminReplyWidgetState();
}

class _AdminReplyWidgetState extends State<_AdminReplyWidget> {
  final _ctrl = TextEditingController();
  bool _isReplying = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (!_isReplying) {
      return TextButton.icon(
        icon: const Icon(Icons.reply, size: 16),
        label: const Text("Reply as Admin"),
        onPressed: () => setState(() => _isReplying = true),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: "Type reply...", 
              isDense: true,
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.black12,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
          onPressed: () async {
            if (_ctrl.text.trim().isEmpty) return;
            await FirestoreService.instance.replyToComment(postId: widget.postId, commentId: widget.commentId, replyText: _ctrl.text.trim());
            _ctrl.clear();
            setState(() => _isReplying = false);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reply sent")));
          },
        ),
      ],
    );
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
