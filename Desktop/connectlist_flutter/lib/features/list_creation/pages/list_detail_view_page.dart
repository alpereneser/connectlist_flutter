import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../shared/widgets/sub_header.dart';
import '../models/list_model.dart';
import '../models/content_item.dart';

class ListDetailViewPage extends StatefulWidget {
  final ListModel list;
  final int bottomMenuIndex;

  const ListDetailViewPage({
    super.key,
    required this.list,
    this.bottomMenuIndex = 0,
  });

  @override
  State<ListDetailViewPage> createState() => _ListDetailViewPageState();
}

class _ListDetailViewPageState extends State<ListDetailViewPage> {
  bool _isLiked = false;
  bool _isBookmarked = false;
  int _subHeaderIndex = 0;

  String _getPrivacyText(ListPrivacy privacy) {
    switch (privacy) {
      case ListPrivacy.public:
        return 'Public';
      case ListPrivacy.private:
        return 'Private';
      case ListPrivacy.unlisted:
        return 'Unlisted';
    }
  }

  IconData _getPrivacyIcon(ListPrivacy privacy) {
    switch (privacy) {
      case ListPrivacy.public:
        return PhosphorIcons.globe();
      case ListPrivacy.private:
        return PhosphorIcons.lock();
      case ListPrivacy.unlisted:
        return PhosphorIcons.link();
    }
  }

  Color _getPrivacyColor(ListPrivacy privacy) {
    switch (privacy) {
      case ListPrivacy.public:
        return Colors.green;
      case ListPrivacy.private:
        return Colors.red;
      case ListPrivacy.unlisted:
        return Colors.orange;
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
            selectedIndex: _subHeaderIndex,
            onTabSelected: (index) {
              setState(() {
                _subHeaderIndex = index;
              });
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success Message
                  Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'List created successfully!',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // List Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPrivacyColor(widget.list.privacy).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPrivacyIcon(widget.list.privacy),
                                    size: 12,
                                    color: _getPrivacyColor(widget.list.privacy),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPrivacyText(widget.list.privacy),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _getPrivacyColor(widget.list.privacy),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Just now',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          widget.list.title,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          widget.list.description,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // List Stats
                        Row(
                          children: [
                            _buildStatChip(
                              PhosphorIcons.listBullets(),
                              '${widget.list.items.length} items',
                            ),
                            const SizedBox(width: 12),
                            if (widget.list.allowComments)
                              _buildStatChip(
                                PhosphorIcons.chatCircle(),
                                'Comments on',
                              ),
                            const SizedBox(width: 12),
                            if (widget.list.allowCollaboration)
                              _buildStatChip(
                                PhosphorIcons.users(),
                                'Collaborative',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: _isLiked ? PhosphorIcons.heart(PhosphorIconsStyle.fill) : PhosphorIcons.heart(),
                            label: 'Like',
                            onTap: () {
                              setState(() {
                                _isLiked = !_isLiked;
                              });
                            },
                            isActive: _isLiked,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: _isBookmarked ? PhosphorIcons.bookmark(PhosphorIconsStyle.fill) : PhosphorIcons.bookmark(),
                            label: 'Save',
                            onTap: () {
                              setState(() {
                                _isBookmarked = !_isBookmarked;
                              });
                            },
                            isActive: _isBookmarked,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: PhosphorIcons.shareNetwork(),
                            label: 'Share',
                            onTap: () {
                              // Share functionality
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // List Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items in this list',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.list.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.list.items[index];
                            return _buildListItem(item, index + 1);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
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

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? Colors.orange.shade600 : Colors.grey.shade200,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isActive ? Colors.orange.shade50 : Colors.white,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.orange.shade600 : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.orange.shade600 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(ContentItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}