import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_categories.dart';
import '../widgets/profile_content.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../shared/utils/navigation_helper.dart';
import 'settings_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? userId; // null means current user profile
  
  const ProfilePage({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int _selectedCategoryIndex = 0;
  int _currentBottomIndex = 4; // Profile tab is selected
  
  bool get isCurrentUser => widget.userId == null || widget.userId == ref.watch(currentUserProvider)?.id;

  void _onBottomMenuTap(int index) {
    context.navigateToBottomMenuTab(index, _currentBottomIndex);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final targetUserId = widget.userId ?? currentUser?.id;
    
    if (targetUserId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Text('Please log in to view profile'),
        ),
      );
    }
    
    // Use current user if viewing own profile, otherwise fetch other user
    final userAsync = isCurrentUser && currentUser != null
        ? AsyncValue.data(currentUser)
        : ref.watch(userProfileProvider(targetUserId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !isCurrentUser,
        title: Image.asset(
          'assets/images/connectlist-beta-logo.png',
          height: 17,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              PhosphorIcons.chatCircle(),
              color: Colors.grey.shade600,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('User not found'),
            );
          }
          
          return Column(
            children: [
              // Profile Header
              ProfileHeader(
                user: user,
                isCurrentUser: isCurrentUser,
              ),
              
              // Profile Stats
              ProfileStats(
                userId: user.id,
                isCurrentUser: isCurrentUser,
              ),
              
              // Profile Categories
              ProfileCategories(
                selectedIndex: _selectedCategoryIndex,
                onTabSelected: (index) {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                isCurrentUser: isCurrentUser,
              ),
              
              // Profile Content
              Expanded(
                child: ProfileContent(
                  userId: user.id,
                  categoryIndex: _selectedCategoryIndex,
                  isCurrentUser: isCurrentUser,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
                'Error loading profile',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isCurrentUser
          ? BottomMenu(
              currentIndex: _currentBottomIndex,
              onTap: _onBottomMenuTap,
            )
          : null,
    );
  }
}