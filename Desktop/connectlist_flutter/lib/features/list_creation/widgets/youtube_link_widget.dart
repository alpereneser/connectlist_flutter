import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/models/content_item.dart';
import '../models/content_item.dart' as local;

class YouTubeLinkWidget extends ConsumerStatefulWidget {
  final Function(local.ContentItem) onVideoSelected;

  const YouTubeLinkWidget({
    super.key,
    required this.onVideoSelected,
  });

  @override
  ConsumerState<YouTubeLinkWidget> createState() => _YouTubeLinkWidgetState();
}

class _YouTubeLinkWidgetState extends ConsumerState<YouTubeLinkWidget> {
  final _linkController = TextEditingController();
  ContentItem? _currentVideo;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  String? _extractVideoId(String url) {
    // Regex patterns to extract YouTube video ID
    final patterns = [
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      r'youtube\.com\/shorts\/([^"&?\/\s]{11})',
    ];
    
    for (final pattern in patterns) {
      final match = RegExp(pattern).firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  Future<void> _loadVideo() async {
    final url = _linkController.text.trim();
    if (url.isEmpty) return;

    final videoId = _extractVideoId(url);
    if (videoId == null) {
      setState(() {
        _error = 'Invalid YouTube link. Please paste a valid YouTube video link.';
        _currentVideo = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final youtubeService = ref.read(youtubeServiceProvider);
      final videoData = await youtubeService.getVideoDetails(videoId);
      
      if (videoData != null) {
        final snippet = videoData['snippet'] as Map<String, dynamic>?;
        final statistics = videoData['statistics'] as Map<String, dynamic>?;
        
        final video = ContentItem(
          id: videoId,
          title: snippet?['title'] ?? 'Unknown Video',
          subtitle: snippet?['channelTitle'] ?? 'Unknown Channel',
          imageUrl: snippet?['thumbnails']?['medium']?['url'],
          category: 'videos',
          metadata: {
            'description': snippet?['description'] ?? '',
            'publishedAt': snippet?['publishedAt'] ?? '',
            'viewCount': statistics?['viewCount'] ?? '0',
            'likeCount': statistics?['likeCount'] ?? '0',
            'channelTitle': snippet?['channelTitle'] ?? '',
          },
          source: 'youtube',
        );
        
        setState(() {
          _currentVideo = video;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Video not found. Please check the YouTube link.';
          _currentVideo = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        if (e.toString().contains('YouTube API access denied')) {
          _error = 'YouTube API temporarily unavailable. Please try again later.';
        } else if (e.toString().contains('Invalid video link')) {
          _error = 'Invalid YouTube link. Please check the URL and try again.';
        } else {
          _error = 'Failed to get video details. Please check the link and try again.';
        }
        _currentVideo = null;
        _isLoading = false;
      });
    }
  }

  void _selectVideo() {
    if (_currentVideo != null) {
      final localVideo = local.ContentItem(
        id: _currentVideo!.id,
        title: _currentVideo!.title,
        subtitle: _currentVideo!.subtitle,
        imageUrl: _currentVideo!.imageUrl,
        category: 'videos',
        metadata: _currentVideo!.metadata,
        source: _currentVideo!.source,
      );
      
      widget.onVideoSelected(localVideo);
      
      // Clear the form
      setState(() {
        _linkController.clear();
        _currentVideo = null;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.info(),
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add YouTube Video',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paste YouTube video link below. Video details will be loaded automatically.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Link Input
          Text(
            'YouTube Video Link',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _linkController,
                    onSubmitted: (_) => _loadVideo(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                    decoration: InputDecoration(
                      hintText: 'https://www.youtube.com/watch?v=...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: Icon(
                        PhosphorIcons.link(),
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _loadVideo,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              PhosphorIcons.magnifyingGlass(),
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Error Message
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.warning(),
                    color: Colors.red.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Video Preview
          if (_currentVideo != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Video Thumbnail
                      Container(
                        width: 80,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: _currentVideo!.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _currentVideo!.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      PhosphorIcons.videoCamera(),
                                      color: Colors.grey.shade400,
                                      size: 24,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                PhosphorIcons.videoCamera(),
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Video Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentVideo!.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_currentVideo!.subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _currentVideo!.subtitle!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIcons.plus(),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add Video to List',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Supported Formats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supported Link Formats:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  'https://www.youtube.com/watch?v=VIDEO_ID',
                  'https://youtu.be/VIDEO_ID',
                  'https://www.youtube.com/shorts/VIDEO_ID',
                ].map((format) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• $format',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}