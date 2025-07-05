import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/profile_stats_provider.dart';
import '../providers/user_profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'followers_modal.dart';
import 'following_modal.dart';
import 'liked_lists_modal.dart';

class ProfileStats extends ConsumerWidget {
  final String userId;
  final bool isCurrentUser;

  const ProfileStats({
    super.key,
    required this.userId,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider(userId));
    final userAsync = ref.watch(userProfileProvider(userId));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: statsAsync.when(
        data: (stats) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              'Lists',
              stats['lists']!,
              () {
                // TODO: Navigate to user's lists
              },
            ),
            _buildStatItem(
              context,
              'Followers',
              stats['followers']!,
              () {
                userAsync.when(
                  data: (user) {
                    if (user != null) {
                      _showFollowersModal(context, user.username);
                    }
                  },
                  loading: () {},
                  error: (_, __) {},
                );
              },
            ),
            _buildStatItem(
              context,
              'Following',
              stats['following']!,
              () {
                userAsync.when(
                  data: (user) {
                    if (user != null) {
                      _showFollowingModal(context, user.username);
                    }
                  },
                  loading: () {},
                  error: (_, __) {},
                );
              },
            ),
            _buildStatItem(
              context,
              'Liked',
              stats['liked']!,
              () {
                userAsync.when(
                  data: (user) {
                    if (user != null) {
                      _showLikedListsModal(context, user.username);
                    }
                  },
                  loading: () {},
                  error: (_, __) {},
                );
              },
            ),
          ],
        ),
        loading: () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLoadingStatItem('Lists'),
            _buildLoadingStatItem('Followers'),
            _buildLoadingStatItem('Following'),
            _buildLoadingStatItem('Liked'),
          ],
        ),
        error: (error, stack) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(context, 'Lists', 0, () {}),
            _buildStatItem(context, 'Followers', 0, () {}),
            _buildStatItem(context, 'Following', 0, () {}),
            _buildStatItem(context, 'Liked', 0, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int count,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingStatItem(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showFollowersModal(BuildContext context, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FollowersModal(
        userId: userId,
        userName: userName,
      ),
    );
  }

  void _showFollowingModal(BuildContext context, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FollowingModal(
        userId: userId,
        userName: userName,
      ),
    );
  }

  void _showLikedListsModal(BuildContext context, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LikedListsModal(
        userId: userId,
        userName: userName,
      ),
    );
  }
}