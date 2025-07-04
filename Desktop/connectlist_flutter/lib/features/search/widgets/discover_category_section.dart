import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../pages/see_all_page.dart';

class DiscoverCategorySection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final FutureProvider<List<dynamic>> provider;
  final String itemType;

  const DiscoverCategorySection({
    super.key,
    required this.title,
    required this.icon,
    required this.provider,
    required this.itemType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(provider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              icon,
              color: Colors.grey.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SeeAllPage(
                      title: title,
                      provider: provider,
                      itemType: itemType,
                    ),
                  ),
                );
              },
              child: Text(
                'See All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Content
        SizedBox(
          height: itemType == 'list' ? 140 : (itemType == 'place' ? 160 : 200),
          child: dataAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No items found',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildDiscoverItem(context, item, itemType);
                },
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                color: Colors.orange.shade600,
                strokeWidth: 2,
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.wifiSlash(),
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverItem(BuildContext context, dynamic item, String type) {
    switch (type) {
      case 'movie':
      case 'tv_show':
      case 'book':
      case 'game':
      case 'person':
      case 'place':
        return _buildMediaItem(context, item, type);
      case 'list':
        return _buildListItem(context, item);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMediaItem(BuildContext context, dynamic item, String type) {
    final title = item['title'] ?? item['name'] ?? 'Unknown';
    final imageUrl = _getImageUrl(item, type);
    
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to item details
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _getIconForType(type),
                                color: Colors.grey.shade400,
                                size: 32,
                              );
                            },
                          ),
                        )
                      : Icon(
                          _getIconForType(type),
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Title
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, dynamic item) {
    final title = item['title'] ?? 'Untitled';
    final username = item['users_profiles']?['username'] ?? 'Unknown';
    final category = item['categories']?['display_name'] ?? 'Unknown';
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
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
            // TODO: Navigate to list details
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const Spacer(),
                
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(
                        PhosphorIcons.user(),
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '@$username',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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

  String? _getImageUrl(dynamic item, String type) {
    switch (type) {
      case 'movie':
      case 'tv_show':
        return item['poster_path'] != null 
            ? 'https://image.tmdb.org/t/p/w300${item['poster_path']}'
            : null;
      case 'person':
        return item['profile_path'] != null 
            ? 'https://image.tmdb.org/t/p/w300${item['profile_path']}'
            : null;
      case 'book':
        return item['volumeInfo']?['imageLinks']?['thumbnail'];
      case 'game':
        return item['background_image'];
      case 'place':
        return item['place_image']; // Use the assigned place image
      default:
        return null;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'movie':
        return PhosphorIcons.filmStrip();
      case 'tv_show':
        return PhosphorIcons.television();
      case 'person':
        return PhosphorIcons.user();
      case 'book':
        return PhosphorIcons.book();
      case 'game':
        return PhosphorIcons.gameController();
      case 'place':
        return PhosphorIcons.mapPin();
      default:
        return PhosphorIcons.image();
    }
  }
}