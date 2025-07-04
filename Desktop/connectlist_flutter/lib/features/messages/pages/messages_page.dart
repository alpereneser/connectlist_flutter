import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../widgets/conversations_tab.dart';
import '../widgets/people_tab.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentBottomIndex = 0; // This page is not in bottom menu, but we use 0 for home

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomMenuTap(int index) {
    if (index == 0) {
      // Home
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else if (index == 1) {
      // Search
      Navigator.of(context).pushNamed('/search');
    } else if (index == 2) {
      // Add - This would show category popup
      Navigator.of(context).pop();
    } else if (index == 3) {
      // Notifications
      Navigator.of(context).pushNamed('/notifications');
    } else if (index == 4) {
      // Profile
      Navigator.of(context).pushNamed('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.magnifyingGlass()),
            onPressed: () {
              // Search messages/people
            },
          ),
          IconButton(
            icon: Icon(PhosphorIcons.pencilSimple()),
            onPressed: () {
              // New message
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange.shade600,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.orange.shade600,
          indicatorWeight: 2,
          labelStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'People'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ConversationsTab(),
          PeopleTab(),
        ],
      ),
      bottomNavigationBar: BottomMenu(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomMenuTap,
      ),
    );
  }
}