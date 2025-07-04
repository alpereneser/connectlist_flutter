import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  
  try {
    // Get user profile with social counts
    final userResponse = await supabase
        .from('users_profiles')
        .select('''
          followers_count,
          following_count,
          lists_count
        ''')
        .eq('id', userId)
        .single();
    
    // Get liked lists count (not stored in profile)
    final likedResponse = await supabase
        .from('list_likes')
        .select('id')
        .eq('user_id', userId);
    
    final likedCount = likedResponse.length;
    
    return {
      'lists': userResponse['lists_count'] ?? 0,
      'followers': userResponse['followers_count'] ?? 0,
      'following': userResponse['following_count'] ?? 0,
      'liked': likedCount,
    };
  } catch (e) {
    print('Error fetching profile stats: $e');
    // Return default values in case of error
    return {
      'lists': 0,
      'followers': 0,
      'following': 0,
      'liked': 0,
    };
  }
});