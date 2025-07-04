import 'package:dio/dio.dart';
import 'package:connectlist/core/config/api_config.dart';

class YouTubeService {
  late final Dio _dio;
  
  YouTubeService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.youtubeBaseUrl,
    ));
  }
  
  String? extractVideoId(String url) {
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([^&]+)'),
      RegExp(r'youtu\.be/([^?]+)'),
      RegExp(r'youtube\.com/embed/([^?]+)'),
      RegExp(r'youtube\.com/v/([^?]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> getVideoDetails(String videoId) async {
    try {
      print('YouTube API Request - Video ID: $videoId');
      print('YouTube API Request - Full URL: ${ApiConfig.youtubeBaseUrl}/videos?key=${ApiConfig.youtubeApiKey}&id=$videoId&part=snippet,contentDetails,statistics');
      
      final response = await _dio.get('/videos', queryParameters: {
        'key': ApiConfig.youtubeApiKey,
        'id': videoId,
        'part': 'snippet,contentDetails,statistics',
      });
      
      print('YouTube API Response: ${response.statusCode}');
      print('YouTube API Response Data: ${response.data}');
      
      final items = response.data['items'] as List?;
      if (items != null && items.isNotEmpty) {
        return items.first;
      }
      
      // If no items returned, video might not exist or be private
      print('No items returned for video ID: $videoId');
      return null;
    } catch (e) {
      print('Error getting video details: $e');
      print('Video ID that caused error: $videoId');
      
      // Check if it's a 403 error (API key or quota issue)
      if (e.toString().contains('403')) {
        print('YouTube API 403 Error: Check if YouTube Data API v3 is enabled and API key has sufficient quota');
        throw Exception('YouTube API access denied. Please check API configuration.');
      } else if (e.toString().contains('400')) {
        print('YouTube API 400 Error: Bad request - probably invalid video ID or API request format');
        throw Exception('Invalid video link. Please check the YouTube URL.');
      }
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getVideoDetailsFromUrl(String url) async {
    final videoId = extractVideoId(url);
    if (videoId == null) return null;
    
    return getVideoDetails(videoId);
  }
}