import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../shared/widgets/sub_header.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../../core/models/content_item.dart';
import '../../../core/providers/list_providers.dart';
import '../../../main.dart';
import '../../profile/pages/profile_page.dart';
import '../../list_creation/pages/content_selection_page.dart';

class ModernListViewPage extends ConsumerStatefulWidget {
  final String listId;
  final int bottomMenuIndex;

  const ModernListViewPage({
    super.key,
    required this.listId,
    this.bottomMenuIndex = 0,
  });

  @override
  ConsumerState<ModernListViewPage> createState() => _ModernListViewPageState();
}

class _ModernListViewPageState extends ConsumerState<ModernListViewPage> {
  bool _isLiked = false;
  bool _isOwner = false;
  String? _listOwnerId;
  
  void _toggleLike() async {
    try {
      final result = await ref.read(toggleListLikeProvider(widget.listId).future);
      setState(() {
        _isLiked = result;
      });
      // Refresh list details to update like count
      ref.invalidate(listDetailsProvider(widget.listId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(PhosphorIcons.x()),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Comments List
              Expanded(
                child: Center(
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
                        'No comments yet',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to comment on this list',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Comment Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          // TODO: Implement comment submission
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  void _shareList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
              'Share List',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: PhosphorIcons.link(),
                  label: 'Copy Link',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                  },
                ),
                _buildShareOption(
                  icon: PhosphorIcons.shareNetwork(),
                  label: 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement native share
                  },
                ),
                _buildShareOption(
                  icon: PhosphorIcons.export(),
                  label: 'Export',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement export functionality
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Navigation functions
  void _navigateToUserProfile(String? userId) {
    if (userId == null) return;
    
    // Check if it's current user's own profile
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == userId) {
      // Navigate to own profile (without userId)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );
    } else {
      // Navigate to other user's profile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(userId: userId),
        ),
      );
    }
  }

  // Owner-only functions
  Future<void> _editList() async {
    final listDetailsAsync = ref.read(listDetailsProvider(widget.listId));
    final listData = listDetailsAsync.value;
    
    if (listData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load list data')),
      );
      return;
    }

    // For now, show a dialog with edit options
    // In the future, this can navigate to a dedicated edit page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit List',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIcons.textT()),
              title: Text('Edit Title & Description'),
              onTap: () {
                Navigator.pop(context);
                _showEditTitleDialog(listData);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.plus()),
              title: Text('Add Items'),
              onTap: () {
                Navigator.pop(context);
                _addItemToList();
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.gear()),
              title: Text('List Settings'),
              onTap: () {
                Navigator.pop(context);
                _showListSettings(listData);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditTitleDialog(Map<String, dynamic> listData) {
    final titleController = TextEditingController(text: listData['title']);
    final descriptionController = TextEditingController(text: listData['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit List Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'List Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final supabase = Supabase.instance.client;
                await supabase
                    .from('lists')
                    .update({
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'updated_at': DateTime.now().toIso8601String(),
                    })
                    .eq('id', widget.listId);

                // Refresh list details
                ref.invalidate(listDetailsProvider(widget.listId));
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('List updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating list: $e')),
                  );
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showListSettings(Map<String, dynamic> listData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'List Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Privacy: ${listData['privacy'] ?? 'public'}'),
            const SizedBox(height: 16),
            Text('Created: ${timeago.format(DateTime.parse(listData['created_at']))}'),
            if (listData['updated_at'] != null)
              Text('Updated: ${timeago.format(DateTime.parse(listData['updated_at']))}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteList() async {
    final listDetailsAsync = ref.read(listDetailsProvider(widget.listId));
    final listData = listDetailsAsync.value;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete List',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${listData?['title'] ?? 'this list'}"? This action cannot be undone.',
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
    final listDetailsAsync = ref.read(listDetailsProvider(widget.listId));
    final listData = listDetailsAsync.value;
    
    if (listData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load list data')),
      );
      return;
    }

    final category = listData['categories'] as Map<String, dynamic>?;
    final categoryName = category?['display_name'] ?? 'Unknown';
    
    // Navigate to content selection page for the same category
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentSelectionPage(
          category: categoryName,
          existingListId: widget.listId, // Pass existing list ID to add items
        ),
      ),
    );
  }

  Future<void> _removeItemFromList(String itemId) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('list_items')
          .delete()
          .eq('id', itemId);

      // Refresh the list
      ref.invalidate(listDetailsProvider(widget.listId));
      
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

