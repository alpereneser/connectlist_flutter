import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/list_model.dart';
import '../../social/services/social_service.dart';

final userLikedListsProvider = FutureProvider.family<List<ListModel>, String>((ref, userId) async {
  final socialService = SocialService();
  final likedListsData = await socialService.getUserLikedLists(userId);
  return likedListsData.map((data) => ListModel.fromJson(data)).toList();
});