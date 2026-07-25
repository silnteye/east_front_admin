import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { text, image, audio, video, pdf, link, poll }

class PollOption {
  final String id;
  final String text;
  final int votes;
  PollOption({required this.id, required this.text, this.votes = 0});
  factory PollOption.fromJson(Map<String, dynamic> j) =>
      PollOption(id: j['id'] ?? '', text: j['text'] ?? '', votes: j['votes'] ?? 0);
  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'votes': votes};
}

class PostModel {
  final String id;
  final String title;
  final String description;
  final String? categoryId;
  final PostType type;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String? pdfUrl;
  final String? externalUrl;
  final List<String>? mediaUrls; // multiple media files
  final bool allowDownload;
  final int views;
  final int shareCount;
  final bool autoExpire;
  final int? expireDays;
  final List<PollOption>? pollOptions;
  final DateTime? createdAt;
  final DateTime? expireDate;
  final bool isPinned;
  final String authorId;
  final bool commentsEnabled;
  final String language;
  final DateTime? pollExpiryDate;
  final bool pollEnded;
  final String? bookSubcategory;

  PostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.pdfUrl,
    this.externalUrl,
    this.mediaUrls,
    this.allowDownload = true,
    this.views = 0,
    this.shareCount = 0,
    this.autoExpire = false,
    this.expireDays,
    this.pollOptions,
    this.categoryId,
    this.createdAt,
    this.expireDate,
    this.isPinned = false,
    required this.authorId,
    this.commentsEnabled = true,
    this.language = 'en',
    this.pollExpiryDate,
    this.pollEnded = false,
    this.bookSubcategory,
  });

  factory PostModel.fromJson(String id, Map<String, dynamic> json) {
    return PostModel(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: PostType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PostType.text,
      ),
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      videoUrl: json['videoUrl'],
      pdfUrl: json['pdfUrl'],
      externalUrl: json['externalUrl'],
      mediaUrls: json['mediaUrls'] != null ? List<String>.from(json['mediaUrls']) : null,
      allowDownload: json['allowDownload'] ?? true,
      views: json['views'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      autoExpire: json['autoExpire'] ?? false,
      expireDays: json['expireDays'],
      categoryId: json['categoryId'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      expireDate: json['expireDate'] != null
          ? (json['expireDate'] as Timestamp).toDate()
          : null,
      isPinned: json['isPinned'] ?? false,
      authorId: json['authorId'] ?? '',
      pollOptions: json['pollOptions'] != null
          ? (json['pollOptions'] as List)
              .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      commentsEnabled: json['commentsEnabled'] ?? true,
      language: json['language'] ?? 'en',
      pollExpiryDate: json['pollExpiryDate'] != null
          ? (json['pollExpiryDate'] as Timestamp).toDate()
          : null,
      pollEnded: json['pollEnded'] ?? false,
      bookSubcategory: json['bookSubcategory'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'type': type.name,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'pdfUrl': pdfUrl,
        'externalUrl': externalUrl,
        'mediaUrls': mediaUrls,
        'allowDownload': allowDownload,
        'views': views,
        'shareCount': shareCount,
        'autoExpire': autoExpire,
        'expireDays': expireDays,
        'categoryId': categoryId,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'expireDate': expireDate != null ? Timestamp.fromDate(expireDate!) : null,
        'isPinned': isPinned,
        'authorId': authorId,
        'pollOptions': pollOptions?.map((e) => e.toJson()).toList(),
        'commentsEnabled': commentsEnabled,
        'language': language,
        'pollExpiryDate': pollExpiryDate != null ? Timestamp.fromDate(pollExpiryDate!) : null,
        'pollEnded': pollEnded,
        'bookSubcategory': bookSubcategory,
      };
}
