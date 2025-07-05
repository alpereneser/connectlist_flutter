import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../services/social_service.dart';

final followersListProvider = FutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final socialService = SocialService();
  return await socialService.getFollowers(userId);
});