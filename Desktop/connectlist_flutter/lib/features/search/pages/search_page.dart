import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../../core/providers/search_providers.dart';
import '../widgets/search_input.dart';
import '../widgets/search_category_tabs.dart';
import '../widgets/discover_section.dart';
import '../widgets/search_results.dart';
import '../../discover/pages/discover_users_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  Timer? _debounceTimer;
  
  String _currentQuery = '';
  int _selectedCategoryIndex = 0;
  int _currentBottomIndex = 1; // Search tab is selected
  
  final List<String> _searchCategories = [
    'All',
    'Users',
    'Lists',
    'Movies',
    'TV Shows',
    'Books',
    'Games',
    'People',
    'Places',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _currentQuery) {
        setState(() {
          _currentQuery = _searchController.text;
        });
      }
    });
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onBottomMenuTap(int index) {
    context.navigateToBottomMenuTab(index, _currentBottomIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          SearchInput(
            controller: _searchController,
            onChanged: (query) => _onSearchTextChanged(),
          ),
          
          // Category Tabs
          if (_currentQuery.isNotEmpty)
            SearchCategoryTabs(
              categories: _searchCategories,
              selectedIndex: _selectedCategoryIndex,
              onCategorySelected: _onCategorySelected,
            ),
          
          // Content
          Expanded(
            child: _currentQuery.isEmpty
                ? const DiscoverSection()
                : SearchResults(
                    query: _currentQuery,
                    selectedCategory: _searchCategories[_selectedCategoryIndex],
                    pageController: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomMenu(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomMenuTap,
      ),
    );
  }
}