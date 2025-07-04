import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectlist/core/services/tmdb_service.dart';
import 'package:connectlist/core/services/rawg_service.dart';
import 'package:connectlist/core/services/google_books_service.dart';
import 'package:connectlist/core/services/yandex_places_service.dart';
import 'package:connectlist/core/services/youtube_service.dart';
import 'package:connectlist/core/models/content_item.dart';

final tmdbServiceProvider = Provider((ref) => TmdbService());
final rawgServiceProvider = Provider((ref) => RawgService());
final googleBooksServiceProvider = Provider((ref) => GoogleBooksService());
final yandexPlacesServiceProvider = Provider((ref) => YandexPlacesService());
final youtubeServiceProvider = Provider((ref) => YouTubeService());

final contentSearchProvider = FutureProvider.family<List<ContentItem>, ({String query, String category})>((ref, params) async {
  final query = params.query;
  final category = params.category;
  
  if (query.isEmpty) return [];
  
  switch (category) {
    case 'movies':
      final tmdbService = ref.read(tmdbServiceProvider);
      return tmdbService.searchMovies(query);
      
    case 'tv_shows':
      final tmdbService = ref.read(tmdbServiceProvider);
      return tmdbService.searchTvShows(query);
      
    case 'games':
      final rawgService = ref.read(rawgServiceProvider);
      return rawgService.searchGames(query);
      
    case 'books':
      final googleBooksService = ref.read(googleBooksServiceProvider);
      return googleBooksService.searchBooks(query);
      
    case 'places':
      final yandexPlacesService = ref.read(yandexPlacesServiceProvider);
      return yandexPlacesService.searchPlaces(query);
      
    case 'people':
      final tmdbService = ref.read(tmdbServiceProvider);
      return tmdbService.searchPeople(query);
      
    default:
      return [];
  }
});