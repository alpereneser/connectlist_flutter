import 'package:dio/dio.dart';
import 'package:connectlist/core/config/api_config.dart';
import 'package:connectlist/core/models/content_item.dart';

class RawgService {
  late final Dio _dio;
  
  RawgService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.rawgBaseUrl,
    ));
  }
  
  Future<List<ContentItem>> searchGames(String query) async {
    try {
      final response = await _dio.get('/games', queryParameters: {
        'key': ApiConfig.rawgApiKey,
        'search': query,
        'page_size': 20,
      });
      
      final results = response.data['results'] as List;
      return results.map((game) => ContentItem.fromRawgGame(game)).toList();
    } catch (e) {
      print('Error searching games: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getGameDetails(String id) async {
    try {
      final response = await _dio.get('/games/$id', queryParameters: {
        'key': ApiConfig.rawgApiKey,
      });
      return response.data;
    } catch (e) {
      print('Error getting game details: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getGameScreenshots(String id) async {
    try {
      final response = await _dio.get('/games/$id/screenshots', queryParameters: {
        'key': ApiConfig.rawgApiKey,
      });
      return List<Map<String, dynamic>>.from(response.data['results'] ?? []);
    } catch (e) {
      print('Error getting game screenshots: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> getPopularGames() async {
    try {
      final response = await _dio.get('/games', queryParameters: {
        'key': ApiConfig.rawgApiKey,
        'ordering': '-rating',
        'page_size': 10,
      });
      return response.data;
    } catch (e) {
      print('Error getting popular games: $e');
      return {'results': []};
    }
  }
}