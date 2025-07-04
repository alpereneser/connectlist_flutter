import 'package:dio/dio.dart';

class BookCoverService {
  static const String _openLibraryBaseUrl = 'https://covers.openlibrary.org';
  static const String _openLibrarySearchUrl = 'https://openlibrary.org/search.json';
  
  late final Dio _dio;
  
  BookCoverService() {
    _dio = Dio();
  }
  
  /// Generate a fallback cover URL from Open Library using title
  static String generateCoverFromTitle(String title) {
    // Clean the title for URL usage
    final cleanTitle = title
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '+') // Replace spaces with +
        .toLowerCase();
    
    return '$_openLibraryBaseUrl/b/title/$cleanTitle-L.jpg';
  }
  
  /// Generate a fallback cover URL from Open Library using ISBN
  static String generateCoverFromIsbn(String isbn) {
    return '$_openLibraryBaseUrl/b/isbn/$isbn-L.jpg';
  }
  
  /// Generate a fallback cover URL from Open Library using author and title
  static String generateCoverFromAuthorTitle(String author, String title) {
    final cleanAuthor = author.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '+');
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '+');
    
    return '$_openLibraryBaseUrl/b/title/$cleanAuthor+$cleanTitle-L.jpg';
  }
  
  /// Try to find a better cover image using Open Library search
  Future<String?> searchBetterCover(String title, String? author) async {
    try {
      final queryParts = <String>[title];
      if (author != null && author.isNotEmpty) {
        queryParts.add(author);
      }
      
      final response = await _dio.get(_openLibrarySearchUrl, queryParameters: {
        'title': title,
        'author': author,
        'limit': 5,
        'fields': 'key,title,author_name,cover_i,isbn',
      });
      
      final docs = response.data['docs'] as List?;
      if (docs != null && docs.isNotEmpty) {
        // Find the first book with a cover
        for (final doc in docs) {
          final coverId = doc['cover_i'];
          if (coverId != null) {
            return '$_openLibraryBaseUrl/b/id/$coverId-L.jpg';
          }
          
          // Try with ISBN if available
          final isbns = doc['isbn'] as List?;
          if (isbns != null && isbns.isNotEmpty) {
            return generateCoverFromIsbn(isbns.first.toString());
          }
        }
      }
    } catch (e) {
      print('Error searching for better cover: $e');
    }
    
    return null;
  }
  
  /// Get multiple fallback URLs for a book
  static List<String> getFallbackUrls(String title, String? author, String? isbn) {
    final fallbacks = <String>[];
    
    // Add ISBN-based cover if available
    if (isbn != null && isbn.isNotEmpty) {
      fallbacks.add(generateCoverFromIsbn(isbn));
    }
    
    // Add author+title based cover if author available
    if (author != null && author.isNotEmpty) {
      fallbacks.add(generateCoverFromAuthorTitle(author, title));
    }
    
    // Add title-only based cover
    fallbacks.add(generateCoverFromTitle(title));
    
    // Add a generic book cover as last resort
    fallbacks.add('$_openLibraryBaseUrl/b/title/default-book-cover-L.jpg');
    
    return fallbacks;
  }
  
  /// Check if an image URL is accessible
  Future<bool> isImageAccessible(String url) async {
    try {
      final response = await _dio.head(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Get the best available cover URL for a book
  Future<String> getBestCoverUrl(String title, String? author, String? isbn, String? googleImageUrl) async {
    // First try Google Books image if available
    if (googleImageUrl != null && googleImageUrl.isNotEmpty) {
      final isAccessible = await isImageAccessible(googleImageUrl);
      if (isAccessible) {
        return googleImageUrl;
      }
    }
    
    // Try to find a better cover using Open Library search
    final betterCover = await searchBetterCover(title, author);
    if (betterCover != null) {
      final isAccessible = await isImageAccessible(betterCover);
      if (isAccessible) {
        return betterCover;
      }
    }
    
    // Try fallback URLs one by one
    final fallbacks = getFallbackUrls(title, author, isbn);
    for (final fallbackUrl in fallbacks) {
      final isAccessible = await isImageAccessible(fallbackUrl);
      if (isAccessible) {
        return fallbackUrl;
      }
    }
    
    // Return the title-based URL as final fallback
    return generateCoverFromTitle(title);
  }
}