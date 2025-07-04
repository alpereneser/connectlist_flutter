import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState?>((ref) {
  final supabase = ref.read(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) => event);
});

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return CurrentUserNotifier(ref);
});

final authProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return ref.watch(currentUserProvider.notifier);
});

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final Ref ref;
  
  CurrentUserNotifier(this.ref) : super(null) {
    _initUser();
  }

  void _initUser() async {
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      await loadUserProfile(user.id);
    }
  }

  Future<void> loadUserProfile(String userId) async {
    try {
      final supabase = ref.read(supabaseProvider);
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
      
      state = UserModel.fromJson(response);
    } catch (e) {
      state = null;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final supabase = ref.read(supabaseProvider);
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await loadUserProfile(response.user!.id);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      final supabase = ref.read(supabaseProvider);
      
      // Check username availability
      final existingUser = await supabase
          .from('users_profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      
      if (existingUser != null) {
        throw Exception('Username already taken');
      }
      
      // Email uniqueness is handled by Supabase auth automatically
      
      // Sign up user
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName,
        },
      );
      
      if (response.user != null) {
        // Always create profile manually to ensure consistency
        // First check if profile already exists (in case trigger worked)
        final existingProfile = await supabase
            .from('users_profiles')
            .select('id')
            .eq('id', response.user!.id)
            .maybeSingle();
        
        if (existingProfile == null) {
          // Create profile manually
          await supabase.from('users_profiles').insert({
            'id': response.user!.id,
            'username': username,
            'full_name': fullName,
          });
        }
        
        await loadUserProfile(response.user!.id);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) return;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google sign in failed');
      }
      
      final supabase = ref.read(supabaseProvider);
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      if (response.user != null) {
        // Check if profile exists
        final profile = await supabase
            .from('users_profiles')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();
        
        if (profile == null) {
          // Generate unique username for Google user
          String baseUsername = googleUser.email.split('@')[0];
          String finalUsername = baseUsername;
          
          // Check username uniqueness
          int counter = 1;
          while (true) {
            final existingUser = await supabase
                .from('users_profiles')
                .select('id')
                .eq('username', finalUsername)
                .maybeSingle();
            
            if (existingUser == null) break;
            
            finalUsername = '${baseUsername}_$counter';
            counter++;
          }
          
          // Create profile for Google user
          await supabase.from('users_profiles').insert({
            'id': response.user!.id,
            'username': finalUsername,
            'full_name': googleUser.displayName ?? '',
            'avatar_url': googleUser.photoUrl,
          });
        }
        
        await loadUserProfile(response.user!.id);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final supabase = ref.read(supabaseProvider);
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final supabase = ref.read(supabaseProvider);
      await supabase.auth.signOut();
      state = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;
      
      if (user?.email != null) {
        await supabase.auth.resend(
          type: OtpType.signup,
          email: user!.email!,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final supabase = ref.read(supabaseProvider);
      final currentUserId = supabase.auth.currentUser?.id;
      
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      // If username is being updated, check availability
      if (username != null && username != state?.username) {
        final existingUser = await supabase
            .from('users_profiles')
            .select('id')
            .eq('username', username)
            .neq('id', currentUserId)
            .maybeSingle();
        
        if (existingUser != null) {
          throw Exception('Username already taken');
        }
      }
      
      // Update profile data
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      
      await supabase
          .from('users_profiles')
          .update(updateData)
          .eq('id', currentUserId);
      
      // Reload user profile to update state
      await loadUserProfile(currentUserId);
    } catch (e) {
      rethrow;
    }
  }

  // Debug function to check if profile exists
  Future<bool> checkUserProfile(String userId) async {
    try {
      final supabase = ref.read(supabaseProvider);
      final profile = await supabase
          .from('users_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return profile != null;
    } catch (e) {
      return false;
    }
  }
}