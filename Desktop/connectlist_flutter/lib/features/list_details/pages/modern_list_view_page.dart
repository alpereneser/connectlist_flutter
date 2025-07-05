import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../shared/widgets/sub_header.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../../core/models/content_item.dart' as core;
import '../../../core/providers/list_providers.dart';
import '../../../core/providers/api_providers.dart';
import '../../../main.dart';
import '../../profile/pages/profile_page.dart';
import '../../list_creation/pages/content_selection_page.dart';
import '../../list_creation/models/content_item.dart';

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
      builder: (context) => CommentsBottomSheet(
        listId: widget.listId,
      ),
    );
  }

  void _showOptionsMenu() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId != null && currentUserId == _listOwnerId;
    
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
            if (isOwner) ...[
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
            if (isOwner) 
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

    // Show comprehensive edit page with all options expanded
    _showComprehensiveEditDialog(listData);
  }

  void _showComprehensiveEditDialog(Map<String, dynamic> listData) {
    final titleController = TextEditingController(text: listData['title']);
    final descriptionController = TextEditingController(text: listData['description']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
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
                      'Edit List',
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
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Title & Description Section
                    Text(
                      'List Details',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'List Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(PhosphorIcons.textT()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(PhosphorIcons.article()),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Privacy Settings
                    Text(
                      'Privacy Settings',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(PhosphorIcons.globe(), color: Colors.grey.shade600),
                              const SizedBox(width: 12),
                              Text(
                                'Current Privacy: ${listData['privacy'] ?? 'public'}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Privacy settings will be available in future updates',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Manage Items Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Manage Items',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _addItemToList();
                          },
                          icon: Icon(PhosphorIcons.plus()),
                          label: Text('Add Items'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Items List Preview (manageable)
                    _buildManageItemsSection(listData),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildManageItemsSection(Map<String, dynamic> listData) {
    final items = List<Map<String, dynamic>>.from(listData['list_items'] ?? []);
    
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              PhosphorIcons.listBullets(),
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No items in this list',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Items" to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: items.take(5).map((item) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Item Image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: item['image_url'] != null
                  ? Image.network(
                      item['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        PhosphorIcons.image(),
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Icon(
                      PhosphorIcons.image(),
                      color: Colors.grey.shade400,
                    ),
            ),
            const SizedBox(width: 12),
            
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Untitled',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['description'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Delete Button
            IconButton(
              icon: Icon(
                PhosphorIcons.trash(),
                color: Colors.red.shade600,
                size: 18,
              ),
              onPressed: () {
                Navigator.pop(context);
                _showRemoveItemConfirmation(item);
              },
            ),
          ],
        ),
      )).toList(),
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

  void _showManageItemsDialog() {
    final listDetailsAsync = ref.watch(listDetailsProvider(widget.listId));
    final listData = listDetailsAsync.value;
    
    if (listData == null || listData['list_items'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load list items')),
      );
      return;
    }
    
    final items = List<Map<String, dynamic>>.from(listData['list_items'] ?? []);
    
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
                      'Manage Items',
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
              
              // Items List
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No items in this list',
                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: item['image_url'] != null
                                  ? Image.network(
                                      item['image_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        PhosphorIcons.image(),
                                        color: Colors.grey.shade400,
                                      ),
                                    )
                                  : Icon(
                                      PhosphorIcons.image(),
                                      color: Colors.grey.shade400,
                                    ),
                            ),
                            title: Text(
                              item['title'] ?? 'Untitled',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            ),
                            subtitle: item['description'] != null
                                ? Text(
                                    item['description'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: IconButton(
                              icon: Icon(
                                PhosphorIcons.trash(),
                                color: Colors.red.shade600,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showRemoveItemConfirmation(item);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
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
    
    // Show modal popup instead of navigating to a page
    _showAddItemModal(categoryName);
  }

  void _showAddItemModal(String categoryName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => AddItemModal(
          categoryName: categoryName,
          listId: widget.listId,
          onItemsAdded: () {
            // Refresh list details when items are added
            ref.invalidate(listDetailsProvider(widget.listId));
          },
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
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
          final listOwnerId = listData['creator_id'] ?? listData['user_id']; // Check both fields
          final isOwner = currentUserId != null && currentUserId == listOwnerId;
          _listOwnerId = listOwnerId;
          
          // Debug logs
          print('=== OWNER CHECK ===');
          print('Current User ID: $currentUserId');
          print('List Owner ID: $listOwnerId');
          print('Is Owner: $isOwner');
          print('List Title: ${listData['title']}');
          print('==================');
          
          // Force a visual indicator for debugging
          if (isOwner) {
            print('>>> USER IS THE OWNER - EDIT BUTTONS SHOULD BE VISIBLE <<<');
          } else {
            print('>>> USER IS NOT THE OWNER - NO EDIT BUTTONS <<<');
          }
          
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
                        crossAxisCount: 4,
                        childAspectRatio: 0.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: listItems.length,
                      itemBuilder: (context, index) {
                        final item = listItems[index];
                        return _buildGridItem(item, index + 1, isOwner);
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

  Widget _buildGridItem(Map<String, dynamic> item, int position, bool isOwner) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to content details
          },
          onLongPress: isOwner ? () => _showItemOptions(item) : null,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.shade100,
                      ),
                      child: item['image_url'] != null && 
                          item['image_url'].toString().isNotEmpty &&
                          item['image_url'].toString() != ''
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
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
                  ],
                ),
              ),
              
              // Item Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'Untitled',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item['description'] != null) ...[
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            item['description'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 3,
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

class AddItemModal extends ConsumerStatefulWidget {
  final String categoryName;
  final String listId;
  final VoidCallback onItemsAdded;

  const AddItemModal({
    super.key,
    required this.categoryName,
    required this.listId,
    required this.onItemsAdded,
  });

  @override
  ConsumerState<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends ConsumerState<AddItemModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<ContentItem> _selectedItems = [];
  String _currentQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _currentQuery) {
        setState(() {
          _currentQuery = _searchController.text;
        });
      }
    });
  }

  ContentItem _convertToLocalContentItem(core.ContentItem coreItem) {
    return ContentItem(
      id: coreItem.id,
      title: coreItem.title,
      subtitle: coreItem.subtitle,
      imageUrl: coreItem.imageUrl,
      category: widget.categoryName,
      metadata: coreItem.metadata,
      source: coreItem.source,
    );
  }

  void _toggleItemSelection(ContentItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _addSelectedItems() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one item'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      return;
    }

    try {
      final supabase = ref.read(supabaseClientProvider);
      
      // Get current max position
      final existingItems = await supabase
          .from('list_items')
          .select('position')
          .eq('list_id', widget.listId)
          .order('position', ascending: false)
          .limit(1);
      
      int startPosition = 1;
      if (existingItems.isNotEmpty) {
        startPosition = (existingItems[0]['position'] as int) + 1;
      }
      
      // Add new items
      final listItems = _selectedItems.map((item) => {
        'list_id': widget.listId,
        'external_id': item.id,
        'title': item.title,
        'description': item.subtitle,
        'image_url': item.imageUrl,
        'external_data': item.metadata,
        'source': item.source ?? 'manual',
        'position': startPosition + _selectedItems.indexOf(item),
      }).toList();
      
      await supabase
          .from('list_items')
          .insert(listItems);
      
      if (mounted) {
        widget.onItemsAdded();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedItems.length} items added to list'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding items: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map category display names to API category names
    final categoryMapping = {
      'Places': 'places',
      'Movies': 'movies', 
      'Books': 'books',
      'TV Shows': 'tv_shows',
      'Videos': 'videos',
      'Musics': 'music',
      'Games': 'games',
      'People': 'people',
      'Poetry': 'poetry',
    };
    
    final apiCategoryName = categoryMapping[widget.categoryName] ?? widget.categoryName.toLowerCase();
    
    return Container(
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
                  'Add ${widget.categoryName} Items',
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
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.categoryName.toLowerCase()}...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    PhosphorIcons.magnifyingGlass(),
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),
          
          // Selected Items Preview
          if (_selectedItems.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedItems.length} items selected',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = _selectedItems[index];
                        return Container(
                          width: 50,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: item.imageUrl != null
                              ? Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    PhosphorIcons.image(),
                                    color: Colors.grey.shade400,
                                  ),
                                )
                              : Icon(
                                  PhosphorIcons.image(),
                                  color: Colors.grey.shade400,
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Search Results
          Expanded(
            child: _currentQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.magnifyingGlass(),
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search for ${widget.categoryName.toLowerCase()} to add',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Consumer(
                    builder: (context, ref, child) {
                      final searchResults = ref.watch(contentSearchProvider((
                        query: _currentQuery,
                        category: apiCategoryName,
                      )));
                      
                      return searchResults.when(
                        data: (results) {
                          if (results.isEmpty) {
                            return Center(
                              child: Text(
                                'No results found',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final result = results[index];
                              final localItem = _convertToLocalContentItem(result);
                              final isSelected = _selectedItems.contains(localItem);
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orange.shade50 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.orange.shade300 : Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: result.imageUrl != null
                                        ? Image.network(
                                            result.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                              PhosphorIcons.image(),
                                              color: Colors.grey.shade400,
                                            ),
                                          )
                                        : Icon(
                                            PhosphorIcons.image(),
                                            color: Colors.grey.shade400,
                                          ),
                                  ),
                                  title: Text(
                                    result.title,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: result.subtitle != null
                                      ? Text(
                                          result.subtitle!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: Icon(
                                    isSelected 
                                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                                        : PhosphorIcons.plus(),
                                    color: isSelected ? Colors.orange.shade600 : Colors.grey.shade600,
                                  ),
                                  onTap: () => _toggleItemSelection(localItem),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text(
                            'Error: $error',
                            style: GoogleFonts.inter(color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Add Button
          if (_selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addSelectedItems,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add ${_selectedItems.length} item${_selectedItems.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String listId;

  const CommentsBottomSheet({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await supabase.from('list_comments').insert({
        'list_id': widget.listId,
        'user_id': user.id,
        'content': commentText,
      });

      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        // Refresh the modal by calling setState
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadComments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading comments: ${snapshot.error}',
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    );
                  }
                  
                  final comments = snapshot.data ?? [];
                  
                  if (comments.isEmpty) {
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
                    );
                  }
                  
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final profile = comment['users_profiles'] as Map<String, dynamic>?;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                                image: profile?['avatar_url'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(profile!['avatar_url']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: profile?['avatar_url'] == null
                                  ? Icon(
                                      PhosphorIcons.user(),
                                      size: 20,
                                      color: Colors.grey.shade500,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            
                            // Comment Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        profile?['username'] ?? 'Anonymous',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeago.format(DateTime.parse(comment['created_at'])),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment['content'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Comment Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
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
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                        onPressed: _isSubmitting ? null : _submitComment,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadComments() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase
          .from('list_comments')
          .select('''
            *,
            users_profiles!user_id(username, avatar_url)
          ''')
          .eq('list_id', widget.listId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading comments: $e');
      return [];
    }
  }
}