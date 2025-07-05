import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../auth/models/user_model.dart';
import '../../social/widgets/follow_button.dart';
import '../pages/settings_page.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  image: user.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.avatarUrl == null
                    ? Icon(
                        PhosphorIcons.user(),
                        size: 40,
                        color: Colors.grey.shade500,
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name with Edit Icon
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName ?? 'No name',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          IconButton(
                            icon: Icon(
                              PhosphorIcons.pencilSimple(),
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    
                    // Username
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    if (!isCurrentUser) ...[
                      Row(
                        children: [
                          // Follow Button
                          Expanded(
                            child: FollowButton(userId: user.id),
                          ),
                          const SizedBox(width: 12),
                          
                          // Message Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement message functionality
                              },
                              icon: Icon(
                                PhosphorIcons.chatCircle(),
                                size: 18,
                              ),
                              label: Text(
                                'Message',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                foregroundColor: Colors.grey.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // Bio, Website, Location
          if ((user.bio != null && user.bio!.isNotEmpty) ||
              (user.website != null && user.website!.isNotEmpty) ||
              (user.location != null && user.location!.isNotEmpty)) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    Text(
                      user.bio!,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Website
                  if (user.website != null && user.website!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.link(),
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.website!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Location
                  if (user.location != null && user.location!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.mapPin(),
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.location!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}