import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../list/models/list_model.dart';
import '../../list/providers/liked_lists_provider.dart';
import '../../list/widgets/list_item.dart';
import '../pages/profile_page.dart';

class LikedListsModal extends ConsumerWidget {
  final String userId;
  final String userName;

  const LikedListsModal({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedListsAsync = ref.watch(userLikedListsProvider(userId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    PhosphorIcons.x(),
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Beğenilen Listeler',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          
          // Liked Lists
          Expanded(
            child: likedListsAsync.when(
              data: (likedLists) {
                if (likedLists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.heart(),
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz beğenilen liste yok',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: likedLists.length,
                  itemBuilder: (context, index) {
                    final list = likedLists[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListItem(
                        list: list,
                        showActions: false,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.warning(),
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Beğenilen listeler yüklenemedi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}