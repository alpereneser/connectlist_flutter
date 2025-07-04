import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/social_providers.dart';

class LikeButton extends ConsumerWidget {
  final String listId;
  final bool showCount;
  final int? likesCount;

  const LikeButton({
    super.key,
    required this.listId,
    this.showCount = true,
    this.likesCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLikedAsync = ref.watch(isListLikedProvider(listId));
    final likeNotifier = ref.watch(likeNotifierProvider.notifier);

    return isLikedAsync.when(
      data: (isLiked) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => likeNotifier.toggleLike(listId),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isLiked ? PhosphorIcons.heart(PhosphorIconsStyle.fill) : PhosphorIcons.heart(),
                      key: ValueKey(isLiked),
                      color: isLiked ? Colors.red.shade500 : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            if (showCount && likesCount != null) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(likesCount!),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        );
      },
      loading: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              PhosphorIcons.heart(),
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
          if (showCount && likesCount != null) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(likesCount!),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
      error: (error, stack) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              PhosphorIcons.heart(),
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
          if (showCount && likesCount != null) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(likesCount!),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}