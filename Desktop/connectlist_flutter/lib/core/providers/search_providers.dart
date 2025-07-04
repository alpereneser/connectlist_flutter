import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_providers.dart';

final supabase = Supabase.instance.client;

// Search provider for all categories
final searchProvider = FutureProvider.family<List<dynamic>, ({String query, String category})>((ref, params) async {
  final query = params.query.trim();
  if (query.isEmpty) return [];

  switch (params.category) {
    case 'users':
      return _searchUsers(query);
    case 'lists':
      return _searchLists(query);
    case 'movies':
      return _searchMovies(ref, query);
    case 'tv_shows':
      return _searchTVShows(ref, query);
    case 'books':
      return _searchBooks(ref, query);
    case 'games':
      return _searchGames(ref, query);
    case 'people':
      return _searchPeople(ref, query);
    case 'places':
      return _searchPlaces(ref, query);
    default:
      return [];
  }
});

// Discover providers for random/trending content
final discoverMoviesProvider = FutureProvider<List<dynamic>>((ref) async {
  final tmdbService = ref.read(tmdbServiceProvider);
  try {
    final response = await tmdbService.getTrendingMovies();
    return response['results'] ?? [];
  } catch (e) {
    print('Error fetching trending movies: $e');
    return [];
  }
});

final discoverBooksProvider = FutureProvider<List<dynamic>>((ref) async {
  final googleBooksService = ref.read(googleBooksServiceProvider);
  try {
    // Search for popular books
    final results = await googleBooksService.searchBooks('bestseller');
    // Filter books that have images
    final booksWithImages = results.where((item) => 
      item.imageUrl != null && item.imageUrl!.isNotEmpty
    ).toList();
    
    return booksWithImages.map((item) => {
      'volumeInfo': {
        'title': item.title,
        'authors': item.subtitle != null ? item.subtitle!.split(', ') : [],
        'description': item.metadata['volumeInfo']?['description'] ?? '',
        'imageLinks': {
          'thumbnail': item.imageUrl,
        }
      }
    }).toList();
  } catch (e) {
    print('Error fetching popular books: $e');
    return [];
  }
});

final discoverGamesProvider = FutureProvider<List<dynamic>>((ref) async {
  final rawgService = ref.read(rawgServiceProvider);
  try {
    final response = await rawgService.getPopularGames();
    return response['results'] ?? [];
  } catch (e) {
    print('Error fetching popular games: $e');
    return [];
  }
});

final discoverTVShowsProvider = FutureProvider<List<dynamic>>((ref) async {
  final tmdbService = ref.read(tmdbServiceProvider);
  try {
    final response = await tmdbService.getTrendingTVShows();
    return response['results'] ?? [];
  } catch (e) {
    print('Error fetching trending TV shows: $e');
    return [];
  }
});

final discoverPeopleProvider = FutureProvider<List<dynamic>>((ref) async {
  final tmdbService = ref.read(tmdbServiceProvider);
  try {
    final response = await tmdbService.getTrendingPeople();
    return response['results'] ?? [];
  } catch (e) {
    print('Error fetching trending people: $e');
    return [];
  }
});

final discoverPlacesProvider = FutureProvider<List<dynamic>>((ref) async {
  final yandexPlacesService = ref.read(yandexPlacesServiceProvider);
  try {
    // Search for popular places in major cities
    final cities = ['cafe Istanbul', 'restaurant Ankara', 'hotel Izmir', 'museum Antalya', 'park Bursa'];
    final allPlaces = <dynamic>[];
    final placeImages = [
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', // restaurant
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400', // hotel
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400', // cafe
      'https://images.unsplash.com/photo-1580655653885-65763b2597d0?w=400', // museum
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400', // park
      'https://images.unsplash.com/photo-1471919743851-c4df8b6ee130?w=400', // city
      'https://images.unsplash.com/photo-1533929736458-ca588d08c8be?w=400', // building
      'https://images.unsplash.com/photo-1509600110300-21b9d5fedeb7?w=400', // plaza
    ];
    
    for (int i = 0; i < cities.length; i++) {
      final results = await yandexPlacesService.searchPlaces(cities[i]);
      final places = results.take(2).map((item) => {
        'name': item.title,
        'vicinity': item.subtitle ?? cities[i].split(' ').last,
        'rating': (item.metadata['rating'] ?? 4.0) is String 
            ? double.tryParse(item.metadata['rating'].toString()) ?? 4.0
            : item.metadata['rating'] ?? 4.0,
        'place_image': placeImages[(i * 2) % placeImages.length],
      }).toList();
      allPlaces.addAll(places);
    }
    
    return allPlaces;
  } catch (e) {
    print('Error fetching trending places: $e');
    return [];
  }
});

final discoverListsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final response = await supabase
        .from('lists')
        .select('''
          *,
          categories!inner(*),
          users_profiles!creator_id(*)
        ''')
        .eq('privacy', 'public')
        .order('created_at', ascending: false)
        .limit(10);
    
    return response as List<dynamic>;
  } catch (e) {
    print('Error fetching recent lists: $e');
    return [];
  }
});

// Search functions
Future<List<dynamic>> _searchUsers(String query) async {
  try {
    final response = await supabase
        .from('users_profiles')
        .select('*')
        .or('username.ilike.%$query%,full_name.ilike.%$query%')
        .limit(20);
    
    return response as List<dynamic>;
  } catch (e) {
    print('Error searching users: $e');
    return [];
  }
}

Future<List<dynamic>> _searchLists(String query) async {
  try {
    final response = await supabase
        .from('lists')
        .select('''
          *,
          categories!inner(*),
          users_profiles!creator_id(*)
        ''')
        .eq('privacy', 'public')
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('created_at', ascending: false)
        .limit(20);
    
    return response as List<dynamic>;
  } catch (e) {
    print('Error searching lists: $e');
    return [];
  }
}

Future<List<dynamic>> _searchMovies(Ref ref, String query) async {
  try {
    final tmdbService = ref.read(tmdbServiceProvider);
    final results = await tmdbService.searchMovies(query);
    return results.map((item) => {
      'title': item.title,
      'overview': item.subtitle,
      'poster_path': item.imageUrl?.replaceAll('https://image.tmdb.org/t/p/w300', ''),
      'release_date': item.metadata['release_date'],
    }).toList();
  } catch (e) {
    print('Error searching movies: $e');
    return [];
  }
}

Future<List<dynamic>> _searchTVShows(Ref ref, String query) async {
  try {
    final tmdbService = ref.read(tmdbServiceProvider);
    final results = await tmdbService.searchTvShows(query);
    return results.map((item) => {
      'name': item.title,
      'overview': item.subtitle,
      'poster_path': item.imageUrl?.replaceAll('https://image.tmdb.org/t/p/w300', ''),
      'first_air_date': item.metadata['first_air_date'],
    }).toList();
  } catch (e) {
    print('Error searching TV shows: $e');
    return [];
  }
}

Future<List<dynamic>> _searchBooks(Ref ref, String query) async {
  try {
    final googleBooksService = ref.read(googleBooksServiceProvider);
    final results = await googleBooksService.searchBooks(query);
    // Filter books that have images
    final booksWithImages = results.where((item) => 
      item.imageUrl != null && item.imageUrl!.isNotEmpty
    ).toList();
    
    return booksWithImages.map((item) => {
      'volumeInfo': {
        'title': item.title,
        'authors': item.subtitle != null ? item.subtitle!.split(', ') : [],
        'description': item.metadata['volumeInfo']?['description'] ?? '',
        'imageLinks': {
          'thumbnail': item.imageUrl,
        }
      }
    }).toList();
  } catch (e) {
    print('Error searching books: $e');
    return [];
  }
}

Future<List<dynamic>> _searchGames(Ref ref, String query) async {
  try {
    final rawgService = ref.read(rawgServiceProvider);
    final results = await rawgService.searchGames(query);
    return results.map((item) => {
      'name': item.title,
      'background_image': item.imageUrl,
      'rating': item.metadata['rating'],
      'released': item.metadata['released'],
    }).toList();
  } catch (e) {
    print('Error searching games: $e');
    return [];
  }
}

Future<List<dynamic>> _searchPeople(Ref ref, String query) async {
  try {
    final tmdbService = ref.read(tmdbServiceProvider);
    final results = await tmdbService.searchPeople(query);
    return results.map((item) => {
      'name': item.title,
      'known_for_department': item.subtitle,
      'profile_path': item.imageUrl?.replaceAll('https://image.tmdb.org/t/p/w300', ''),
    }).toList();
  } catch (e) {
    print('Error searching people: $e');
    return [];
  }
}

Future<List<dynamic>> _searchPlaces(Ref ref, String query) async {
  try {
    final yandexPlacesService = ref.read(yandexPlacesServiceProvider);
    final results = await yandexPlacesService.searchPlaces(query);
    final placeImages = [
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400',
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400',
      'https://images.unsplash.com/photo-1580655653885-65763b2597d0?w=400',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
      'https://images.unsplash.com/photo-1471919743851-c4df8b6ee130?w=400',
    ];
    
    return results.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return {
        'name': item.title,
        'vicinity': item.subtitle,
        'rating': (item.metadata['rating'] ?? 4.0) is String 
            ? double.tryParse(item.metadata['rating'].toString()) ?? 4.0
            : item.metadata['rating'] ?? 4.0,
        'place_image': placeImages[index % placeImages.length],
      };
    }).toList();
  } catch (e) {
    print('Error searching places: $e');
    return [];
  }
}