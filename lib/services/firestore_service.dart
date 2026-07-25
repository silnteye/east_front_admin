import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserIfNotExists({required String uid}) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return;
    await _db.collection('users').doc(uid).set({
      'uid': uid, 'role': 'user', 'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createOrUpdateUser({required String uid, required String role}) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid, 'role': role, 'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> getRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return 'user';
    return doc['role'] ?? 'user';
  }

  Stream<List<PostModel>> getPosts() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => PostModel.fromJson(d.id, d.data())).toList(),
    );
  }

  Future<void> createPost({required Map<String, dynamic> data}) async {
    await _db.collection('posts').add(data);
  }

  Future<void> updatePost({required String postId, required Map<String, dynamic> data}) async {
    await _db.collection('posts').doc(postId).update(data);
  }

  Future<void> deletePost(String postId) async {
    final batch = _db.batch();

    // 1. Delete all comment documents in the subcollection
    final commentsSnapshot = await _db.collection('posts').doc(postId).collection('comments').get();
    for (var doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete all reaction documents in the subcollection
    final reactionsSnapshot = await _db.collection('posts').doc(postId).collection('reactions').get();
    for (var doc in reactionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Commit the subcollection deletions
    await batch.commit();

    // 4. Delete the parent post document
    await _db.collection('posts').doc(postId).delete();
  }

  Future<void> togglePinPost(String postId, bool isPinned) async {
    await _db.collection('posts').doc(postId).update({'isPinned': isPinned});
  }

  Future<bool> incrementView(String postId, String uid) async {
    final viewId = '${postId}_$uid';
    final viewRef = _db.collection('views').doc(viewId);
    final doc = await viewRef.get();
    if (!doc.exists) {
      await viewRef.set({
        'postId': postId,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('posts').doc(postId).update({'views': FieldValue.increment(1)});
      return true;
    }
    return false;
  }

  Future<bool> hasVotedPoll(String postId, String uid) async {
    final voteId = '${postId}_$uid';
    final doc = await _db.collection('pollVotes').doc(voteId).get();
    return doc.exists;
  }

  Future<void> votePoll({required String postId, required String uid, required String optionId}) async {
    final voteId = '${postId}_$uid';
    final doc = await _db.collection('pollVotes').doc(voteId).get();
    if (doc.exists) return;
    await _db.collection('pollVotes').doc(voteId).set({'postId': postId, 'uid': uid, 'optionId': optionId});
    // Increment option votes
    final postDoc = await _db.collection('posts').doc(postId).get();
    if (!postDoc.exists) return;
    final data = postDoc.data()!;
    final options = List<Map<String, dynamic>>.from(data['pollOptions'] ?? []);
    final updated = options.map((o) {
      if (o['id'] == optionId) return {...o, 'votes': (o['votes'] ?? 0) + 1};
      return o;
    }).toList();
    await _db.collection('posts').doc(postId).update({'pollOptions': updated});
  }

  Future<void> toggleBookmark(String postId, String uid) async {
    final id = '${postId}_$uid';
    final doc = _db.collection('bookmarks').doc(id);
    final exists = await doc.get();
    if (exists.exists) {
      await doc.delete();
    } else {
      await doc.set({'postId': postId, 'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Future<bool> isBookmarked(String postId, String uid) async {
    final id = '${postId}_$uid';
    final doc = await _db.collection('bookmarks').doc(id).get();
    return doc.exists;
  }

  Stream<List<PostModel>> getBookmarkedPosts(String uid) {
    return _db.collection('bookmarks').where('uid', isEqualTo: uid).snapshots().asyncMap(
      (snap) async {
        final postIds = snap.docs.map((d) => d['postId'] as String).toList();
        if (postIds.isEmpty) return [];
        final posts = await Future.wait(postIds.map((id) => _db.collection('posts').doc(id).get()));
        return posts.where((d) => d.exists).map((d) => PostModel.fromJson(d.id, d.data()!)).toList();
      },
    );
  }

  Stream<QuerySnapshot> getComments(String postId) {
    return _db.collection('posts').doc(postId).collection('comments')
        .orderBy('createdAt').snapshots();
  }

  Stream<QuerySnapshot> getLatestComments() {
    return _db.collectionGroup('comments')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();
  }

  Stream<int> getCommentsCount() {
    return _db.collectionGroup('comments').snapshots().map((snap) => snap.docs.length);
  }

  Future<void> addComment({required String postId, required String uid, required String text}) async {
    String userName = "User";
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        userName = userDoc.data()?['name'] as String? ?? "User";
      }
    } catch (_) {}
    await _db.collection('posts').doc(postId).collection('comments').add({
      'uid': uid,
      'text': text,
      'userName': userName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _db.collection('posts').doc(postId).collection('comments').doc(commentId).delete();
  }

  Future<void> replyToComment({required String postId, required String commentId, required String replyText}) async {
    await _db.collection('posts').doc(postId).collection('comments').doc(commentId).update({
      'adminReply': replyText,
      'adminReplyAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getReactions(String postId) {
    return _db.collection('posts').doc(postId).collection('reactions').snapshots();
  }

  Future<void> setReaction({required String postId, required String uid, required String type, required String userName}) async {
    await _db.collection('posts').doc(postId).collection('reactions').doc(uid).set({
      'uid': uid,
      'type': type,
      'userName': userName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeReaction({required String postId, required String uid}) async {
    await _db.collection('posts').doc(postId).collection('reactions').doc(uid).delete();
  }

  Future<void> endPoll(String postId) async {
    await _db.collection('posts').doc(postId).update({'pollEnded': true});
  }

  Stream<List<Map<String, dynamic>>> getBookSubcategories() {
    return _db.collection('bookSubcategories').snapshots().map(
      (snap) {
        final list = snap.docs.map((d) => {'id': d.id, 'name': d['name'] ?? '', 'position': d.data().containsKey('position') ? d['position'] : 999}).toList();
        list.sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
        return list;
      },
    );
  }

  Future<void> addBookSubcategory(String name, {int position = 999}) async {
    await _db.collection('bookSubcategories').add({
      'name': name,
      'position': position,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBookSubcategory(String id, String name) async {
    await _db.collection('bookSubcategories').doc(id).update({'name': name});
  }

  Future<void> deleteBookSubcategory(String id) async {
    await _db.collection('bookSubcategories').doc(id).delete();
  }

  Future<void> updateBookSubcategoriesOrder(List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    for (int i = 0; i < items.length; i++) {
      final docRef = _db.collection('bookSubcategories').doc(items[i]['id']);
      batch.update(docRef, {'position': i});
    }
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getCategories() {
    return _db.collection('categories').snapshots().map(
      (snap) {
        final list = snap.docs.map((d) => {'id': d.id, 'name': d['name'] ?? '', 'position': d.data().containsKey('position') ? d['position'] : 999}).toList();
        list.sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
        return list;
      },
    );
  }

  Future<void> addCategory(String name, {int position = 999}) async {
    await _db.collection('categories').add({
      'name': name,
      'position': position,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(String id, String name) async {
    await _db.collection('categories').doc(id).update({'name': name});
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  Future<void> updateCategoriesOrder(List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    for (int i = 0; i < items.length; i++) {
      final docRef = _db.collection('categories').doc(items[i]['id']);
      batch.update(docRef, {'position': i});
    }
    await batch.commit();
  }

  Future<void> initializeDefaultCategories() async {
    final snap = await _db.collection('categories').limit(1).get();
    if (snap.docs.isEmpty) {
      final defaults = ["Political", "History", "Announcements", "Books", "E-News", "Survey"];
      for (int i = 0; i < defaults.length; i++) {
        await _db.collection('categories').add({
          'name': defaults[i],
          'position': i,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Stream<int> getRegisteredUsersCount() {
    return _db.collection("users")
        .where("isAnonymous", isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}

