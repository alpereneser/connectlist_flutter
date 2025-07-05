import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileCategories extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final bool isCurrentUser;

  const ProfileCategories({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final categories = _getCategories();

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          final category = categories[index];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTabSelected(index),
                splashColor: Colors.orange.shade100,
                highlightColor: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: isSelected ? Border(
                      bottom: BorderSide(
                        color: Colors.orange.shade600,
                        width: 2,
                      ),
                    ) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'],
                        size: 18,
                        color: isSelected ? Colors.orange.shade600 : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category['name'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.orange.shade600 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getCategories() {
    return [
      {'name': 'All Lists', 'icon': PhosphorIcons.list()},
      {'name': 'Movies', 'icon': PhosphorIcons.filmStrip()},
      {'name': 'Books', 'icon': PhosphorIcons.book()},
      {'name': 'TV Shows', 'icon': PhosphorIcons.television()},
      {'name': 'Games', 'icon': PhosphorIcons.gameController()},
      {'name': 'Places', 'icon': PhosphorIcons.mapPin()},
      {'name': 'Music', 'icon': PhosphorIcons.musicNote()},
      {'name': 'People', 'icon': PhosphorIcons.user()},
    ];
  }
}