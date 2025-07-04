import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../main.dart';
import '../../features/search/pages/search_page.dart';
import '../../features/notifications/pages/notifications_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/list_creation/pages/content_selection_page.dart';
import '../widgets/category_popup.dart';

class NavigationHelper {
  static void handleBottomMenuTap(
    BuildContext context,
    int index,
    int currentIndex,
  ) {
    switch (index) {
      case 0: // Home
        if (currentIndex != 0) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
        break;
        
      case 1: // Search
        if (currentIndex != 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        }
        break;
        
      case 2: // Add (Category Popup)
        HapticFeedback.mediumImpact();
        _showCategoryPopup(context);
        break;
        
      case 3: // Notifications
        if (currentIndex != 3) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const NotificationsPage()),
          );
        }
        break;
        
      case 4: // Profile
        if (currentIndex != 4) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
        break;
    }
  }

  static void _showCategoryPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CategoryPopupModal(
        onCategorySelected: (category) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentSelectionPage(
                category: category,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Extension to make it easier to use
extension NavigationExtension on BuildContext {
  void navigateToBottomMenuTab(
    int index,
    int currentIndex, {
    VoidCallback? onShowCategoryPopup,
  }) {
    NavigationHelper.handleBottomMenuTap(
      this,
      index,
      currentIndex,
    );
  }
}

class _CategoryPopupModal extends StatelessWidget {
  final Function(String) onCategorySelected;

  const _CategoryPopupModal({
    required this.onCategorySelected,
  });

  List<CategoryItem> get categories => [
    CategoryItem('Places', PhosphorIcons.mapPin(), Colors.green),
    CategoryItem('Movies', PhosphorIcons.filmStrip(), Colors.red),
    CategoryItem('Books', PhosphorIcons.book(), Colors.blue),
    CategoryItem('TV Shows', PhosphorIcons.television(), Colors.purple),
    CategoryItem('Videos', PhosphorIcons.videoCamera(), Colors.orange),
    CategoryItem('Musics', PhosphorIcons.musicNote(), Colors.pink),
    CategoryItem('Games', PhosphorIcons.gameController(), Colors.indigo),
    CategoryItem('People', PhosphorIcons.user(), Colors.teal),
    CategoryItem('Poetry', PhosphorIcons.feather(), Colors.amber),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Text(
            'Choose Category',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(category);
            },
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryItem category) {
    return GestureDetector(
      onTap: () => onCategorySelected(category.name),
      child: Container(
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 28,
              color: category.color,
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: category.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryItem(this.name, this.icon, this.color);
}