import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchResultItem extends StatelessWidget {
  final dynamic item;
  final String category;
  final bool isHorizontal;

  const SearchResultItem({
    super.key,
    required this.item,
    required this.category,
    required this.isHorizontal,
  });

  @override
  Widget build(BuildContext context) {
    switch (category) {
      case 'users':
        return _buildUserItem();
      case 'lists':
        return _buildListItem();
      case 'movies':
      case 'tv_shows':
        return _buildMovieItem();
      case 'books':
        return _buildBookItem();
      case 'games':
        return _buildGameItem();
      case 'people':
        return _buildPersonItem();
      case 'places':
        return _buildPlaceItem();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserItem() {
    final username = item['username'] ?? 'Unknown';
    final fullName = item['full_name'] ?? '';
    final avatarUrl = item['avatar_url'];
    
    if (isHorizontal) {
      return Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to user profile
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  backgroundColor: Colors.grey.shade200,
                  child: avatarUrl == null
                      ? Icon(PhosphorIcons.user(), color: Colors.grey.shade500)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  username,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fullName.isNotEmpty)
                  Text(
                    fullName,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to user profile
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  backgroundColor: Colors.grey.shade200,
                  child: avatarUrl == null
                      ? Icon(PhosphorIcons.user(), color: Colors.grey.shade500)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (fullName.isNotEmpty)
                        Text(
                          fullName,
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
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem() {
    final title = item['title'] ?? 'Untitled';
    final description = item['description'];
    final username = item['users_profiles']?['username'] ?? 'Unknown';
    final category = item['categories']?['display_name'] ?? 'Unknown';
    
    if (isHorizontal) {
      return Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to list details
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Spacer(),
                  Text(
                    '@$username',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                Row(
                  children: [
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'by @$username',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieItem() {
    final title = item['title'] ?? item['name'] ?? 'Unknown';
    final overview = item['overview'];
    final posterPath = item['poster_path'];
    final releaseDate = item['release_date'] ?? item['first_air_date'];
    
    return _buildMediaItem(
      title: title,
      subtitle: overview,
      imageUrl: posterPath != null ? 'https://image.tmdb.org/t/p/w300$posterPath' : null,
      metadata: releaseDate,
      icon: PhosphorIcons.filmStrip(),
    );
  }

  Widget _buildBookItem() {
    final volumeInfo = item['volumeInfo'] ?? {};
    final title = volumeInfo['title'] ?? 'Unknown';
    final authors = volumeInfo['authors'] as List?;
    final description = volumeInfo['description'];
    final imageLinks = volumeInfo['imageLinks'] as Map?;
    final imageUrl = imageLinks?['thumbnail'];
    
    return _buildMediaItem(
      title: title,
      subtitle: description,
      imageUrl: imageUrl,
      metadata: authors?.isNotEmpty == true ? 'by ${authors!.first}' : null,
      icon: PhosphorIcons.book(),
    );
  }

  Widget _buildGameItem() {
    final title = item['name'] ?? 'Unknown';
    final released = item['released'];
    final backgroundImage = item['background_image'];
    final rating = item['rating'];
    
    return _buildMediaItem(
      title: title,
      subtitle: null,
      imageUrl: backgroundImage,
      metadata: rating != null ? '⭐ $rating' : released,
      icon: PhosphorIcons.gameController(),
    );
  }

  Widget _buildPersonItem() {
    final name = item['name'] ?? 'Unknown';
    final knownFor = item['known_for_department'];
    final profilePath = item['profile_path'];
    
    return _buildMediaItem(
      title: name,
      subtitle: null,
      imageUrl: profilePath != null ? 'https://image.tmdb.org/t/p/w300$profilePath' : null,
      metadata: knownFor,
      icon: PhosphorIcons.user(),
    );
  }

  Widget _buildPlaceItem() {
    final name = item['name'] ?? 'Unknown';
    final vicinity = item['vicinity'];
    final rating = item['rating'];
    final imageUrl = item['place_image'];
    
    return _buildMediaItem(
      title: name,
      subtitle: vicinity,
      imageUrl: imageUrl,
      metadata: rating != null ? '⭐ ${rating.toStringAsFixed(1)}' : null,
      icon: PhosphorIcons.mapPin(),
    );
  }

  Widget _buildMediaItem({
    required String title,
    String? subtitle,
    String? imageUrl,
    String? metadata,
    required IconData icon,
  }) {
    if (isHorizontal) {
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
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(icon, color: Colors.grey.shade400, size: 32);
                              },
                            ),
                          )
                        : Icon(icon, color: Colors.grey.shade400, size: 32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to item details
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(icon, color: Colors.grey.shade400, size: 24);
                            },
                          ),
                        )
                      : Icon(icon, color: Colors.grey.shade400, size: 24),
                ),
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
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (metadata != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          metadata,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  PhosphorIcons.arrowRight(),
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}