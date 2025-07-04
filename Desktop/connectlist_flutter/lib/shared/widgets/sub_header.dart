import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SubHeader extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const SubHeader({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<SubHeader> createState() => _SubHeaderState();
}

class _SubHeaderState extends State<SubHeader> {
  final List<CategoryTab> categories = [
    CategoryTab('All Lists', PhosphorIcons.list()),
    CategoryTab('Place Lists', PhosphorIcons.mapPin()),
    CategoryTab('Movie Lists', PhosphorIcons.filmStrip()),
    CategoryTab('Book Lists', PhosphorIcons.book()),
    CategoryTab('TV Show Lists', PhosphorIcons.television()),
    CategoryTab('Video Lists', PhosphorIcons.videoCamera()),
    CategoryTab('Music Lists', PhosphorIcons.musicNote()),
    CategoryTab('Game Lists', PhosphorIcons.gameController()),
    CategoryTab('Person Lists', PhosphorIcons.user()),
    CategoryTab('Poem Lists', PhosphorIcons.feather()),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = widget.selectedIndex == index;
          final category = categories[index];
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onTabSelected(index),
                splashColor: Colors.orange.shade100,
                highlightColor: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange.shade600 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          category.icon,
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.orange.shade700 : Colors.grey.shade600,
                          letterSpacing: -0.2,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
}

class CategoryTab {
  final String name;
  final IconData icon;

  CategoryTab(this.name, this.icon);
}