import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/social_providers.dart';

class FollowButton extends ConsumerWidget {
  final String userId;
  final bool isCompact;

  const FollowButton({
    super.key,
    required this.userId,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(isFollowingProvider(userId));
    final followNotifier = ref.watch(followNotifierProvider.notifier);

    return isFollowingAsync.when(
      data: (isFollowing) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: MaterialButton(
            onPressed: () => followNotifier.toggleFollow(userId),
            minWidth: isCompact ? 80 : 100,
            height: isCompact ? 28 : 36,
            color: isFollowing ? Colors.grey.shade200 : Colors.orange.shade600,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
              side: isFollowing
                  ? BorderSide(color: Colors.grey.shade300, width: 1)
                  : BorderSide.none,
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: GoogleFonts.inter(
                fontSize: isCompact ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: isFollowing ? Colors.grey.shade700 : Colors.white,
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        width: isCompact ? 80 : 100,
        height: isCompact ? 28 : 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        ),
      ),
      error: (error, stack) => Container(
        width: isCompact ? 80 : 100,
        height: isCompact ? 28 : 36,
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
        ),
        child: Center(
          child: Text(
            'Error',
            style: GoogleFonts.inter(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
        ),
      ),
    );
  }
}