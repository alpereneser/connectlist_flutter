import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class MessageService {
  final SupabaseClient _supabase;
  final Ref _ref;

  MessageService(this._supabase, this._ref);

  // Get conversations for current user
  Future<List<ConversationModel>> getConversations() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            conversation_participants!inner(
              user_id,
              last_read_at,
              users_profiles!conversation_participants_user_id_fkey(
                id,
                username,
                full_name,
                avatar_url
              )
            ),
            messages(
              id,
              content,
              created_at,
              sender_id,
              users_profiles!messages_sender_id_fkey(
                id,
                username,
                full_name,
                avatar_url
              )
            )
          ''')
          .eq('conversation_participants.user_id', currentUser.id)
          .order('last_message_at', ascending: false);

      return response.map((json) {
        // Process participants
        final participants = (json['conversation_participants'] as List)
            .map((p) => UserModel.fromJson(p['users_profiles']))
            .toList();

        // Get last message
        final messages = json['messages'] as List?;
        MessageModel? lastMessage;
        if (messages != null && messages.isNotEmpty) {
          final lastMsg = messages.reduce((a, b) => 
              DateTime.parse(a['created_at']).isAfter(DateTime.parse(b['created_at'])) ? a : b);
          lastMessage = MessageModel.fromJson({
            ...lastMsg,
            'sender': lastMsg['users_profiles'],
          });
        }

        return ConversationModel(
          id: json['id'],
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
          lastMessageAt: DateTime.parse(json['last_message_at']),
          participants: participants,
          lastMessage: lastMessage,
          unreadCount: 0, // Calculate based on last_read_at
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  // Get messages for a conversation
  Future<List<MessageModel>> getMessages(String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('messages')
          .select('''
            *,
            sender:users_profiles!messages_sender_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('conversation_id', conversationId);

      if (before != null) {
        queryBuilder = queryBuilder.lt('created_at', before);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);
      
      return response
          .map((json) => MessageModel.fromJson(json))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Send a message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now().toIso8601String();

      // Insert message
      final messageResponse = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': currentUser.id,
            'content': content,
            'message_type': messageType,
            'created_at': now,
            'updated_at': now,
          })
          .select('''
            *,
            sender:users_profiles!messages_sender_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .single();

      // Update conversation last_message_at
      await _supabase
          .from('conversations')
          .update({
            'last_message_at': now,
            'updated_at': now,
          })
          .eq('id', conversationId);

      return MessageModel.fromJson(messageResponse);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Create or get conversation between users
  Future<ConversationModel> createOrGetConversation(String otherUserId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if conversation already exists
      final existingConversation = await _supabase
          .from('conversations')
          .select('''
            *,
            conversation_participants!inner(
              user_id,
              users_profiles!conversation_participants_user_id_fkey(
                id,
                username,
                full_name,
                avatar_url
              )
            )
          ''')
          .eq('conversation_participants.user_id', currentUser.id)
          .limit(1);

      // Filter conversations that include the other user
      for (final conv in existingConversation) {
        final participantUserIds = (conv['conversation_participants'] as List)
            .map((p) => p['user_id'] as String)
            .toList();
        
        if (participantUserIds.contains(otherUserId) && participantUserIds.length == 2) {
          // Found existing conversation
          final participants = (conv['conversation_participants'] as List)
              .map((p) => UserModel.fromJson(p['users_profiles']))
              .toList();

          return ConversationModel(
            id: conv['id'],
            createdAt: DateTime.parse(conv['created_at']),
            updatedAt: DateTime.parse(conv['updated_at']),
            lastMessageAt: DateTime.parse(conv['last_message_at']),
            participants: participants,
          );
        }
      }

      // Create new conversation
      final now = DateTime.now().toIso8601String();
      
      final conversationResponse = await _supabase
          .from('conversations')
          .insert({
            'created_at': now,
            'updated_at': now,
            'last_message_at': now,
          })
          .select()
          .single();

      final conversationId = conversationResponse['id'];

      // Add participants
      await _supabase.from('conversation_participants').insert([
        {
          'conversation_id': conversationId,
          'user_id': currentUser.id,
          'joined_at': now,
          'last_read_at': now,
        },
        {
          'conversation_id': conversationId,
          'user_id': otherUserId,
          'joined_at': now,
          'last_read_at': now,
        },
      ]);

      // Get participant profiles
      final participantsResponse = await _supabase
          .from('users_profiles')
          .select('*')
          .or('id.eq.${currentUser.id},id.eq.$otherUserId');

      final participants = participantsResponse
          .map((json) => UserModel.fromJson(json))
          .toList();

      return ConversationModel(
        id: conversationId,
        createdAt: DateTime.parse(conversationResponse['created_at']),
        updatedAt: DateTime.parse(conversationResponse['updated_at']),
        lastMessageAt: DateTime.parse(conversationResponse['last_message_at']),
        participants: participants,
      );
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Search users for messaging
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('users_profiles')
          .select('*')
          .neq('id', currentUser.id) // Exclude current user
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);

      return response.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Get suggested users (users not in conversations yet)
  Future<List<UserModel>> getSuggestedUsers() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // For now, just get recent users excluding current user
      final response = await _supabase
          .from('users_profiles')
          .select('*')
          .neq('id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(10);

      return response.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get suggested users: $e');
    }
  }

  // Real-time subscription for messages
  Stream<MessageModel> subscribeToMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data.last)
        .map((json) => MessageModel.fromJson(json));
  }

  // Real-time subscription for conversations
  Stream<List<ConversationModel>> subscribeToConversations() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .asyncMap((data) async {
          // Filter conversations where current user is participant
          final filteredConversations = <Map<String, dynamic>>[];
          
          for (final conv in data) {
            final participants = await _supabase
                .from('conversation_participants')
                .select('user_id')
                .eq('conversation_id', conv['id'])
                .eq('user_id', currentUser.id);
            
            if (participants.isNotEmpty) {
              filteredConversations.add(conv);
            }
          }

          return filteredConversations.map((json) => ConversationModel.fromJson(json)).toList();
        });
  }

  // Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase
          .from('conversation_participants')
          .update({
            'last_read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', currentUser.id);
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }
}

// Provider for message service
final messageServiceProvider = Provider<MessageService>((ref) {
  final supabase = ref.read(supabaseProvider);
  return MessageService(supabase, ref);
});