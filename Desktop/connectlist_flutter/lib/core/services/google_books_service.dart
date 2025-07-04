import 'package:dio/dio.dart';
import 'package:connectlist/core/config/api_config.dart';
import 'package:connectlist/core/models/content_item.dart';

class GoogleBooksService {
  late final Dio _dio;
  
  GoogleBooksService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.googleBooksBaseUrl,
    ));
  }
  
  Future<List<ContentItem>> searchBooks(String query) async {
    try {
      print('📚 Searching books with query: "$query"');
      
      final response = await _dio.get('/volumes', queryParameters: {
        'key': ApiConfig.googleBooksApiKey,
        'q': query,
        'maxResults': 20,
        'printType': 'books',
        'projection': 'full',
        'orderBy': 'relevance',
      });
      
      print('📱 Google Books API Response Status: ${response.statusCode}');
      final items = response.data['items'] as List? ?? [];
      print('📚 Google Books API Response: Found ${items.length} items');
      
      // Debug: Print first few items to see structure
      if (items.isNotEmpty) {
        for (int i = 0; i < items.length && i < 2; i++) {
          final book = items[i];
          final volumeInfo = book['volumeInfo'] ?? {};
          print('📖 Book ${i + 1}: ${volumeInfo['title']}');
          print('🖼️ Raw image links: ${volumeInfo['imageLinks']}');
          print('📝 Authors: ${volumeInfo['authors']}');
          print('🆔 Book ID: ${book['id']}');
          print('---');
        }
      }
      
      // Filter out items without proper volume info or title
      final validBooks = items.where((book) {
        final volumeInfo = book['volumeInfo'] ?? {};
        final title = volumeInfo['title'];
        return title != null && title.toString().isNotEmpty;
      }).toList();
      
      print('✅ Valid books after filtering: ${validBooks.length}');
      
      final contentItems = validBooks.map((book) => ContentItem.fromGoogleBook(book)).toList();
      
      // Debug: Print final image URLs
      print('🎯 Final book cover URLs:');
      for (int i = 0; i < contentItems.length && i < 5; i++) {
        final item = contentItems[i];
        print('📚 ${i + 1}. "${item.title}" by ${item.subtitle}');
        print('🖼️ Final URL: ${item.imageUrl}');
        print('---');
      }
      
      return contentItems;
    } catch (e) {
      print('❌ Error searching books: $e');
      if (e is DioException) {
        print('📱 HTTP Status: ${e.response?.statusCode}');
        print('📝 Error Data: ${e.response?.data}');
      }
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getBookDetails(String id) async {
    try {
      final response = await _dio.get('/volumes/$id', queryParameters: {
        'key': ApiConfig.googleBooksApiKey,
      });
      return response.data;
    } catch (e) {
      print('Error getting book details: $e');
      return null;
    }
  }
  
  /// Test method to verify a known book with cover image
  Future<void> testKnownBook() async {
    print('🧪 Testing known book: Harry Potter and the Philosopher\'s Stone');
    final results = await searchBooks('Harry Potter Philosopher\'s Stone Rowling');
    
    if (results.isNotEmpty) {
      final book = results.first;
      print('✅ Found book: ${book.title}');
      print('🖼️ Image URL: ${book.imageUrl}');
      print('📚 Metadata: ${book.metadata}');
    } else {
      print('❌ No books found in test');
    }
  }
}