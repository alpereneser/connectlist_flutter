import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shared/widgets/bottom_menu.dart';
import 'shared/widgets/category_popup.dart';
import 'shared/widgets/sub_header.dart';
import 'shared/utils/navigation_helper.dart';
import 'features/list_creation/pages/content_selection_page.dart';
import 'features/list_details/pages/modern_list_view_page.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/pages/login_page.dart';
import 'features/profile/pages/profile_page.dart';
import 'features/search/pages/search_page.dart';
import 'features/notifications/pages/notifications_page.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/messages/pages/messages_page.dart';
import 'features/discover/pages/discover_users_page.dart';
import 'shared/widgets/list_card.dart';
import 'shared/widgets/enhanced_list_card.dart';
import 'core/providers/list_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://ikalabbzbdbfuxpbiazz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlrYWxhYmJ6YmRiZnV4cGJpYXp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3MDkxMTIsImV4cCI6MjA2NjI4NTExMn0.VptwNkqalA8hfBqasy943wx5kKezkd_Wx7UbN-80YA4',
  );
  
  runApp(const ProviderScope(child: ConnectlistApp()));
}

class ConnectlistApp extends ConsumerWidget {
  const ConnectlistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Connectlist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        fontFamily: GoogleFonts.inter().fontFamily,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.grey.shade200,
          iconTheme: IconThemeData(color: Colors.grey.shade600),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          toolbarHeight: 66,
          shape: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/notifications': (context) => const NotificationsPage(),
        '/search': (context) => const SearchPage(),
        '/profile': (context) => const ProfilePage(),
        '/messages': (context) => const MessagesPage(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (state) {
        if (state?.session != null) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      ),
      error: (error, stackTrace) => const LoginPage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  bool _isPopupVisible = false;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize notifications when homepage loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadNotifications(refresh: true);
      ref.read(notificationsRealtimeListenerProvider);
    });
  }

  void _onBottomMenuTap(int index) {
    context.navigateToBottomMenuTab(
      index, 
      _currentIndex,
      onShowCategoryPopup: () {
        setState(() {
          _isPopupVisible = true;
        });
      },
    );
  }

  void _closePopup() {
    setState(() {
      _isPopupVisible = false;
    });
  }

  void _onCategorySelected(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentSelectionPage(
          category: category,
          bottomMenuIndex: _currentIndex,
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Image.asset(
              'assets/images/connectlist-beta-logo.png',
              height: 17,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  PhosphorIcons.users(),
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiscoverUsersPage(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  PhosphorIcons.chatCircle(),
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/messages');
                },
              ),
            ],
          ),
          backgroundColor: Colors.white,
          body: Column(
            children: [
              SubHeader(
                selectedIndex: _selectedCategoryIndex,
                onTabSelected: _onTabSelected,
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final listsAsync = ref.watch(userListsProvider(null));
                    
                    return listsAsync.when(
                      data: (lists) {
                        if (lists.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.listBullets(),
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No lists yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first list to get started',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        // Group lists by category and sort by created_at (newest first)
                        final groupedLists = <String, List<Map<String, dynamic>>>{};
                        for (final list in lists) {
                          final category = list['categories'] as Map<String, dynamic>?;
                          final categoryName = category?['display_name'] ?? 'Unknown';
                          groupedLists.putIfAbsent(categoryName, () => []).add(list);
                        }
                        
                        // Sort each category's lists by created_at (newest first)
                        groupedLists.forEach((category, categoryLists) {
                          categoryLists.sort((a, b) {
                            final aDate = DateTime.parse(a['created_at']);
                            final bDate = DateTime.parse(b['created_at']);
                            return bDate.compareTo(aDate); // Newest first
                          });
                        });
                        
                        // Build the list with category headers
                        final widgets = <Widget>[];
                        groupedLists.forEach((categoryName, categoryLists) {
                          // Add category header
                          widgets.add(_buildCategoryHeader(categoryName, categoryLists.length));
                          
                          // Add lists for this category
                          for (final list in categoryLists) {
                            final profile = list['users_profiles'] as Map<String, dynamic>?;
                            final category = list['categories'] as Map<String, dynamic>?;
                            widgets.add(
                              EnhancedListCard(
                                listId: list['id'],
                                listTitle: list['title'] ?? 'Untitled',
                                listDescription: list['description'],
                                userFullName: profile?['username'] ?? 'Unknown',
                                username: profile?['username'] ?? 'Unknown',
                                userAvatarUrl: profile?['avatar_url'] ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=default',
                                category: category?['display_name'] ?? 'Unknown',
                                createdAt: list['created_at'] is String 
                                    ? list['created_at'] 
                                    : DateTime.now().toIso8601String(),
                                itemCount: list['items_count'] ?? 0,
                                likesCount: list['likes_count'] ?? 0,
                                sharesCount: list['shares_count'] ?? 0,
                                commentsCount: list['comments_count'] ?? 0,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ModernListViewPage(
                                        listId: list['id'],
                                        bottomMenuIndex: _currentIndex,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        });
                        
                        return ListView.builder(
                          itemCount: widgets.length,
                          itemBuilder: (context, index) => widgets[index],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.wifiSlash(),
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading lists',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                ref.invalidate(userListsProvider);
                              },
                              child: Text(
                                'Retry',
                                style: GoogleFonts.inter(
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomMenu(
            currentIndex: _currentIndex,
            onTap: _onBottomMenuTap,
          ),
        ),
        CategoryPopup(
          isVisible: _isPopupVisible,
          onClose: _closePopup,
          onCategorySelected: _onCategorySelected,
        ),
      ],
    );
  }
  
  Widget _buildCategoryHeader(String categoryName, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text(
            categoryName,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}