  void _showItemOptions(Map<String, dynamic> item) {
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
                item['title'] ?? 'Item',
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
          ],
        ),
      ),
    );
  }

  void _showRemoveItemConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Item',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove "${item['title']}" from this list?',
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
              _removeItemFromList(item['id']);
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

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.grey.shade700,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listDetailsAsync = ref.watch(listDetailsProvider(widget.listId));
    
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar with list title
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.arrowLeft(),
            color: Colors.grey.shade800,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: listDetailsAsync.when(
          data: (listData) => Text(
            listData?['title'] ?? 'List Details',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          loading: () => Text(
            'List Details',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          error: (_, __) => Text(
            'List Details',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Edit button for owners
          if (_isOwner)
            IconButton(
              icon: Icon(
                PhosphorIcons.pencil(),
                color: Colors.grey.shade800,
              ),
              onPressed: () => _editList(),
              tooltip: 'Edit List',
            ),
          IconButton(
            icon: Icon(
              PhosphorIcons.dotsThreeVertical(),
              color: Colors.grey.shade800,
            ),
            onPressed: () => _showOptionsMenu(),
            tooltip: 'More Options',
          ),
        ],
      ),
      body: listDetailsAsync.when(
        data: (listData) {
          if (listData == null) {
            return const Center(child: Text('List not found'));
          }
          
          // Check ownership
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          final listOwnerId = listData['user_id'];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isOwner = currentUserId == listOwnerId;
                _listOwnerId = listOwnerId;
              });
            }
          });
          
          final profile = listData['users_profiles'];
          final category = listData['categories'];
          final listItems = (listData['list_items'] as List?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ?? [];
          
          // Sort list items by position
          listItems.sort((a, b) => (a['position'] ?? 0).compareTo(b['position'] ?? 0));
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. List name and description
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listData['title'] ?? 'Untitled',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (listData['description'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          listData['description'],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 3. User who shared the list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    onTap: () {
                      // Navigate to user profile
                      _navigateToUserProfile(_listOwnerId);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              profile?['avatar_url'] ?? 
                              'https://api.dicebear.com/7.x/avataaars/svg?seed=default',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?['username'] ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              if (profile?['full_name'] != null)
                                Text(
                                  profile['full_name'],
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 4. List category, creation date and update date
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (category?['display_name'] ?? 'Unknown').toString().toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Dates
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created ${timeago.format(
                                DateTime.parse(listData['created_at'] ?? DateTime.now().toIso8601String()),
                              )}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (listData['updated_at'] != null && 
                                listData['updated_at'] != listData['created_at'])
                              Text(
                                'Updated ${timeago.format(
                                  DateTime.parse(listData['updated_at']),
                                )}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 5. List items in 3x3 grid
                if (listItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: listItems.length,
                      itemBuilder: (context, index) {
                        final item = listItems[index];
                        return _buildGridItem(item, index + 1);
                      },
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // 6. Like, comments, share icons at bottom
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Like Button
                      Expanded(
                        child: _buildActionButton(
                          icon: _isLiked 
                              ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                              : PhosphorIcons.heart(),
                          label: '${listData['likes_count'] ?? 0}',
                          color: _isLiked ? Colors.red : Colors.grey.shade600,
                          onTap: _toggleLike,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Comment Button
                      Expanded(
                        child: _buildActionButton(
                          icon: PhosphorIcons.chatCircle(),
                          label: '${listData['comments_count'] ?? 0}',
                          color: Colors.grey.shade600,
                          onTap: _showComments,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Share Button
                      Expanded(
                        child: _buildActionButton(
                          icon: PhosphorIcons.shareNetwork(),
                          label: 'Share',
                          color: Colors.grey.shade600,
                          onTap: _shareList,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom padding for BottomMenu
                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.warning(),
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading list',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.invalidate(listDetailsProvider(widget.listId));
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _isOwner ? FloatingActionButton(
        onPressed: _addItemToList,
        backgroundColor: Colors.orange.shade600,
        child: Icon(
          PhosphorIcons.plus(),
          color: Colors.white,
        ),
      ) : null,
      bottomNavigationBar: BottomMenu(
        currentIndex: widget.bottomMenuIndex,
        onTap: (index) {
          context.navigateToBottomMenuTab(index, widget.bottomMenuIndex);
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
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
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item, int position) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to content details
          },
          onLongPress: _isOwner ? () => _showItemOptions(item) : null,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        color: Colors.grey.shade100,
                      ),
                      child: item['image_url'] != null && 
                          item['image_url'].toString().isNotEmpty &&
                          item['image_url'].toString() != ''
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              item['image_url'].toString().replaceFirst('http://', 'https://'),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Get category-specific icon based on source
                                IconData getItemIcon() {
                                  final source = item['source'];
                                  switch (source) {
                                    case 'google_books':
                                      return PhosphorIcons.book();
                                    case 'tmdb_movie':
                                      return PhosphorIcons.filmStrip();
                                    case 'tmdb_tv':
                                      return PhosphorIcons.television();
                                    case 'rawg':
                                      return PhosphorIcons.gameController();
                                    case 'yandex_places':
                                      return PhosphorIcons.mapPin();
                                    default:
                                      return PhosphorIcons.image();
                                  }
                                }
                                
                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey.shade100,
                                  child: Icon(
                                    getItemIcon(),
                                    color: Colors.grey.shade400,
                                    size: 32,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Icon(
                            item['source'] == 'google_books' 
                                ? PhosphorIcons.book()
                                : PhosphorIcons.image(),
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                    ),
                    
                    // Position Number
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            position.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Item Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'Untitled',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item['description'] != null) ...[
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            item['description'],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}