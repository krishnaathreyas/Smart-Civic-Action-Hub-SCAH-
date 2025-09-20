// presentation/providers/comments_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/comment_model.dart';

class CommentsProvider extends ChangeNotifier {
  final Map<String, List<CommentModel>> _commentsByReport = {};
  final Map<String, Set<String>> _upvotesByComment = {}; // commentId -> userIds
  final Set<String> _spamFlags = {}; // commentIds flagged as spam
  final Set<String> _officialResponseIds = {}; // commentIds marked official

  List<CommentModel> getComments(String reportId) =>
      List.unmodifiable(_commentsByReport[reportId] ?? const []);

  bool isCommentUpvoted(String commentId, String userId) =>
      _upvotesByComment[commentId]?.contains(userId) ?? false;

  int upvoteCount(String commentId) =>
      _upvotesByComment[commentId]?.length ?? 0;

  bool isSpam(String commentId) => _spamFlags.contains(commentId);

  bool isOfficial(String commentId) => _officialResponseIds.contains(commentId);

  Future<void> addComment(CommentModel comment) async {
    final list = _commentsByReport.putIfAbsent(comment.reportId, () => []);
    list.add(comment);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleUpvote(String commentId, String userId) async {
    final set = _upvotesByComment.putIfAbsent(commentId, () => <String>{});
    if (!set.add(userId)) set.remove(userId);
    await _persist();
    notifyListeners();
  }

  Future<void> flagSpam(String commentId) async {
    _spamFlags.add(commentId);
    await _persist();
    notifyListeners();
  }

  Future<void> markOfficial(String commentId) async {
    _officialResponseIds.add(commentId);
    await _persist();
    notifyListeners();
  }

  // Persistence (simple local demo)
  static const _kKey = 'comments_provider_v1';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      // Comments
      _commentsByReport.clear();
      final commentsMap = data['commentsByReport'] as Map<String, dynamic>;
      commentsMap.forEach((reportId, list) {
        _commentsByReport[reportId] = (list as List)
            .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
      // Upvotes
      _upvotesByComment.clear();
      final upvotesMap = data['upvotesByComment'] as Map<String, dynamic>;
      upvotesMap.forEach((cid, list) {
        _upvotesByComment[cid] = (list as List).map((e) => e as String).toSet();
      });
      // Spam
      _spamFlags
        ..clear()
        ..addAll((data['spamFlags'] as List).map((e) => e as String));
      // Official
      _officialResponseIds
        ..clear()
        ..addAll((data['officialResponseIds'] as List).map((e) => e as String));
    } catch (_) {
      // ignore corrupt state
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'commentsByReport': _commentsByReport.map(
          (rid, list) => MapEntry(rid, list.map((c) => c.toJson()).toList()),
        ),
        'upvotesByComment': _upvotesByComment.map(
          (cid, set) => MapEntry(cid, set.toList()),
        ),
        'spamFlags': _spamFlags.toList(),
        'officialResponseIds': _officialResponseIds.toList(),
      };
      await prefs.setString(_kKey, jsonEncode(data));
    } catch (_) {}
  }
}
