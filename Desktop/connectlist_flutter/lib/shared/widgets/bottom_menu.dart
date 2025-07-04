import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../features/notifications/providers/notifications_provider.dart';

class BottomMenu extends ConsumerStatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomMenu({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  ConsumerState<BottomMenu> createState() => _BottomMenuState();
}

class _BottomMenuState extends ConsumerState<BottomMenu> {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      shadowColor: Colors.orange.shade100,
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade100,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMenuItem(
              icon: PhosphorIcons.house(),
              iconFilled: PhosphorIcons.house(PhosphorIconsStyle.fill),
              label: 'Home',
              index: 0,
            ),
            _buildMenuItem(
              icon: PhosphorIcons.magnifyingGlass(),
              iconFilled: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.fill),
              label: 'Search',
              index: 1,
            ),
            _buildAddButton(),
            _buildNotificationMenuItem(),
            _buildMenuItem(
              icon: PhosphorIcons.user(),
              iconFilled: PhosphorIcons.user(PhosphorIconsStyle.fill),
              label: 'Profile',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required IconData iconFilled,
    required String label,
    required int index,
  }) {
    final isSelected = widget.currentIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap(index);
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.orange.shade100,
        highlightColor: Colors.orange.shade50,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? iconFilled : icon,
                  size: 24,
                  color: isSelected ? Colors.orange.shade600 : Colors.grey.shade500,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationMenuItem() {
    final isSelected = widget.currentIndex == 3;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap(3);
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.orange.shade100,
        highlightColor: Colors.orange.shade50,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange.shade50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected 
                          ? PhosphorIcons.bell(PhosphorIconsStyle.fill)
                          : PhosphorIcons.bell(),
                      size: 24,
                      color: isSelected ? Colors.orange.shade600 : Colors.grey.shade500,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap(2);
        },
        borderRadius: BorderRadius.circular(28),
        splashColor: Colors.orange.shade700,
        highlightColor: Colors.orange.shade500,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade300,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            PhosphorIcons.plus(),
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}