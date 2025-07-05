import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Notification Settings Provider
final notificationSettingsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;
  
  if (user == null) return null;
  
  try {
    final response = await supabase
        .from('user_notification_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    
    return response;
  } catch (e) {
    print('Error fetching notification settings: $e');
    return null;
  }
});

// Notification Settings Notifier
final notificationSettingsNotifierProvider = StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return NotificationSettingsNotifier(ref);
});

class NotificationSettingsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Ref _ref;
  
  NotificationSettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final supabase = _ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    
    try {
      final response = await supabase
          .from('user_notification_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      state = AsyncValue.data(response);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    final supabase = _ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    
    if (user == null) return;
    
    try {
      state = const AsyncValue.loading();
      
      await supabase
          .from('user_notification_settings')
          .upsert({
            'user_id': user.id,
            ...settings,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      await _loadSettings();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Privacy Settings Provider
final privacySettingsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;
  
  if (user == null) return null;
  
  try {
    final response = await supabase
        .from('user_privacy_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    
    return response;
  } catch (e) {
    print('Error fetching privacy settings: $e');
    return null;
  }
});

// Privacy Settings Notifier
final privacySettingsNotifierProvider = StateNotifierProvider<PrivacySettingsNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return PrivacySettingsNotifier(ref);
});

class PrivacySettingsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Ref _ref;
  
  PrivacySettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final supabase = _ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    
    try {
      final response = await supabase
          .from('user_privacy_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      state = AsyncValue.data(response);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    final supabase = _ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    
    if (user == null) return;
    
    try {
      state = const AsyncValue.loading();
      
      // Check if settings exist
      final existing = await supabase
          .from('user_privacy_settings')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (existing != null) {
        // Update existing settings
        await supabase
            .from('user_privacy_settings')
            .update({
              ...settings,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
      } else {
        // Insert new settings
        await supabase
            .from('user_privacy_settings')
            .insert({
              'user_id': user.id,
              ...settings,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
      
      await _loadSettings();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Update Profile Provider
final updateProfileProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, profileData) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;
  
  if (user == null) throw Exception('User not authenticated');
  
  try {
    await supabase
        .from('users_profiles')
        .update({
          ...profileData,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
    
    return true;
  } catch (e) {
    print('Error updating profile: $e');
    throw Exception('Failed to update profile: $e');
  }
});

// Update Notification Settings Provider
final updateNotificationSettingsProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, settings) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;
  
  if (user == null) throw Exception('User not authenticated');
  
  try {
    await supabase
        .from('user_notification_settings')
        .upsert({
          'user_id': user.id,
          ...settings,
          'updated_at': DateTime.now().toIso8601String(),
        });
    
    ref.invalidate(notificationSettingsProvider);
    return true;
  } catch (e) {
    print('Error updating notification settings: $e');
    throw Exception('Failed to update notification settings: $e');
  }
});

// Update Privacy Settings Provider
final updatePrivacySettingsProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, settings) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;
  
  if (user == null) throw Exception('User not authenticated');
  
  try {
    await supabase
        .from('user_privacy_settings')
        .upsert({
          'user_id': user.id,
          ...settings,
          'updated_at': DateTime.now().toIso8601String(),
        });
    
    ref.invalidate(privacySettingsProvider);
    return true;
  } catch (e) {
    print('Error updating privacy settings: $e');
    throw Exception('Failed to update privacy settings: $e');
  }
});

// Create Support Ticket Provider
final createSupportTicketProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, ticketData) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;
  
  try {
    await supabase
        .from('support_tickets')
        .insert({
          'user_id': user?.id,
          'email': ticketData['email'],
          'subject': ticketData['subject'],
          'message': ticketData['message'],
          'category': ticketData['category'] ?? 'general',
        });
    
    return true;
  } catch (e) {
    print('Error creating support ticket: $e');
    throw Exception('Failed to create support ticket: $e');
  }
});

// Account Deletion Request Provider
final createAccountDeletionRequestProvider = FutureProvider.family<bool, String>((ref, reason) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;
  
  if (user == null) throw Exception('User not authenticated');
  
  try {
    await supabase
        .from('account_deletion_requests')
        .insert({
          'user_id': user.id,
          'reason': reason,
        });
    
    return true;
  } catch (e) {
    print('Error creating account deletion request: $e');
    throw Exception('Failed to create account deletion request: $e');
  }
});

// Upload Avatar Provider
final uploadAvatarProvider = FutureProvider.family<String, Uint8List>((ref, imageBytes) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;
  
  if (user == null) throw Exception('User not authenticated');
  
  try {
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    print('🔄 Avatar yükleniyor: $fileName');
    print('📦 Dosya boyutu: ${imageBytes.length} bytes');
    
    // Upload to Supabase Storage (avatars bucket)
    final uploadResult = await supabase.storage
        .from('avatars')
        .uploadBinary(
          fileName, 
          imageBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true, // Aynı dosya varsa üzerine yaz
          ),
        );
    
    print('✅ Storage upload tamamlandı: ${uploadResult}');
    
    // Get public URL
    final avatarUrl = supabase.storage
        .from('avatars')
        .getPublicUrl(fileName);
    
    print('🔗 Public URL alındı: $avatarUrl');
    
    // Update user profile with new avatar URL
    await supabase
        .from('users_profiles')
        .update({
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
    
    print('✅ Profil güncellendi');
    
    return avatarUrl;
  } catch (e) {
    print('❌ Avatar yükleme hatası: $e');
    print('📊 Hata tipi: ${e.runtimeType}');
    
    // Detaylı hata mesajları
    if (e.toString().contains('policies')) {
      throw Exception('Storage erişim hatası: RLS policy\'leri kontrol edin');
    } else if (e.toString().contains('bucket')) {
      throw Exception('Storage bucket \'avatars\' bulunamadı');
    } else if (e.toString().contains('size')) {
      throw Exception('Dosya çok büyük (max 5MB)');
    } else {
      throw Exception('Avatar yükleme hatası: $e');
    }
  }
});