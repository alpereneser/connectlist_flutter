import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/search_providers.dart';
import 'search_result_item.dart';

class SearchResults extends ConsumerWidget {
  final String query;
  final String selectedCategory;
  final PageController pageController;
  final Function(int) onPageChanged;

  const SearchResults({
    super.key,
    required this.query,
    required this.selectedCategory,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageView(
      controller: pageController,
      onPageChanged: onPageChanged,
      children: [
        _buildAllResults(ref),
        _buildCategoryResults(ref, 'users'),
        _buildCategoryResults(ref, 'lists'),
        _buildCategoryResults(ref, 'movies'),
        _buildCategoryResults(ref, 'tv_shows'),
        _buildCategoryResults(ref, 'books'),
        _buildCategoryResults(ref, 'games'),
        _buildCategoryResults(ref, 'people'),
        _buildCategoryResults(ref, 'places'),
      ],
    );
  }

  Widget _buildAllResults(WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Users Section
          _buildMiniSection(ref, 'Users', 'users', PhosphorIcons.users()),
          
          const SizedBox(height: 24),
          
          // Lists Section
          _buildMiniSection(ref, 'Lists', 'lists', PhosphorIcons.listBullets()),
          
          const SizedBox(height: 24),
          
          // Movies Section
          _buildMiniSection(ref, 'Movies', 'movies', PhosphorIcons.filmStrip()),
          
          const SizedBox(height: 24),
          
          // Books Section
          _buildMiniSection(ref, 'Books', 'books', PhosphorIcons.book()),
          
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildMiniSection(WidgetRef ref, String title, String category, IconData icon) {
    final searchAsync = ref.watch(searchProvider((query: query, category: category)));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.grey.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          height: category == 'users' || category == 'lists' ? 80 : 120,
          child: searchAsync.when(
            data: (results) {
              if (results.isEmpty) {
                return Center(
                  child: Text(
                    'No results found',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: results.length > 5 ? 5 : results.length,
                itemBuilder: (context, index) {
                  return SearchResultItem(
                    item: results[index],
                    category: category,
                    isHorizontal: true,
                  );
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
              child: Text(
                'Error loading results',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryResults(WidgetRef ref, String category) {
    final searchAsync = ref.watch(searchProvider((query: query, category: category)));
    
    return searchAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
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
                  'No results found for "$query"',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return SearchResultItem(
              item: results[index],
              category: category,
              isHorizontal: false,
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: Colors.orange.shade600,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.wifiSlash(),
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading results',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.invalidate(searchProvider);
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
      ),
    );
  }
}