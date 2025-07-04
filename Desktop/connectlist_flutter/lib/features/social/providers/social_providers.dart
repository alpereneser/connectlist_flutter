import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_service.dart';
import '../../auth/models/user_model.dart';

// FOLLOW/UNFOLLOW PROVIDERS

/// Provider to check if current user is following a specific user
final isFollowingProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final socialService = ref.read(socialServiceProvider);
  return await socialService.isFollowing(userId);
});

/// Provider to get followers of a user
final followersProvider = FutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final socialService = ref.read(socialServiceProvider);
  return await socialService.getFollowers(userId);
});

/// Provider to get users that a user is following
final followingProvider = FutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final socialService = ref.read(socialServiceProvider);
  return await socialService.getFollowing(userId);
});

/// State notifier for follow/unfollow actions
class FollowNotifier extends StateNotifier<AsyncValue<bool>> {
  final SocialService _socialService;
  final Ref _ref;

  FollowNotifier(this._socialService, this._ref) : super(const AsyncValue.loading());

  /// Follow a user
  Future<void> followUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _socialService.followUser(userId);
      state = const AsyncValue.data(true);
      
      // Invalidate related providers
      _ref.invalidate(isFollowingProvider(userId));
      _ref.invalidate(followersProvider(userId));
      _ref.invalidate(recommendedUsersProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _socialService.unfollowUser(userId);
      state = const AsyncValue.data(false);
      
      // Invalidate related providers
      _ref.invalidate(isFollowingProvider(userId));
      _ref.invalidate(followersProvider(userId));
      _ref.invalidate(recommendedUsersProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Toggle follow status
  Future<void> toggleFollow(String userId) async {
    try {
      final isFollowing = await _socialService.isFollowing(userId);
      if (isFollowing) {
        await unfollowUser(userId);
      } else {
        await followUser(userId);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final followNotifierProvider = StateNotifierProvider<FollowNotifier, AsyncValue<bool>>((ref) {
  final socialService = ref.read(socialServiceProvider);
  return FollowNotifier(socialService, ref);
});

// LIKE/UNLIKE PROVIDERS

/// Provider to check if current user has liked a specific list
final isListLikedProvider = FutureProvider.family<bool, String>((ref, listId) async {
  final socialService = ref.read(socialServiceProvider);
  return await socialService.isListLiked(listId);
});

/// Provider to get users who liked a list
final listLikersProvider = FutureProvider.family<List<UserModel>, String>((ref, listId) async {
  final socialService = ref.read(socialServiceProvider);
  return await socialService.getListLikers(listId);
});

/// State notifier for like/unlike actions
class LikeNotifier extends StateNotifier<AsyncValue<bool>> {
  final SocialService _socialService;
  final Ref _ref;

  LikeNotifier(this._socialService, this._ref) : super(const AsyncValue.loading());

  /// Like a list
  Future<void> likeList(String listId) async {
    state = const AsyncValue.loading();
    try {
      await _socialService.likeList(listId);
      state = const AsyncValue.data(true);
      
      // Invalidate related providers
      _ref.invalidate(isListLikedProvider(listId));
      _ref.invalidate(listLikersProvider(listId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Unlike a list
  Future<void> unlikeList(String listId) async {
    state = const AsyncValue.loading();
    try {
      await _socialService.unlikeList(listId);
      state = const AsyncValue.data(false);
      
      // Invalidate related providers
      _ref.invalidate(isListLikedProvider(listId));
      _ref.invalidate(listLikersProvider(listId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Toggle like status
  Future<void> toggleLike(String listId) async {
    try {
      final isLiked = await _socialService.isListLiked(listId);
      if (isLiked) {
        await unlikeList(listId);
      } else {
        await likeList(listId);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final likeNotifierProvider = StateNotifierProvider<LikeNotifier, AsyncValue<bool>>((ref) {
  final socialService = ref.read(socialServiceProvider);
  return LikeNotifier(socialService, ref);
});

// COMMENT PROVIDERS

/// Provider to get comments for a list
final listCommentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, listId) async {
  final socialService = ref.read(socialServiceProvider);
  return await socialService.getListComments(listId);
});

/// State notifier for comment actions
class CommentNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final SocialService _socialService;
  final Ref _ref;

  CommentNotifier(this._socialService, this._ref) : super(const AsyncValue.loading());

  /// Add a comment to a list
  Future<void> addComment({
    required String listId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      await _socialService.addComment(
        listId: listId,
        content: content,
        parentCommentId: parentCommentId,
      );
      
      // Invalidate comments provider to refresh
      _ref.invalidate(listCommentsProvider(listId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId, String listId) async {
    try {
      await _socialService.deleteComment(commentId);
      
      // Invalidate comments provider to refresh
      _ref.invalidate(listCommentsProvider(listId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final commentNotifierProvider = StateNotifierProvider<CommentNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final socialService = ref.read(socialServiceProvider);
  return CommentNotifier(socialService, ref);
});

// USER DISCOVERY PROVIDERS

/// Provider to get recommended users
final recommendedUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final socialService = ref.read(socialServiceProvider);
  return await socialService.getRecommendedUsers();
});

/// Provider to search users
final searchUsersProvider = FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final socialService = ref.read(socialServiceProvider);
  return await socialService.searchUsers(query);
});

// ACTIVITY PROVIDERS

/// Provider to get user activity feed
final userActivityFeedProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, userId) async {
  final socialService = ref.read(socialServiceProvider);
  return await socialService.getUserActivityFeed(userId: userId);
});

// SHARING PROVIDERS

/// Provider to get list share stats
final listShareStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, listId) async {
  final socialService = ref.read(socialServiceProvider);
  return await socialService.getListShareStats(listId);
});

/// State notifier for sharing actions
class ShareNotifier extends StateNotifier<AsyncValue<void>> {
  final SocialService _socialService;
  final Ref _ref;

  ShareNotifier(this._socialService, this._ref) : super(const AsyncValue.data(null));

  /// Track a list share
  Future<void> trackShare({
    required String listId,
    required String platform,
  }) async {
    try {
      await _socialService.trackListShare(
        listId: listId,
        platform: platform,
      );
      
      // Invalidate share stats provider to refresh
      _ref.invalidate(listShareStatsProvider(listId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Track a list view
  Future<void> trackView(String listId) async {
    try {
      await _socialService.trackListView(listId);
    } catch (e) {
      // Silently fail for view tracking
    }
  }
}

final shareNotifierProvider = StateNotifierProvider<ShareNotifier, AsyncValue<void>>((ref) {
  final socialService = ref.read(socialServiceProvider);
  return ShareNotifier(socialService, ref);
});