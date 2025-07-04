import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class SocialService {
  final SupabaseClient _supabase;
  final Ref _ref;

  SocialService(this._supabase, this._ref);

  // FOLLOW/UNFOLLOW SYSTEM
  
  /// Follow a user
  Future<void> followUser(String userId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (currentUser.id == userId) {
        throw Exception('Cannot follow yourself');
      }

      // Check if already following
      final existingFollow = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', currentUser.id)
          .eq('following_id', userId)
          .maybeSingle();

      if (existingFollow != null) {
        throw Exception('Already following this user');
      }

      // Insert follow relationship
      await _supabase.from('user_follows').insert({
        'follower_id': currentUser.id,
        'following_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String userId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('user_follows')
          .delete()
          .eq('follower_id', currentUser.id)
          .eq('following_id', userId);

    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// Check if current user is following a specific user
  Future<bool> isFollowing(String userId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', currentUser.id)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get user's followers
  Future<List<UserModel>> getFollowers(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('user_follows')
          .select('''
            follower_id,
            created_at,
            follower:users_profiles!user_follows_follower_id_fkey(
              id,
              username,
              full_name,
              avatar_url,
              bio,
              followers_count,
              following_count,
              lists_count
            )
          ''')
          .eq('following_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map((json) => UserModel.fromJson(json['follower']))
          .toList();
    } catch (e) {
      throw Exception('Failed to get followers: $e');
    }
  }

  /// Get users that current user is following
  Future<List<UserModel>> getFollowing(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('user_follows')
          .select('''
            following_id,
            created_at,
            following:users_profiles!user_follows_following_id_fkey(
              id,
              username,
              full_name,
              avatar_url,
              bio,
              followers_count,
              following_count,
              lists_count
            )
          ''')
          .eq('follower_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map((json) => UserModel.fromJson(json['following']))
          .toList();
    } catch (e) {
      throw Exception('Failed to get following: $e');
    }
  }

  // LIKE/UNLIKE SYSTEM

  /// Like a list
  Future<void> likeList(String listId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if already liked
      final existingLike = await _supabase
          .from('list_likes')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('list_id', listId)
          .maybeSingle();

      if (existingLike != null) {
        throw Exception('Already liked this list');
      }

      // Insert like
      await _supabase.from('list_likes').insert({
        'user_id': currentUser.id,
        'list_id': listId,
        'created_at': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      throw Exception('Failed to like list: $e');
    }
  }

  /// Unlike a list
  Future<void> unlikeList(String listId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('list_likes')
          .delete()
          .eq('user_id', currentUser.id)
          .eq('list_id', listId);

    } catch (e) {
      throw Exception('Failed to unlike list: $e');
    }
  }

  /// Check if current user has liked a specific list
  Future<bool> isListLiked(String listId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _supabase
          .from('list_likes')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('list_id', listId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get users who liked a list
  Future<List<UserModel>> getListLikers(String listId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('list_likes')
          .select('''
            user_id,
            created_at,
            user:users_profiles!list_likes_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url,
              bio,
              followers_count,
              following_count,
              lists_count
            )
          ''')
          .eq('list_id', listId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map((json) => UserModel.fromJson(json['user']))
          .toList();
    } catch (e) {
      throw Exception('Failed to get list likers: $e');
    }
  }

  // COMMENT SYSTEM

  /// Add a comment to a list
  Future<Map<String, dynamic>> addComment({
    required String listId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('list_comments')
          .insert({
            'list_id': listId,
            'user_id': currentUser.id,
            'content': content,
            'parent_comment_id': parentCommentId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            user:users_profiles!list_comments_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a list
  Future<List<Map<String, dynamic>>> getListComments(String listId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('list_comments')
          .select('''
            *,
            user:users_profiles!list_comments_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('list_id', listId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('list_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', currentUser.id); // Only allow user to delete their own comments

    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // USER DISCOVERY SYSTEM

  /// Get recommended users for current user
  Future<List<UserModel>> getRecommendedUsers({int limit = 10}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get users current user is not following
      final response = await _supabase
          .from('users_profiles')
          .select('*')
          .neq('id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(limit * 2); // Get more to filter out followed users

      final users = response.map((json) => UserModel.fromJson(json)).toList();

      // Filter out users that current user is already following
      final filteredUsers = <UserModel>[];
      for (final user in users) {
        if (filteredUsers.length >= limit) break;
        
        final isFollowed = await isFollowing(user.id);
        if (!isFollowed) {
          filteredUsers.add(user);
        }
      }

      return filteredUsers;
    } catch (e) {
      throw Exception('Failed to get recommended users: $e');
    }
  }

  /// Search users for discovery
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('users_profiles')
          .select('*')
          .neq('id', currentUser.id)
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .order('followers_count', ascending: false)
          .limit(limit);

      return response.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // SOCIAL SHARING SYSTEM

  /// Track when a list is shared
  Future<void> trackListShare({
    required String listId,
    required String platform,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('list_shares').insert({
        'list_id': listId,
        'user_id': currentUser.id,
        'platform': platform,
        'created_at': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      throw Exception('Failed to track share: $e');
    }
  }

  /// Get share statistics for a list
  Future<Map<String, int>> getListShareStats(String listId) async {
    try {
      final response = await _supabase
          .from('list_shares')
          .select('platform')
          .eq('list_id', listId);

      final stats = <String, int>{};
      for (final share in response) {
        final platform = share['platform'] as String;
        stats[platform] = (stats[platform] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get share stats: $e');
    }
  }

  // ACTIVITY TRACKING

  /// Track list view
  Future<void> trackListView(String listId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      
      // Check if user already viewed this list today (if authenticated)
      if (currentUser != null) {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        final existingView = await _supabase
            .from('list_views')
            .select('id')
            .eq('list_id', listId)
            .eq('user_id', currentUser.id)
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String())
            .maybeSingle();
        
        // If already viewed today, don't track again
        if (existingView != null) return;
      }
      
      await _supabase.from('list_views').insert({
        'list_id': listId,
        'user_id': currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      // Silently fail for view tracking
    }
  }

  /// Get user activity feed
  Future<List<Map<String, dynamic>>> getUserActivityFeed({
    String? userId,
    int limit = 20,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      final response = await _supabase
          .from('user_activities')
          .select('''
            *,
            user:users_profiles!user_activities_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      throw Exception('Failed to get activity feed: $e');
    }
  }
}

// Provider for social service
final socialServiceProvider = Provider<SocialService>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SocialService(supabase, ref);
});