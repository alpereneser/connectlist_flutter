import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/social/widgets/like_button.dart';
import '../../features/social/widgets/share_button.dart';
import '../../features/social/widgets/comments_bottom_sheet.dart';
import '../../features/social/providers/social_providers.dart';
import 'smart_book_cover.dart';

class EnhancedListCard extends ConsumerStatefulWidget {
  final String listId;
  final String listTitle;
  final String? listDescription;
  final String userFullName;
  final String username;
  final String? userAvatarUrl;
  final String category;
  final String createdAt;
  final int itemCount;
  final int? likesCount;
  final int? sharesCount;
  final int? commentsCount;
  final VoidCallback? onTap;

  const EnhancedListCard({
    super.key,
    required this.listId,
    required this.listTitle,
    this.listDescription,
    required this.userFullName,
    required this.username,
    this.userAvatarUrl,
    required this.category,
    required this.createdAt,
    required this.itemCount,
    this.likesCount,
    this.sharesCount,
    this.commentsCount,
    this.onTap,
  });

  @override
  ConsumerState<EnhancedListCard> createState() => _EnhancedListCardState();
}

class _EnhancedListCardState extends ConsumerState<EnhancedListCard> {
  List<Map<String, dynamic>> _listItems = [];
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadListItems();
    _trackView();
  }

  void _trackView() {
    // Track list view for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shareNotifierProvider.notifier).trackView(widget.listId);
    });
  }

  Future<void> _loadListItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('list_items')
          .select('*')
          .eq('list_id', widget.listId)
          .order('position', ascending: true)
          .limit(10); // Load first 10 items for preview
      
      setState(() {
        _listItems = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Handle error silently for card preview
    } finally {
      setState(() => _isLoadingItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final truncatedDescription = widget.listDescription != null && widget.listDescription!.length > 140
        ? '${widget.listDescription!.substring(0, 140)}...'
        : widget.listDescription;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Row (moved to top)
                Row(
                  children: [
                    // User Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        image: widget.userAvatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(widget.userAvatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.userAvatarUrl == null
                          ? Icon(
                              PhosphorIcons.user(),
                              size: 20,
                              color: Colors.grey.shade500,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userFullName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@${widget.username}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Time and Category
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeago.format(DateTime.parse(widget.createdAt), locale: 'en_short'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.category,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // List Title
                Text(
                  widget.listTitle,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (truncatedDescription != null && truncatedDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // List Description
                  Text(
                    truncatedDescription,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // Horizontal scrolling items preview
                if (_listItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _listItems.length,
                      itemBuilder: (context, index) {
                        final item = _listItems[index];
                        return _buildItemPreview(item, index);
                      },
                    ),
                  ),
                ] else if (_isLoadingItems) ...[
                  const SizedBox(height: 16),
                  const SizedBox(
                    height: 240,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // List Stats
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.listBullets(),
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.itemCount} items',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    // Social action buttons
                    LikeButton(
                      listId: widget.listId,
                      likesCount: widget.likesCount,
                    ),
                    const SizedBox(width: 4),
                    _buildCommentButton(),
                    const SizedBox(width: 4),
                    ShareButton(
                      listId: widget.listId,
                      listTitle: widget.listTitle,
                      listDescription: widget.listDescription,
                      sharesCount: widget.sharesCount,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CommentsBottomSheet(
                  listId: widget.listId,
                  listTitle: widget.listTitle,
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                PhosphorIcons.chatCircle(),
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ),
        ),
        if (widget.commentsCount != null && widget.commentsCount! > 0) ...[
          const SizedBox(width: 4),
          Text(
            _formatCount(widget.commentsCount!),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  Widget _buildItemPreview(Map<String, dynamic> item, int index) {
    final imageUrl = item['image_url'];
    final title = item['title'] ?? 'Item ${index + 1}';
    final source = item['source'];
    final description = item['description'];
    
    // Extract additional metadata for books
    String? author;
    String? isbn;
    if (source == 'google_books') {
      final externalData = item['external_data'] as Map<String, dynamic>?;
      if (externalData != null) {
        final enhanced = externalData['enhanced_metadata'] as Map<String, dynamic>?;
        author = enhanced?['primary_author'];
        isbn = enhanced?['isbn'];
      }
      // Fallback to description for author
      author ??= description;
    }
    
    // Get category-specific icon
    IconData getItemIcon() {
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
      width: 160,
      margin: EdgeInsets.only(right: 16, left: index == 0 ? 0 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use SmartBookCover for books, regular Image for others
          source == 'google_books'
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SmartBookCover(
                    imageUrl: imageUrl,
                    bookTitle: title,
                    author: author,
                    isbn: isbn,
                    width: 160,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  height: 200,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                getItemIcon(),
                                size: 24,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            getItemIcon(),
                            size: 24,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}