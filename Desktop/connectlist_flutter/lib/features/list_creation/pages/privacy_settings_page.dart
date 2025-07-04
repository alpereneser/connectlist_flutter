import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../shared/widgets/sub_header.dart';
import '../../../core/models/content_item.dart' as core;
import '../../../core/providers/list_providers.dart';
import '../../../features/list_details/pages/modern_list_view_page.dart';
import '../models/content_item.dart';
import '../models/list_model.dart';
import '../widgets/privacy_options_widget.dart';
import 'list_detail_view_page.dart';

class PrivacySettingsPage extends ConsumerStatefulWidget {
  final String category;
  final List<ContentItem> selectedItems;
  final String title;
  final String description;
  final int bottomMenuIndex;

  const PrivacySettingsPage({
    super.key,
    required this.category,
    required this.selectedItems,
    required this.title,
    required this.description,
    this.bottomMenuIndex = 0,
  });

  @override
  ConsumerState<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends ConsumerState<PrivacySettingsPage> {
  ListPrivacy _selectedPrivacy = ListPrivacy.public;
  bool _allowComments = true;
  bool _allowCollaboration = false;
  bool _isCreating = false;

  void _createList() async {
    setState(() {
      _isCreating = true;
    });

    try {
      // Convert local ContentItem to core ContentItem
      final coreItems = widget.selectedItems.map((item) => core.ContentItem(
        id: item.id,
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        category: item.category,
        metadata: item.metadata ?? {},
        source: item.source, // Preserve original source (tmdb, rawg, etc.)
      )).toList();

      final listId = await ref.read(createListProvider((
        title: widget.title,
        description: widget.description,
        category: widget.category.toLowerCase().replaceAll(' ', '_'),
        items: coreItems,
        privacy: _selectedPrivacy.name,
        allowComments: _allowComments,
        allowCollaboration: _allowCollaboration,
      )).future);

      if (mounted && listId != null) {
        // Navigate to the created list view
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ModernListViewPage(
              listId: listId,
              bottomMenuIndex: widget.bottomMenuIndex,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating list: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Progress Indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildStepIndicator(1, false),
                        Expanded(child: _buildStepConnector(true)),
                        _buildStepIndicator(2, false),
                        Expanded(child: _buildStepConnector(true)),
                        _buildStepIndicator(3, true),
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
                          'Privacy Settings',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose who can see and interact with your list',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // List Summary
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.listBullets(),
                              size: 16,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.selectedItems.length} ${widget.category}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Privacy Options
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PrivacyOptionsWidget(
                      selectedPrivacy: _selectedPrivacy,
                      allowComments: _allowComments,
                      allowCollaboration: _allowCollaboration,
                      onPrivacyChanged: (privacy) {
                        setState(() {
                          _selectedPrivacy = privacy;
                        });
                      },
                      onCommentsChanged: (value) {
                        setState(() {
                          _allowComments = value;
                        });
                      },
                      onCollaborationChanged: (value) {
                        setState(() {
                          _allowCollaboration = value;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Create Button
          Container(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isCreating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Creating List...',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Create List',
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
        onTap: (index) {},
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
}