import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ListCard extends StatelessWidget {
  final String listId;
  final String listTitle;
  final String? listDescription;
  final String userFullName;
  final String username;
  final String? userAvatarUrl;
  final String category;
  final String createdAt;
  final int itemCount;
  final VoidCallback? onTap;

  const ListCard({
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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final truncatedDescription = listDescription != null && listDescription!.length > 140
        ? '${listDescription!.substring(0, 140)}...'
        : listDescription;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                // List Title
                Text(
                  listTitle,
                  style: GoogleFonts.inter(
                    fontSize: 18,
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
                
                const SizedBox(height: 16),
                
                // User Info Row
                Row(
                  children: [
                    // User Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        image: userAvatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(userAvatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: userAvatarUrl == null
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
                            userFullName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@$username',
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
                          timeago.format(DateTime.parse(createdAt), locale: 'en_short'),
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
                            category,
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
                
                const SizedBox(height: 12),
                
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
                      '$itemCount items',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    // Like and Share buttons can be added here
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.heart(),
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () {
                        // TODO: Implement like functionality
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.share(),
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () {
                        // TODO: Implement share functionality
                      },
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
}