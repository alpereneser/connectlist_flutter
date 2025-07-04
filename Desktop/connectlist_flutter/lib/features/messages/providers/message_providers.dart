import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../../auth/models/user_model.dart';

// State for conversations
class ConversationsState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  ConversationsState({
    required this.conversations,
    required this.isLoading,
    this.error,
  });

  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// State for messages in a conversation
class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  MessagesState({
    required this.messages,
    required this.isLoading,
    required this.hasMore,
    this.error,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

// Conversations provider
class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final MessageService _messageService;

  ConversationsNotifier(this._messageService) : super(
    ConversationsState(
      conversations: [],
      isLoading: false,
    ),
  ) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final conversations = await _messageService.getConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshConversations() async {
    await loadConversations();
  }

  Future<ConversationModel> createOrGetConversation(String otherUserId) async {
    try {
      final conversation = await _messageService.createOrGetConversation(otherUserId);
      
      // Update local state
      final existingIndex = state.conversations.indexWhere((c) => c.id == conversation.id);
      if (existingIndex >= 0) {
        final updatedConversations = [...state.conversations];
        updatedConversations[existingIndex] = conversation;
        state = state.copyWith(conversations: updatedConversations);
      } else {
        state = state.copyWith(
          conversations: [conversation, ...state.conversations],
        );
      }
      
      return conversation;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void updateConversationLastMessage(String conversationId, MessageModel message) {
    final conversations = [...state.conversations];
    final index = conversations.indexWhere((c) => c.id == conversationId);
    
    if (index >= 0) {
      conversations[index] = conversations[index].copyWith(
        lastMessage: message,
        lastMessageAt: message.createdAt,
      );
      
      // Move to top
      final updatedConversation = conversations.removeAt(index);
      conversations.insert(0, updatedConversation);
      
      state = state.copyWith(conversations: conversations);
    }
  }
}

// Messages provider for a specific conversation
class MessagesNotifier extends StateNotifier<MessagesState> {
  final MessageService _messageService;
  final String conversationId;

  MessagesNotifier(this._messageService, this.conversationId) : super(
    MessagesState(
      messages: [],
      isLoading: false,
      hasMore: true,
    ),
  ) {
    loadMessages();
  }

  Future<void> loadMessages({bool loadMore = false}) async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final before = loadMore && state.messages.isNotEmpty 
          ? state.messages.first.createdAt.toIso8601String()
          : null;
          
      final messages = await _messageService.getMessages(
        conversationId,
        before: before,
      );
      
      if (loadMore) {
        state = state.copyWith(
          messages: [...messages, ...state.messages],
          isLoading: false,
          hasMore: messages.length >= 50,
        );
      } else {
        state = state.copyWith(
          messages: messages,
          isLoading: false,
          hasMore: messages.length >= 50,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage(String content) async {
    try {
      final message = await _messageService.sendMessage(
        conversationId: conversationId,
        content: content,
      );
      
      // Add message to local state
      state = state.copyWith(
        messages: [...state.messages, message],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void addMessage(MessageModel message) {
    // Add new message from real-time subscription
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  Future<void> markAsRead() async {
    try {
      await _messageService.markConversationAsRead(conversationId);
    } catch (e) {
      // Silently fail for read receipts
    }
  }
}

// Search users state
class SearchUsersState {
  final List<UserModel> users;
  final List<UserModel> suggestedUsers;
  final bool isLoading;
  final bool isSuggestedLoading;
  final String? error;

  SearchUsersState({
    required this.users,
    required this.suggestedUsers,
    required this.isLoading,
    required this.isSuggestedLoading,
    this.error,
  });

  SearchUsersState copyWith({
    List<UserModel>? users,
    List<UserModel>? suggestedUsers,
    bool? isLoading,
    bool? isSuggestedLoading,
    String? error,
  }) {
    return SearchUsersState(
      users: users ?? this.users,
      suggestedUsers: suggestedUsers ?? this.suggestedUsers,
      isLoading: isLoading ?? this.isLoading,
      isSuggestedLoading: isSuggestedLoading ?? this.isSuggestedLoading,
      error: error ?? this.error,
    );
  }
}

// Search users provider
class SearchUsersNotifier extends StateNotifier<SearchUsersState> {
  final MessageService _messageService;

  SearchUsersNotifier(this._messageService) : super(
    SearchUsersState(
      users: [],
      suggestedUsers: [],
      isLoading: false,
      isSuggestedLoading: false,
    ),
  ) {
    loadSuggestedUsers();
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(users: []);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final users = await _messageService.searchUsers(query);
      state = state.copyWith(
        users: users,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadSuggestedUsers() async {
    state = state.copyWith(isSuggestedLoading: true);
    
    try {
      final users = await _messageService.getSuggestedUsers();
      state = state.copyWith(
        suggestedUsers: users,
        isSuggestedLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSuggestedLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Main providers
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  final messageService = ref.read(messageServiceProvider);
  return ConversationsNotifier(messageService);
});

// Provider for specific conversation messages
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, MessagesState, String>((ref, conversationId) {
  final messageService = ref.read(messageServiceProvider);
  return MessagesNotifier(messageService, conversationId);
});

// Search users provider
final searchUsersProvider = StateNotifierProvider<SearchUsersNotifier, SearchUsersState>((ref) {
  final messageService = ref.read(messageServiceProvider);
  return SearchUsersNotifier(messageService);
});

// Real-time providers
final messageStreamProvider = StreamProvider.family<MessageModel, String>((ref, conversationId) {
  final messageService = ref.read(messageServiceProvider);
  return messageService.subscribeToMessages(conversationId);
});

final conversationsStreamProvider = StreamProvider<List<ConversationModel>>((ref) {
  final messageService = ref.read(messageServiceProvider);
  return messageService.subscribeToConversations();
});

// Listen to real-time message updates
final messageListenerProvider = Provider.family<void, String>((ref, conversationId) {
  final messageStream = ref.watch(messageStreamProvider(conversationId));
  final messagesNotifier = ref.read(messagesProvider(conversationId).notifier);
  final conversationsNotifier = ref.read(conversationsProvider.notifier);
  
  messageStream.whenData((message) {
    messagesNotifier.addMessage(message);
    conversationsNotifier.updateConversationLastMessage(conversationId, message);
  });
  
  return null;
});

// Listen to real-time conversation updates
final conversationListenerProvider = Provider<void>((ref) {
  final conversationsStream = ref.watch(conversationsStreamProvider);
  final conversationsNotifier = ref.read(conversationsProvider.notifier);
  
  conversationsStream.whenData((conversations) {
    // Update conversations from real-time stream
    conversationsNotifier.state = conversationsNotifier.state.copyWith(
      conversations: conversations,
    );
  });
  
  return null;
});