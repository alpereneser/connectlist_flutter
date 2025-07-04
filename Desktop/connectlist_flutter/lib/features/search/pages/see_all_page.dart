import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../widgets/search_result_item.dart';
import '../../profile/pages/profile_page.dart';
import '../../../main.dart';

class SeeAllPage extends ConsumerWidget {
  final String title;
  final FutureProvider<List<dynamic>> provider;
  final String itemType;

  const SeeAllPage({
    super.key,
    required this.title,
    required this.provider,
    required this.itemType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(provider);
    
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
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              PhosphorIcons.chatCircle(),
              color: Colors.grey.shade600,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: dataAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.listBullets(),
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items found',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(itemType),
              childAspectRatio: _getAspectRatio(itemType),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildGridItem(item);
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
                'Error loading items',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(provider);
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
      ),
      bottomNavigationBar: BottomMenu(
        currentIndex: 1, // Search tab
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pop();
          } else if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          } else if (index == 2) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          } else if (index == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildGridItem(dynamic item) {
    String category;
    switch (itemType) {
      case 'movie':
        category = 'movies';
        break;
      case 'tv_show':
        category = 'tv_shows';
        break;
      case 'book':
        category = 'books';
        break;
      case 'game':
        category = 'games';
        break;
      case 'person':
        category = 'people';
        break;
      case 'place':
        category = 'places';
        break;
      case 'list':
        category = 'lists';
        break;
      default:
        category = 'movies';
    }
    
    return SearchResultItem(
      item: item,
      category: category,
      isHorizontal: false,
    );
  }

  int _getCrossAxisCount(String type) {
    switch (type) {
      case 'movie':
      case 'tv_show':
      case 'book':
      case 'game':
        return 3;
      case 'person':
        return 4;
      case 'place':
      case 'list':
        return 1;
      default:
        return 2;
    }
  }

  double _getAspectRatio(String type) {
    switch (type) {
      case 'movie':
      case 'tv_show':
      case 'book':
        return 0.65;
      case 'game':
        return 0.8;
      case 'person':
        return 0.8;
      case 'place':
        return 4.0;
      case 'list':
        return 3.0;
      default:
        return 1.0;
    }
  }
}