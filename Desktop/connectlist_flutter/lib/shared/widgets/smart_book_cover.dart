import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SmartBookCover extends StatefulWidget {
  final String? imageUrl;
  final String bookTitle;
  final String? author;
  final String? isbn;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SmartBookCover({
    super.key,
    this.imageUrl,
    required this.bookTitle,
    this.author,
    this.isbn,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<SmartBookCover> createState() => _SmartBookCoverState();
}

class _SmartBookCoverState extends State<SmartBookCover> {
  int _fallbackAttempt = 0;
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
    print('🎯 SmartBookCover initialized for: "${widget.bookTitle}"');
    print('🖼️ Initial image URL: $_currentImageUrl');
    
    // Don't immediately try fallbacks - let Google Books attempt first
    // _tryNextFallback() will be called only if image loading actually fails
  }

  @override
  void didUpdateWidget(SmartBookCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() {
        _currentImageUrl = widget.imageUrl;
        _fallbackAttempt = 0;
        _isLoading = true;
        _hasError = false;
      });
    }
  }

  bool _isProblematicBook(String title) {
    // List of book titles that commonly have issues with Google Books covers
    final problematicBooks = [
      'suç ve ceza',
      'crime and punishment',
      'преступление и наказание',
      'dostoyevski',
      'dostoyevsky'
    ];
    
    final lowerTitle = title.toLowerCase();
    return problematicBooks.any((problem) => lowerTitle.contains(problem));
  }

  List<String> _getFallbackUrls() {
    final fallbacks = <String>[];
    
    print('🔄 Creating fallback URLs for: "${widget.bookTitle}"');
    
    // Add specific fallbacks for known problematic books
    final lowerTitle = widget.bookTitle.toLowerCase();
    if (lowerTitle.contains('suç ve ceza') || lowerTitle.contains('crime and punishment')) {
      // Specific fallbacks for Crime and Punishment
      fallbacks.add('https://covers.openlibrary.org/b/isbn/9780140449136-L.jpg');
      fallbacks.add('https://covers.openlibrary.org/b/isbn/0486415872-L.jpg');
      fallbacks.add('https://covers.openlibrary.org/b/title/crime+and+punishment-L.jpg');
      fallbacks.add('https://covers.openlibrary.org/b/title/dostoyevsky+crime+punishment-L.jpg');
      print('🎯 Added specific fallbacks for Crime and Punishment');
    }
    
    // Add ISBN-based fallbacks
    if (widget.isbn != null && widget.isbn!.isNotEmpty) {
      final cleanIsbn = widget.isbn!.replaceAll(RegExp(r'[^\d]'), ''); // Remove any non-digits
      fallbacks.add('https://covers.openlibrary.org/b/isbn/$cleanIsbn-L.jpg');
      fallbacks.add('https://covers.openlibrary.org/b/isbn/$cleanIsbn-M.jpg');
      print('📚 Added ISBN fallbacks for ISBN: $cleanIsbn');
    }
    
    // Add author+title based fallbacks (multiple variations)
    if (widget.author != null && widget.author!.isNotEmpty) {
      final cleanAuthor = _cleanForUrl(widget.author!);
      final cleanTitle = _cleanForUrl(widget.bookTitle);
      
      // Try different combinations
      fallbacks.add('https://covers.openlibrary.org/b/title/$cleanAuthor+$cleanTitle-L.jpg');
      fallbacks.add('https://covers.openlibrary.org/b/title/$cleanTitle+$cleanAuthor-L.jpg');
      fallbacks.add('https://covers.openlibrary.org/b/title/$cleanTitle-L.jpg');
      
      // Try without author's first name if present
      final authorParts = widget.author!.split(' ');
      if (authorParts.length > 1) {
        final lastName = _cleanForUrl(authorParts.last);
        fallbacks.add('https://covers.openlibrary.org/b/title/$lastName+$cleanTitle-L.jpg');
      }
      
      print('👨‍💼 Added author+title fallbacks for: "$cleanAuthor" + "$cleanTitle"');
    } else {
      // Add title-only fallbacks
      final cleanTitle = _cleanForUrl(widget.bookTitle);
      fallbacks.add('https://covers.openlibrary.org/b/title/$cleanTitle-L.jpg');
      fallbacks.add('https://covers.openlibrary.org/b/title/$cleanTitle-M.jpg');
      print('📖 Added title-only fallbacks for: "$cleanTitle"');
    }
    
    print('🎯 Total fallback URLs: ${fallbacks.length}');
    for (int i = 0; i < fallbacks.length; i++) {
      print('${i + 1}. ${fallbacks[i]}');
    }
    
    return fallbacks;
  }
  
  String _cleanForUrl(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single
        .trim()
        .replaceAll(' ', '+'); // Replace spaces with +
  }

  void _tryNextFallback() {
    // Only try fallbacks if the initial URL was NOT from Google Books
    // Give Google Books URLs more of a chance to load
    if (_currentImageUrl != null && _currentImageUrl!.contains('books.google.com') && _fallbackAttempt == 0) {
      print('🔄 Giving Google Books URL another chance: $_currentImageUrl');
      setState(() {
        _fallbackAttempt++;
        _isLoading = true;
        _hasError = false;
      });
      return;
    }
    
    final fallbacks = _getFallbackUrls();
    
    // Limit fallback attempts to prevent infinite loops
    if (_fallbackAttempt < fallbacks.length && _fallbackAttempt < 3) {
      setState(() {
        _currentImageUrl = fallbacks[_fallbackAttempt - 1]; // Subtract 1 because we increment above
        _fallbackAttempt++;
        _isLoading = true;
        _hasError = false;
      });
    } else {
      print('❌ All fallback attempts exhausted for: ${widget.bookTitle}');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _onImageError() {
    if (mounted) {
      print('❌ Image failed to load: $_currentImageUrl');
      print('🔄 Trying next fallback (attempt ${_fallbackAttempt + 1})');
      _tryNextFallback();
    }
  }

  void _onImageLoaded() {
    if (mounted) {
      print('✅ Image loaded successfully: $_currentImageUrl');
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.book(),
            size: (widget.height ?? 120) * 0.3,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.bookTitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.author != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.author!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentImageUrl == null || _currentImageUrl!.isEmpty || _hasError) {
      return _buildPlaceholder();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Image with enhanced error handling
          Image.network(
            _currentImageUrl!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            headers: _currentImageUrl!.contains('books.google.com') || _currentImageUrl!.contains('googleusercontent.com')
                ? {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept': 'image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
                    'Referer': 'https://books.google.com/',
                    'Accept-Language': 'en-US,en;q=0.9',
                    'Cache-Control': 'no-cache',
                    'Pragma': 'no-cache',
                  }
                : {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept': 'image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
                  },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                // Image loaded successfully
                WidgetsBinding.instance.addPostFrameCallback((_) => _onImageLoaded());
                return child;
              }
              
              // Show loading indicator
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Try next fallback
              print('❌ Image.network failed: $error');
              WidgetsBinding.instance.addPostFrameCallback((_) => _onImageError());
              return _buildPlaceholder();
            },
          ),
        ],
      ),
    );
  }
}