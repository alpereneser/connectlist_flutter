import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/social_providers.dart';

class ShareButton extends ConsumerWidget {
  final String listId;
  final String listTitle;
  final String? listDescription;
  final bool showCount;
  final int? sharesCount;

  const ShareButton({
    super.key,
    required this.listId,
    required this.listTitle,
    this.listDescription,
    this.showCount = true,
    this.sharesCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareNotifier = ref.watch(shareNotifierProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showShareOptions(context, ref, shareNotifier),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                PhosphorIcons.shareNetwork(),
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ),
        ),
        if (showCount && sharesCount != null) ...[
          const SizedBox(width: 4),
          Text(
            _formatCount(sharesCount!),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  void _showShareOptions(BuildContext context, WidgetRef ref, ShareNotifier shareNotifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share List',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),
              _buildShareOption(
                icon: PhosphorIcons.link(),
                title: 'Copy Link',
                onTap: () {
                  _copyLink(context, shareNotifier);
                },
              ),
              _buildShareOption(
                icon: PhosphorIcons.export(),
                title: 'Share via...',
                onTap: () {
                  _shareViaSystem(context, shareNotifier);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyLink(BuildContext context, ShareNotifier shareNotifier) async {
    // Generate list URL (you can customize this based on your app's URL structure)
    final listUrl = 'https://connectlist.app/list/$listId';
    
    try {
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: listUrl));
      
      shareNotifier.trackShare(listId: listId, platform: 'copy_link');
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Link copied to clipboard',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to copy link',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _shareViaSystem(BuildContext context, ShareNotifier shareNotifier) {
    final shareText = listDescription != null
        ? '$listTitle\n\n$listDescription\n\nCheck out this list on Connectlist!'
        : '$listTitle\n\nCheck out this list on Connectlist!';

    Share.share(
      shareText,
      subject: 'Check out this list: $listTitle',
    );

    shareNotifier.trackShare(listId: listId, platform: 'system_share');
    Navigator.pop(context);
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