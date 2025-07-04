import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/user_model.dart';

final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase
        .from('users_profiles')
        .select('''
          *,
          followers_count,
          following_count,
          lists_count
        ''')
        .eq('id', userId)
        .single();
    
    return UserModel.fromJson(response);
  } catch (e) {
    print('Error fetching user profile: $e');
    return null;
  }
});