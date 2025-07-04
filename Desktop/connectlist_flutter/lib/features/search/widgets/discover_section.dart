import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/search_providers.dart';
import 'discover_category_section.dart';

class DiscoverSection extends ConsumerWidget {
  const DiscoverSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.compass(),
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Discover',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            'Explore trending content from all categories',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Trending Movies
          DiscoverCategorySection(
            title: 'Trending Movies',
            icon: PhosphorIcons.filmStrip(),
            provider: discoverMoviesProvider,
            itemType: 'movie',
          ),
          
          const SizedBox(height: 32),
          
          // Popular Books
          DiscoverCategorySection(
            title: 'Popular Books',
            icon: PhosphorIcons.book(),
            provider: discoverBooksProvider,
            itemType: 'book',
          ),
          
          const SizedBox(height: 32),
          
          // Top Games
          DiscoverCategorySection(
            title: 'Top Games',
            icon: PhosphorIcons.gameController(),
            provider: discoverGamesProvider,
            itemType: 'game',
          ),
          
          const SizedBox(height: 32),
          
          // TV Shows
          DiscoverCategorySection(
            title: 'Popular TV Shows',
            icon: PhosphorIcons.television(),
            provider: discoverTVShowsProvider,
            itemType: 'tv_show',
          ),
          
          const SizedBox(height: 32),
          
          // Popular People
          DiscoverCategorySection(
            title: 'Popular People',
            icon: PhosphorIcons.users(),
            provider: discoverPeopleProvider,
            itemType: 'person',
          ),
          
          const SizedBox(height: 32),
          
          // Trending Places
          DiscoverCategorySection(
            title: 'Trending Places',
            icon: PhosphorIcons.mapPin(),
            provider: discoverPlacesProvider,
            itemType: 'place',
          ),
          
          const SizedBox(height: 32),
          
          // Recent Lists
          DiscoverCategorySection(
            title: 'Recent Lists',
            icon: PhosphorIcons.listBullets(),
            provider: discoverListsProvider,
            itemType: 'list',
          ),
          
          const SizedBox(height: 100), // Bottom padding for navigation bar
        ],
      ),
    );
  }
}