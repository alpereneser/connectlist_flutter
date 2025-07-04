import 'package:dio/dio.dart';
import 'package:connectlist/core/config/api_config.dart';
import 'package:connectlist/core/models/content_item.dart';

class TmdbService {
  late final Dio _dio;
  
  TmdbService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.tmdbBaseUrl,
      headers: {
        'Authorization': 'Bearer ${ApiConfig.tmdbReadAccessToken}',
        'Content-Type': 'application/json',
      },
    ));
  }
  
  Future<List<ContentItem>> searchMovies(String query) async {
    try {
      final response = await _dio.get('/search/movie', queryParameters: {
        'query': query,
        'language': 'tr-TR',
      });
      
      final results = response.data['results'] as List;
      return results.map((movie) => ContentItem.fromTmdbMovie(movie)).toList();
    } catch (e) {
      print('Error searching movies: $e');
      return [];
    }
  }
  
  Future<List<ContentItem>> searchTvShows(String query) async {
    try {
      final response = await _dio.get('/search/tv', queryParameters: {
        'query': query,
        'language': 'tr-TR',
      });
      
      final results = response.data['results'] as List;
      return results.map((tvShow) => ContentItem.fromTmdbTvShow(tvShow)).toList();
    } catch (e) {
      print('Error searching TV shows: $e');
      return [];
    }
  }
  
  Future<List<ContentItem>> searchPeople(String query) async {
    try {
      final response = await _dio.get('/search/person', queryParameters: {
        'query': query,
        'language': 'tr-TR',
      });
      
      final results = response.data['results'] as List;
      return results.map((person) => ContentItem.fromTmdbPerson(person)).toList();
    } catch (e) {
      print('Error searching people: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getMovieDetails(String id) async {
    try {
      final response = await _dio.get('/movie/$id', queryParameters: {
        'language': 'tr-TR',
        'append_to_response': 'credits,videos,similar',
      });
      return response.data;
    } catch (e) {
      print('Error getting movie details: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getTvShowDetails(String id) async {
    try {
      final response = await _dio.get('/tv/$id', queryParameters: {
        'language': 'tr-TR',
        'append_to_response': 'credits,videos,similar',
      });
      return response.data;
    } catch (e) {
      print('Error getting TV show details: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getPersonDetails(String id) async {
    try {
      final response = await _dio.get('/person/$id', queryParameters: {
        'language': 'tr-TR',
        'append_to_response': 'movie_credits,tv_credits',
      });
      return response.data;
    } catch (e) {
      print('Error getting person details: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>> getTrendingMovies() async {
    try {
      final response = await _dio.get('/trending/movie/day', queryParameters: {
        'language': 'en-US',
      });
      return response.data;
    } catch (e) {
      print('Error getting trending movies: $e');
      return {'results': []};
    }
  }
  
  Future<Map<String, dynamic>> getTrendingTVShows() async {
    try {
      final response = await _dio.get('/trending/tv/day', queryParameters: {
        'language': 'en-US',
      });
      return response.data;
    } catch (e) {
      print('Error getting trending TV shows: $e');
      return {'results': []};
    }
  }
  
  Future<Map<String, dynamic>> getTrendingPeople() async {
    try {
      final response = await _dio.get('/trending/person/day', queryParameters: {
        'language': 'en-US',
      });
      return response.data;
    } catch (e) {
      print('Error getting trending people: $e');
      return {'results': []};
    }
  }
}