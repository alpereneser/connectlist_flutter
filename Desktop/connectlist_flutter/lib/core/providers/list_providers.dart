import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/content_item.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final createListProvider = FutureProvider.family<String?, ({
  String title,
  String description,
  String category,
  List<ContentItem> items,
  String privacy,
  bool allowComments,
  bool allowCollaboration,
})>((ref, params) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  try {
    // Map category names to database values
    final categoryMapping = {
      'Places': 'places',
      'Movies': 'movies', 
      'Books': 'books',
      'TV Shows': 'tv_shows',
      'Videos': 'videos',
      'Musics': 'music',
      'Games': 'games',
      'People': 'people',
      'Poetry': 'poetry',
    };
    
    final dbCategoryName = categoryMapping[params.category] ?? params.category.toLowerCase();
    
    // Get category ID
    final categoryResponse = await supabase
        .from('categories')
        .select('id')
        .eq('name', dbCategoryName)
        .maybeSingle();
    
    String? categoryId;
    
    if (categoryResponse == null) {
      // Try to find by display_name if name doesn't work
      final categoryByDisplayName = await supabase
          .from('categories')
          .select('id')
          .eq('display_name', params.category)
          .maybeSingle();
      
      if (categoryByDisplayName == null) {
        throw Exception('Category not found: ${params.category}. Available categories should be checked.');
      }
      
      categoryId = categoryByDisplayName['id'];
    } else {
      categoryId = categoryResponse['id'];
    }
    
    // Create the list
    final listResponse = await supabase
        .from('lists')
        .insert({
          'creator_id': user.id,
          'category_id': categoryId,
          'title': params.title,
          'description': params.description,
          'privacy': params.privacy,
        })
        .select()
        .maybeSingle();
    
    if (listResponse == null) {
      throw Exception('Failed to create list - no response from database');
    }
    
    final listId = listResponse['id'];
    
    // Add list items
    final listItems = params.items.map((item) => {
      'list_id': listId,
      'external_id': item.id,
      'title': item.title,
      'description': item.subtitle,
      'image_url': item.imageUrl,
      'external_data': item.metadata,
      'source': item.source ?? 'manual',
      'position': params.items.indexOf(item) + 1,
    }).toList();
    
    await supabase
        .from('list_items')
        .insert(listItems);
    
    return listId;
  } catch (e) {
    print('Error creating list: $e');
    print('Category: ${params.category}');
    print('Title: ${params.title}');
    print('Privacy: ${params.privacy}');
    print('Items count: ${params.items.length}');
    throw Exception('Error creating list: $e');
  }
});

final userListsProvider = StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, userId) {
  final supabase = ref.read(supabaseClientProvider);
  
  // Create a stream controller
  final controller = StreamController<List<Map<String, dynamic>>>();
  
  // Function to fetch data
  Future<void> fetchData() async {
    try {
      final query = supabase
          .from('lists')
          .select('''
            *, 
            users_profiles!creator_id(username, avatar_url), 
            categories(name, display_name),
            likes_count,
            comments_count,
            shares_count,
            views_count
          ''');
      
      if (userId != null) {
        query.eq('creator_id', userId);
      }
      
      final data = await query.order('created_at', ascending: false);
      controller.add(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      print('Error fetching lists: $e');
      controller.add([]);
    }
  }
  
  // Initial fetch
  fetchData();
  
  // Set up realtime subscription
  final channel = supabase.channel('lists_changes_${userId ?? 'all'}').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'lists',
    filter: userId != null ? PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'creator_id',
      value: userId,
    ) : null,
    callback: (payload) {
      print('Realtime event: ${payload.eventType} for user: $userId');
      // Refetch data on any change
      fetchData();
    },
  );
  
  channel.subscribe();
  
  // Clean up when provider is disposed
  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });
  
  return controller.stream;
});

final listDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, listId) async {
  final supabase = ref.read(supabaseClientProvider);
  
  try {
    final response = await supabase
        .from('lists')
        .select('''
          *, 
          users_profiles!creator_id(username, avatar_url), 
          categories(name, display_name), 
          list_items(*),
          likes_count,
          comments_count,
          shares_count,
          views_count
        ''')
        .eq('id', listId)
        .single();
    
    return response;
  } catch (e) {
    print('Error fetching list details: $e');
    return null;
  }
});

final toggleListLikeProvider = FutureProvider.family<bool, String>((ref, listId) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  try {
    print('🔍 Checking like status for listId: $listId, userId: ${user.id}');
    
    // Check if already liked
    final existingLike = await supabase
        .from('list_likes')
        .select('id')
        .eq('list_id', listId)
        .eq('user_id', user.id)
        .maybeSingle();
    
    print('🔍 Existing like found: ${existingLike != null}');
    
    if (existingLike != null) {
      // Unlike
      print('👎 Removing like...');
      await supabase
          .from('list_likes')
          .delete()
          .eq('list_id', listId)
          .eq('user_id', user.id);
      print('✅ Like removed successfully');
      return false;
    } else {
      // Like
      print('👍 Adding like...');
      final insertData = {
        'list_id': listId,
        'user_id': user.id,
      };
      print('📦 Insert data: $insertData');
      
      await supabase
          .from('list_likes')
          .insert(insertData);
      print('✅ Like added successfully');
      return true;
    }
  } catch (e) {
    print('❌ Error toggling like: $e');
    print('📊 Error details: ${e.runtimeType}');
    if (e is PostgrestException) {
      print('🔍 PostgrestException details:');
      print('   Message: ${e.message}');
      print('   Code: ${e.code}');
      print('   Details: ${e.details}');
      print('   Hint: ${e.hint}');
    }
    throw e;
  }
});