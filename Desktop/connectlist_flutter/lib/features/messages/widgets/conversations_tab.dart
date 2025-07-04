import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/message_model.dart';
import '../pages/chat_page.dart';
import '../providers/message_providers.dart';
import '../../auth/providers/auth_provider.dart';

class ConversationsTab extends ConsumerStatefulWidget {
  const ConversationsTab({super.key});

  @override
  ConsumerState<ConversationsTab> createState() => _ConversationsTabState();
}

class _ConversationsTabState extends ConsumerState<ConversationsTab> {
  @override
  void initState() {
    super.initState();
    // Initialize real-time listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationListenerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(conversationsProvider);
    final currentUser = ref.watch(supabaseProvider).auth.currentUser;

    return RefreshIndicator(
      onRefresh: () => ref.read(conversationsProvider.notifier).refreshConversations(),
      child: conversationsState.isLoading && conversationsState.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : conversationsState.error != null && conversationsState.conversations.isEmpty
              ? _buildErrorState(conversationsState.error!)
              : conversationsState.conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: conversationsState.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversationsState.conversations[index];
                        return _buildConversationItem(conversation, currentUser?.id);
                      },
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.chatCircle(),
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with someone',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to people tab or new message
            },
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('New Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.wifiSlash(),
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading conversations',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(conversationsProvider.notifier).refreshConversations();
            },
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                color: Colors.orange.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(ConversationModel conversation, String? currentUserId) {
    final otherUser = conversation.getOtherParticipant(currentUserId ?? '');
    if (otherUser == null) return const SizedBox.shrink();

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: otherUser.avatarUrl != null
            ? NetworkImage(otherUser.avatarUrl!)
            : null,
        child: otherUser.avatarUrl == null
            ? Text(
                otherUser.username[0].toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade600,
                ),
              )
            : null,
      ),
      title: Text(
        otherUser.fullName ?? otherUser.username,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: conversation.lastMessage != null
          ? Text(
              conversation.lastMessage!.content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              'Start a conversation',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conversation.timeAgo,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  conversation.unreadCount > 99 ? '99+' : conversation.unreadCount.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: conversation.id,
              recipientName: otherUser.fullName ?? otherUser.username,
              recipientAvatar: otherUser.avatarUrl,
            ),
          ),
        );
      },
    );
  }
}