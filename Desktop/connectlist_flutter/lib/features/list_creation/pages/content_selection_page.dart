import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../shared/widgets/sub_header.dart';
import '../../../core/models/content_item.dart' as core;
import '../../../core/providers/api_providers.dart';
import '../../../core/providers/list_providers.dart';
import '../models/content_item.dart';
import '../widgets/content_search_widget.dart';
import '../widgets/selected_items_widget.dart';
import '../widgets/youtube_link_widget.dart';
import 'list_details_page.dart';
import '../../../main.dart';
import '../../profile/pages/profile_page.dart';

class ContentSelectionPage extends ConsumerStatefulWidget {
  final String category;
  final int bottomMenuIndex;
  final String? existingListId; // For adding items to existing list

  const ContentSelectionPage({
    super.key,
    required this.category,
    this.bottomMenuIndex = 0,
    this.existingListId,
  });

  @override
  ConsumerState<ContentSelectionPage> createState() => _ContentSelectionPageState();
}

class _ContentSelectionPageState extends ConsumerState<ContentSelectionPage> {
  final List<ContentItem> _selectedItems = [];
  final TextEditingController _searchController = TextEditingController();
  List<ContentItem> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  String _currentQuery = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    // Auto-focus search field when adding items to existing list
    if (widget.existingListId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  ContentItem _convertToLocalContentItem(core.ContentItem coreItem) {
    return ContentItem(
      id: coreItem.id,
      title: coreItem.title,
      subtitle: coreItem.subtitle,
      imageUrl: coreItem.imageUrl,
      category: widget.category,
      metadata: coreItem.metadata,
      source: coreItem.source,
    );
  }

  void _toggleItemSelection(ContentItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _onSearchChanged(String query) {
    // This method is now handled by the text controller listener
    // with debouncing for better performance
  }

  void _proceedToNextStep() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one item'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      return;
    }

    // If we're adding to an existing list, add items directly
    if (widget.existingListId != null) {
      try {
        final supabase = ref.read(supabaseClientProvider);
        
        // Get current max position
        final existingItems = await supabase
            .from('list_items')
            .select('position')
            .eq('list_id', widget.existingListId!)
            .order('position', ascending: false)
            .limit(1);
        
        int startPosition = 1;
        if (existingItems.isNotEmpty) {
          startPosition = (existingItems[0]['position'] as int) + 1;
        }
        
        // Add new items
        final listItems = _selectedItems.map((item) => {
          'list_id': widget.existingListId,
          'external_id': item.id,
          'title': item.title,
          'description': item.subtitle,
          'image_url': item.imageUrl,
          'external_data': item.metadata,
          'source': item.source ?? 'manual',
          'position': startPosition + _selectedItems.indexOf(item),
        }).toList();
        
        await supabase
            .from('list_items')
            .insert(listItems);
        
        // Refresh list details
        ref.invalidate(listDetailsProvider(widget.existingListId!));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedItems.length} items added to list'),
              backgroundColor: Colors.green.shade600,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding items: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
      return;
    }

    // Otherwise, proceed to create new list
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListDetailsPage(
          category: widget.category,
          selectedItems: _selectedItems,
          bottomMenuIndex: widget.bottomMenuIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.arrowLeft(),
            color: Colors.grey.shade600,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SubHeader(
            selectedIndex: 0,
            onTabSelected: (index) {},
          ),
          Expanded(
            child: Column(
              children: [
                // Progress Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStepIndicator(1, true),
                      Expanded(child: _buildStepConnector(false)),
                      _buildStepIndicator(2, false),
                      Expanded(child: _buildStepConnector(false)),
                      _buildStepIndicator(3, false),
                    ],
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select ${widget.category}',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.category.toLowerCase() == 'videos'
                            ? 'Paste YouTube video links below to add them to your list'
                            : 'Choose items you want to add to your list',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Different UI for video category
                if (widget.category.toLowerCase() == 'videos')
                  // YouTube Link Widget
                  YouTubeLinkWidget(
                    onVideoSelected: _toggleItemSelection,
                  )
                else ...[
                  // Normal Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ContentSearchWidget(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      isLoading: _isSearching,
                      focusNode: _searchFocusNode,
                      autofocus: widget.existingListId != null,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
                
                // Selected Items
                if (_selectedItems.isNotEmpty)
                  SelectedItemsWidget(
                    selectedItems: _selectedItems,
                    onRemoveItem: _toggleItemSelection,
                  ),
                
                // Search Results (only show if not video category)
                if (widget.category.toLowerCase() != 'videos')
                  Expanded(
                    child: _currentQuery.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.magnifyingGlass(),
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Search for ${widget.category.toLowerCase()} to add',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                      : Consumer(
                          builder: (context, ref, child) {
                            final searchAsync = ref.watch(
                              contentSearchProvider((
                                query: _currentQuery,
                                category: _getCategoryKey(),
                              )),
                            );
                            
                            return searchAsync.when(
                              data: (results) {
                                if (results.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          PhosphorIcons.magnifyingGlass(),
                                          size: 64,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No results found',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    final coreItem = results[index];
                                    final item = _convertToLocalContentItem(coreItem);
                                    final isSelected = _selectedItems.any((selected) => selected.id == item.id);
                                    
                                    return _buildContentItem(item, isSelected, coreItem.imageUrl);
                                  },
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
                                      'Error loading results',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        ref.invalidate(contentSearchProvider);
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
          ),
          
          // Next Button
          Container(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedItems.isNotEmpty ? _proceedToNextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Next (${_selectedItems.length})',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomMenu(
        currentIndex: widget.bottomMenuIndex,
        onTap: (index) {
          if (index == 0) {
            // Home
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          } else if (index == 2) {
            // Add - Show category popup (already in creation flow)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          } else if (index == 4) {
            // Profile
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? Colors.orange.shade600 : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? Colors.orange.shade600 : Colors.grey.shade200,
    );
  }

  String _getCategoryKey() {
    switch (widget.category.toLowerCase()) {
      case 'movies':
        return 'movies';
      case 'tv shows':
        return 'tv_shows';
      case 'games':
        return 'games';
      case 'books':
        return 'books';
      case 'places':
        return 'places';
      case 'people':
        return 'people';
      default:
        return widget.category.toLowerCase();
    }
  }

  Widget _buildContentItem(ContentItem item, bool isSelected, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.orange.shade600 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleItemSelection(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: Icon(
                            PhosphorIcons.image(),
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isSelected ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
                  color: isSelected ? Colors.orange.shade600 : Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}