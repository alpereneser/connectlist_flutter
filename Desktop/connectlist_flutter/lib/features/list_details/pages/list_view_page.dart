import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../shared/widgets/sub_header.dart';
import '../../../core/models/content_item.dart';

class ListViewPage extends ConsumerStatefulWidget {
  final String listId;
  final String title;
  final String userName;
  final String userAvatarUrl;
  final String category;
  final String createdAt;
  final int itemCount;
  final int bottomMenuIndex;

  const ListViewPage({
    super.key,
    required this.listId,
    required this.title,
    required this.userName,
    required this.userAvatarUrl,
    required this.category,
    required this.createdAt,
    required this.itemCount,
    this.bottomMenuIndex = 0,
  });

  @override
  ConsumerState<ListViewPage> createState() => _ListViewPageState();
}

class _ListViewPageState extends ConsumerState<ListViewPage> {
  bool _isLiked = false;
  int _likeCount = 0;
  final List<ContentItem> _listItems = [];
  final _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  bool _isSendingComment = false;
  bool _isOwner = false;
  String? _listOwnerId;
  String? _listDescription;

  @override
  void initState() {
    super.initState();
    _loadListDetails();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadListDetails() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      
      // Load list details with owner info
      final listResponse = await supabase
          .from('lists')
          .select('user_id, description')
          .eq('id', widget.listId)
          .single();
      
      // Load list items
      final itemsResponse = await supabase
          .from('list_items')
          .select('*')
          .eq('list_id', widget.listId)
          .order('position', ascending: true);
      
      // Load list likes count
      final likesResponse = await supabase
          .from('list_likes')
          .select('id')
          .eq('list_id', widget.listId);
      
      // Check if current user liked this list
      bool isLiked = false;
      if (currentUserId != null) {
        final userLikeResponse = await supabase
            .from('list_likes')
            .select('id')
            .eq('list_id', widget.listId)
            .eq('user_id', currentUserId)
            .maybeSingle();
        isLiked = userLikeResponse != null;
      }
      
      setState(() {
        _listOwnerId = listResponse['user_id'];
        _listDescription = listResponse['description'];
        _isOwner = currentUserId == _listOwnerId;
        _likeCount = likesResponse.length;
        _isLiked = isLiked;
        _listItems.clear();
        _listItems.addAll(
          itemsResponse.map((item) => ContentItem(
            id: item['id'],
            title: item['title'] ?? 'Unknown',
            subtitle: item['description'] ?? item['subtitle'],
            imageUrl: item['image_url'],
            category: widget.category,
            metadata: item['external_data'] ?? {},
            source: item['source'] ?? 'manual',
          )).toList(),
        );
      });
    } catch (e) {
      // Fallback to empty state in case of error
      setState(() {
        _likeCount = 0;
        _listItems.clear();
        _isOwner = false;
      });
    }
  }


  void _toggleLike() async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like lists')),
      );
      return;
    }
    
    try {
      if (_isLiked) {
        // Unlike the list
        await supabase
            .from('list_likes')
            .delete()
            .eq('list_id', widget.listId)
            .eq('user_id', currentUserId);
        
        setState(() {
          _isLiked = false;
          _likeCount -= 1;
        });
      } else {
        // Like the list
        await supabase
            .from('list_likes')
            .insert({
              'list_id': widget.listId,
              'user_id': currentUserId,
            });
        
        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comments',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_comments.length}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingComments
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? Center(
                          child: Text(
                            'No comments yet',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final user = comment['user'] as Map<String, dynamic>?;
                            return _buildCommentItem(
                              username: user?['username'] ?? 'Unknown',
                              avatarUrl: user?['avatar_url'],
                              content: comment['content'] ?? '',
                              createdAt: comment['created_at'] ?? '',
                            );
                          },
                        ),
            ),
            const Divider(height: 1),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSendingComment ? null : _submitComment,
                        borderRadius: BorderRadius.circular(24),
                        child: Center(
                          child: _isSendingComment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  PhosphorIcons.paperPlaneTilt(),
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem({
    required String username,
    String? avatarUrl,
    required String content,
    required String createdAt,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl)
                : null,
            backgroundColor: Colors.grey.shade200,
            child: avatarUrl == null
                ? Icon(
                    PhosphorIcons.user(),
                    size: 20,
                    color: Colors.grey.shade600,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(DateTime.parse(createdAt)),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareList() async {
    final listUrl = 'https://connectlist.app/list/${widget.listId}';
    final shareText = '${widget.title} by ${widget.userName}\n\nCheck out this amazing list on ConnectList!\n\n$listUrl';
    
    try {
      await Share.share(
        shareText,
        subject: widget.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('list_comments')
          .select('*, user:users_profiles!user_id(username, avatar_url)')
          .eq('list_id', widget.listId)
          .order('created_at', ascending: false);
      
      setState(() {
        _comments.clear();
        _comments.addAll(List<Map<String, dynamic>>.from(response));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Please login to comment');
      }

      await supabase.from('list_comments').insert({
        'user_id': userId,
        'list_id': widget.listId,
        'content': content,
      });

      _commentController.clear();
      await _loadComments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    } finally {
      setState(() => _isSendingComment = false);
    }
  }

  void _exportList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Export List',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildExportOption(
              icon: PhosphorIcons.fileText(),
              title: 'Export as Text',
              subtitle: 'Simple text format',
              onTap: () => _exportAsText(),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: PhosphorIcons.fileCsv(),
              title: 'Export as CSV',
              subtitle: 'For spreadsheets',
              onTap: () => _exportAsCSV(),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: PhosphorIcons.fileDoc(),
              title: 'Export as Markdown',
              subtitle: 'For documentation',
              onTap: () => _exportAsMarkdown(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required PhosphorIconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: Colors.grey.shade700),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIcons.arrowRight(),
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportAsText() async {
    final buffer = StringBuffer();
    buffer.writeln(widget.title);
    buffer.writeln('By ${widget.userName}');
    buffer.writeln('Created: ${widget.createdAt}');
    buffer.writeln('\n---\n');
    
    for (int i = 0; i < _listItems.length; i++) {
      final item = _listItems[i];
      buffer.writeln('${i + 1}. ${item.title}');
      if (item.subtitle != null) {
        buffer.writeln('   ${item.subtitle}');
      }
    }

    await Share.share(buffer.toString(), subject: widget.title);
  }

  Future<void> _exportAsCSV() async {
    final buffer = StringBuffer();
    buffer.writeln('Position,Title,Details');
    
    for (int i = 0; i < _listItems.length; i++) {
      final item = _listItems[i];
      buffer.writeln('${i + 1},"${item.title}","${item.subtitle ?? ''}"');
    }

    await Share.share(buffer.toString(), subject: '${widget.title}.csv');
  }

  Future<void> _exportAsMarkdown() async {
    final buffer = StringBuffer();
    buffer.writeln('# ${widget.title}');
    buffer.writeln();
    buffer.writeln('**Created by:** ${widget.userName}');
    buffer.writeln('**Date:** ${widget.createdAt}');
    buffer.writeln();
    buffer.writeln('## Items');
    buffer.writeln();
    
    for (int i = 0; i < _listItems.length; i++) {
      final item = _listItems[i];
      buffer.writeln('${i + 1}. **${item.title}**');
      if (item.subtitle != null) {
        buffer.writeln('   - ${item.subtitle}');
      }
    }

    await Share.share(buffer.toString(), subject: '${widget.title}.md');
  }

  // Owner-only functions
  Future<void> _editList() async {
    // Navigate to edit list page
    final result = await Navigator.pushNamed(
      context,
      '/edit-list',
      arguments: {
        'listId': widget.listId,
        'title': widget.title,
        'description': _listDescription,
        'category': widget.category,
      },
    );
    
    if (result == true) {
      // Refresh list if edited
      _loadListDetails();
    }
  }

  Future<void> _deleteList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete List',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final supabase = Supabase.instance.client;
        
        // Delete the list (cascade will handle list_items)
        await supabase
            .from('lists')
            .delete()
            .eq('id', widget.listId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('List deleted successfully')),
          );
          Navigator.pop(context); // Go back to previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting list: $e')),
          );
        }
      }
    }
  }

  Future<void> _addItemToList() async {
    // Navigate to content selection page
    final result = await Navigator.pushNamed(
      context,
      '/content-selection',
      arguments: {
        'category': widget.category,
        'listId': widget.listId,
        'isEditing': true,
      },
    );
    
    if (result == true) {
      // Refresh list if items were added
      _loadListDetails();
    }
  }

  Future<void> _removeItemFromList(String itemId) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('list_items')
          .delete()
          .eq('id', itemId);

      // Refresh the list
      _loadListDetails();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from list')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  Future<void> _editItemNote(ContentItem item) async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Note',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Add a personal note...',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
              style: GoogleFonts.inter(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              'Save',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final supabase = Supabase.instance.client;
        
        await supabase
            .from('list_items')
            .update({'user_note': result})
            .eq('id', item.id);

        // Refresh the list
        _loadListDetails();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating note: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.arrowLeft(),
            color: Colors.grey.shade600,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/connectlist-beta-logo.png',
          height: 17,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              PhosphorIcons.dotsThreeVertical(),
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SubHeader(
            selectedIndex: 0,
            onTabSelected: (index) {},
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // List Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description (if exists)
                        if (_listDescription != null && _listDescription!.isNotEmpty) ...[
                          Text(
                            _listDescription!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // User Info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(widget.userAvatarUrl),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userName,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    timeago.format(DateTime.parse(widget.createdAt)),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        Row(
                          children: [
                            // Like Button
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _toggleLike,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isLiked 
                                              ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                                              : PhosphorIcons.heart(),
                                          color: _isLiked ? Colors.red : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _likeCount.toString(),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Comment Button
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _showComments,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          PhosphorIcons.chatCircle(),
                                          color: Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _comments.length.toString(),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Share Button
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _shareList,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      PhosphorIcons.shareNetwork(),
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // List Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    itemCount: _listItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _listItems[index];
                      return _buildListItem(item, index + 1);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isOwner ? FloatingActionButton(
        onPressed: _addItemToList,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(
          PhosphorIcons.plus(),
          color: Colors.white,
        ),
      ) : null,
      bottomNavigationBar: BottomMenu(
        currentIndex: widget.bottomMenuIndex,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildListItem(ContentItem item, int position) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to content details
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Position Number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      position.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Item Image
                if (item.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl!,
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: Icon(
                            PhosphorIcons.image(),
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                
                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // More Options
                IconButton(
                  icon: Icon(
                    PhosphorIcons.dotsThreeVertical(),
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () {
                    _showItemOptions(item);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Owner-only options
            if (_isOwner) ...[
              ListTile(
                leading: Icon(PhosphorIcons.plus()),
                title: Text(
                  'Add Items',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addItemToList();
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.pencil()),
                title: Text(
                  'Edit List',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editList();
                },
              ),
              const Divider(),
            ],
            
            // Common options
            ListTile(
              leading: Icon(PhosphorIcons.export()),
              title: Text(
                'Export List',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportList();
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.shareNetwork()),
              title: Text(
                'Share List',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareList();
              },
            ),
            
            // Owner delete option or report option
            if (_isOwner) 
              ListTile(
                leading: Icon(
                  PhosphorIcons.trash(),
                  color: Colors.red,
                ),
                title: Text(
                  'Delete List',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteList();
                },
              )
            else
              ListTile(
                leading: Icon(
                  PhosphorIcons.flag(),
                  color: Colors.red,
                ),
                title: Text(
                  'Report List',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report functionality coming soon')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showItemOptions(ContentItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            
            // Owner-only options
            if (_isOwner) ...[
              ListTile(
                leading: Icon(PhosphorIcons.note()),
                title: Text(
                  'Edit Note',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editItemNote(item);
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.trash(),
                  color: Colors.red,
                ),
                title: Text(
                  'Remove from List',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveItemConfirmation(item);
                },
              ),
              const Divider(),
            ],
            
            // Common options
            ListTile(
              leading: Icon(PhosphorIcons.eye()),
              title: Text(
                'View Details',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to content details
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.shareNetwork()),
              title: Text(
                'Share Item',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                Navigator.pop(context);
                await Share.share(
                  '${item.title}${item.subtitle != null ? ' (${item.subtitle})' : ''}\n\nFrom ${widget.title} by ${widget.userName}',
                  subject: item.title,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveItemConfirmation(ContentItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Item',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove "${item.title}" from this list?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeItemFromList(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}