class ContentItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String category;
  final Map<String, dynamic> metadata;
  final String source; // 'tmdb', 'rawg', 'google_books', 'yandex_places'
  
  ContentItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.category,
    required this.metadata,
    required this.source,
  });
  
  factory ContentItem.fromTmdbMovie(Map<String, dynamic> movie) {
    return ContentItem(
      id: movie['id'].toString(),
      title: movie['title'] ?? '',
      subtitle: movie['release_date'] != null 
          ? DateTime.tryParse(movie['release_date'])?.year.toString() 
          : null,
      imageUrl: movie['poster_path'] != null 
          ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
          : null,
      category: 'movies',
      metadata: movie,
      source: 'tmdb',
    );
  }
  
  factory ContentItem.fromTmdbTvShow(Map<String, dynamic> tvShow) {
    return ContentItem(
      id: tvShow['id'].toString(),
      title: tvShow['name'] ?? '',
      subtitle: tvShow['first_air_date'] != null 
          ? DateTime.tryParse(tvShow['first_air_date'])?.year.toString() 
          : null,
      imageUrl: tvShow['poster_path'] != null 
          ? 'https://image.tmdb.org/t/p/w500${tvShow['poster_path']}'
          : null,
      category: 'tv_shows',
      metadata: tvShow,
      source: 'tmdb',
    );
  }
  
  factory ContentItem.fromTmdbPerson(Map<String, dynamic> person) {
    return ContentItem(
      id: person['id'].toString(),
      title: person['name'] ?? '',
      subtitle: person['known_for_department'],
      imageUrl: person['profile_path'] != null 
          ? 'https://image.tmdb.org/t/p/w500${person['profile_path']}'
          : null,
      category: 'people',
      metadata: person,
      source: 'tmdb',
    );
  }
  
  factory ContentItem.fromRawgGame(Map<String, dynamic> game) {
    return ContentItem(
      id: game['id'].toString(),
      title: game['name'] ?? '',
      subtitle: game['released'] != null 
          ? DateTime.tryParse(game['released'])?.year.toString() 
          : null,
      imageUrl: game['background_image'],
      category: 'games',
      metadata: game,
      source: 'rawg',
    );
  }
  
  factory ContentItem.fromGoogleBook(Map<String, dynamic> book) {
    final volumeInfo = book['volumeInfo'] ?? {};
    final authors = volumeInfo['authors'] as List<dynamic>?;
    final title = volumeInfo['title'] ?? '';
    final industryIdentifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;
    
    print('🔍 Processing book: $title');
    print('📝 Authors: $authors');
    
    // Extract ISBN
    String? isbn;
    if (industryIdentifiers != null) {
      for (final identifier in industryIdentifiers) {
        if (identifier['type'] == 'ISBN_13' || identifier['type'] == 'ISBN_10') {
          isbn = identifier['identifier'];
          break;
        }
      }
    }
    print('📚 ISBN found: $isbn');
    
    // Try to get the best quality image available from Google Books
    String? imageUrl;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    
    print('🖼️ Raw imageLinks from Google: $imageLinks');
    
    if (imageLinks != null) {
      // Priority order: extraLarge -> large -> medium -> small -> thumbnail
      imageUrl = imageLinks['extraLarge'] ??
                 imageLinks['large'] ?? 
                 imageLinks['medium'] ?? 
                 imageLinks['small'] ?? 
                 imageLinks['thumbnail'];
      
      print('🎯 Selected image URL (before enhancement): $imageUrl');
      
      // Enhance image URL for better quality
      if (imageUrl != null) {
        print('🔧 Enhancing image URL: $imageUrl');
        
        // Ensure HTTPS
        if (imageUrl.startsWith('http://')) {
          imageUrl = imageUrl.replaceFirst('http://', 'https://');
          print('🔒 Converted to HTTPS: $imageUrl');
        }
        
        // Try to get higher resolution by modifying URL parameters
        if (imageUrl.contains('zoom=1')) {
          imageUrl = imageUrl.replaceAll('zoom=1', 'zoom=0');
          print('🔍 Removed zoom restriction: $imageUrl');
        }
        if (imageUrl.contains('&edge=curl')) {
          imageUrl = imageUrl.replaceAll('&edge=curl', '');
          print('📐 Removed edge curl: $imageUrl');
        }
        
        // For Google Books images, use the most compatible format
        if (imageUrl.contains('books.google.com')) {
          // Convert to more web-friendly URL format
          final originalUrl = imageUrl;
          
          // Extract the book ID if possible
          final idMatch = RegExp(r'id=([^&]+)').firstMatch(imageUrl);
          if (idMatch != null) {
            final bookId = idMatch.group(1);
            // Use the most reliable Google Books image URL format
            // This format works better with CORS and is more stable
            imageUrl = 'https://books.google.com/books/publisher/content?id=$bookId&printsec=frontcover&img=1&zoom=5&source=gbs_api';
            print('📚 Enhanced Google Books URL: $imageUrl');
          } else {
            // For URLs without clear ID, try to use the thumbnail format which is more permissive
            if (imageUrl.contains('books.googleusercontent.com')) {
              // These URLs are usually more reliable, just ensure HTTPS
              imageUrl = imageUrl.replaceFirst('http://', 'https://');
              print('🔒 Using googleusercontent URL: $imageUrl');
            } else {
              // Remove problematic parameters that might cause CORS issues
              imageUrl = imageUrl
                  .replaceAll('&edge=curl', '')
                  .replaceAll('zoom=0', 'zoom=1')
                  .replaceAll(RegExp(r'&w=\d+'), '')
                  .replaceAll(RegExp(r'&h=\d+'), '')
                  .replaceAll('source=gbs_api', 'source=gbs_thumbnail_api');
              print('🧹 Cleaned Google Books URL: $imageUrl');
            }
          }
        }
        
        print('✨ Final enhanced image URL: $imageUrl');
      }
    } else {
      print('❌ No imageLinks found in volumeInfo');
    }
    
    // If no Google Books image, create intelligent fallback
    if (imageUrl == null || imageUrl.isEmpty) {
      final author = authors?.isNotEmpty == true ? authors!.first : null;
      imageUrl = _createBookCoverFallback(title, author, isbn);
      print('🔄 Using fallback URL: $imageUrl');
    } else {
      // Even if we have a Google Books image, add fallbacks to metadata for SmartBookCover
      print('✅ Google Books image found, adding fallbacks as backup');
    }
    
    return ContentItem(
      id: book['id'].toString(),
      title: title,
      subtitle: authors?.join(', '),
      imageUrl: imageUrl,
      category: 'books',
      metadata: {
        ...book,
        'enhanced_metadata': {
          'isbn': isbn,
          'primary_author': authors?.isNotEmpty == true ? authors!.first : null,
          'fallback_sources': _getBookCoverFallbacks(title, authors?.isNotEmpty == true ? authors!.first : null, isbn),
        }
      },
      source: 'google_books',
    );
  }
  
  /// Create intelligent fallback cover URL
  static String _createBookCoverFallback(String title, String? author, String? isbn) {
    print('🔄 Creating fallback for: $title, Author: $author, ISBN: $isbn');
    
    // Try different strategies and return the most specific one
    
    // Strategy 1: Use ISBN if available
    if (isbn != null && isbn.isNotEmpty) {
      final cleanIsbn = isbn.replaceAll(RegExp(r'[^\d]'), ''); // Remove any non-digits
      final url = 'https://covers.openlibrary.org/b/isbn/$cleanIsbn-L.jpg';
      print('📚 Using ISBN fallback: $url');
      return url;
    }
    
    // Strategy 2: Use Google Books thumbnail API as fallback
    // This is more reliable than Open Library for newer books
    final encodedTitle = Uri.encodeComponent(title);
    final encodedAuthor = author != null ? Uri.encodeComponent(author) : '';
    
    if (author != null && author.isNotEmpty) {
      // Try a direct Google Books cover API approach
      final searchQuery = '$encodedTitle+inauthor:$encodedAuthor';
      final url = 'https://books.google.com/books/content?id=&printsec=frontcover&img=1&zoom=1&source=gbs_api&q=$searchQuery';
      print('📚 Using Google Books fallback: $url');
      return url;
    }
    
    // Strategy 3: Use Open Library as final fallback
    final cleanTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(' ', '+');
    
    final url = 'https://covers.openlibrary.org/b/title/$cleanTitle-L.jpg';
    print('📖 Using Open Library fallback: $url');
    return url;
  }
  
  /// Get list of fallback cover URLs
  static List<String> _getBookCoverFallbacks(String title, String? author, String? isbn) {
    final fallbacks = <String>[];
    
    if (isbn != null && isbn.isNotEmpty) {
      fallbacks.add('https://covers.openlibrary.org/b/isbn/$isbn-L.jpg');
      fallbacks.add('https://covers.openlibrary.org/b/isbn/$isbn-M.jpg');
    }
    
    if (author != null && author.isNotEmpty) {
      final cleanAuthor = author.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '+').toLowerCase();
      final cleanTitle = title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '+').toLowerCase();
      fallbacks.add('https://covers.openlibrary.org/b/title/$cleanAuthor+$cleanTitle-L.jpg');
      fallbacks.add('https://covers.openlibrary.org/b/title/$cleanTitle-L.jpg');
    } else {
      final cleanTitle = title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '+').toLowerCase();
      fallbacks.add('https://covers.openlibrary.org/b/title/$cleanTitle-L.jpg');
    }
    
    return fallbacks;
  }
  
  factory ContentItem.fromYandexPlace(Map<String, dynamic> place) {
    final properties = place['properties'] ?? {};
    final companyMetaData = properties['CompanyMetaData'] ?? {};
    
    return ContentItem(
      id: properties['id']?.toString() ?? '',
      title: companyMetaData['name'] ?? '',
      subtitle: companyMetaData['address'],
      imageUrl: null, // Yandex Places doesn't provide images in search results
      category: 'places',
      metadata: place,
      source: 'yandex_places',
    );
  }
}