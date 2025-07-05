import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/enhanced_list_card.dart';
import '../../../features/list_details/pages/modern_list_view_page.dart';

class ProfileContent extends ConsumerStatefulWidget {
  final String userId;
  final int categoryIndex;
  final bool isCurrentUser;

  const ProfileContent({
    super.key,
    required this.userId,
    required this.categoryIndex,
    required this.isCurrentUser,
  });

  @override
  ConsumerState<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<ProfileContent> {
  List<Map<String, dynamic>> _userLists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserLists();
  }

  @override
  void didUpdateWidget(ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryIndex != widget.categoryIndex) {
      _loadUserLists();
    }
  }

  Future<void> _loadUserLists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    print('Loading lists for user: ${widget.userId}, isCurrentUser: ${widget.isCurrentUser}, categoryIndex: ${widget.categoryIndex}'); // Debug log

    try {
      final supabase = Supabase.instance.client;
      
      // Build query based on category
      var queryBuilder = supabase
          .from('lists')
          .select('''
            *,
            categories!inner(*),
            users_profiles!creator_id(*)
          ''')
          .eq('creator_id', widget.userId);
      
      // If not current user, only show public lists
      if (!widget.isCurrentUser) {
        queryBuilder = queryBuilder.eq('is_public', true);
      }
      
      // Filter by category if not "All Lists" (index 0)
      if (widget.categoryIndex > 0) {
        final categoryName = _getCategoryNameFromIndex(widget.categoryIndex);
        if (categoryName != null) {
          queryBuilder = queryBuilder.eq('categories.name', categoryName);
        }
      }
      
      final response = await queryBuilder.order('created_at', ascending: false);
      
      print('Lists response: $response'); // Debug log
      print('Response length: ${response.length}'); // Debug log
      
      setState(() {
        _userLists = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user lists: $e'); // Debug log
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String? _getCategoryNameFromIndex(int index) {
    // Map category index to actual category names in the database
    final categoryMapping = {
      1: 'movies',    // Movies
      2: 'books',     // Books
      3: 'tv_shows',  // TV Shows
      4: 'games',     // Games
      5: 'places',    // Places
      6: 'music',     // Music (if exists in DB)
      7: 'people',    // People (if exists in DB)
    };
    return categoryMapping[index];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              'Error loading lists',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadUserLists,
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

    if (_userLists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.listDashes(),
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isCurrentUser ? 'No lists yet' : 'No public lists',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isCurrentUser 
                  ? 'Create your first list to get started'
                  : 'This user hasn\'t shared any lists yet',
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
      padding: const EdgeInsets.only(top: 8),
      itemCount: _userLists.length,
      itemBuilder: (context, index) {
        final list = _userLists[index];
        final profile = list['users_profiles'] as Map<String, dynamic>?;
        final category = list['categories'] as Map<String, dynamic>?;
        
        return EnhancedListCard(
          listId: list['id'],
          listTitle: list['title'] ?? 'Untitled',
          listDescription: list['description'],
          userFullName: profile?['username'] ?? 'Unknown',
          username: profile?['username'] ?? 'Unknown',
          userAvatarUrl: profile?['avatar_url'],
          category: category?['display_name'] ?? 'Unknown',
          createdAt: list['created_at'],
          itemCount: list['items_count'] ?? 0,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModernListViewPage(
                  listId: list['id'],
                  bottomMenuIndex: 4, // Profile tab
                ),
              ),
            );
          },
        );
      },
    );
  }

}