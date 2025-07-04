import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/list_model.dart';

class PrivacyOptionsWidget extends StatelessWidget {
  final ListPrivacy selectedPrivacy;
  final bool allowComments;
  final bool allowCollaboration;
  final Function(ListPrivacy) onPrivacyChanged;
  final Function(bool) onCommentsChanged;
  final Function(bool) onCollaborationChanged;

  const PrivacyOptionsWidget({
    super.key,
    required this.selectedPrivacy,
    required this.allowComments,
    required this.allowCollaboration,
    required this.onPrivacyChanged,
    required this.onCommentsChanged,
    required this.onCollaborationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Privacy Level
        Text(
          'Who can see this list?',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildPrivacyOption(
          ListPrivacy.public,
          'Public',
          'Anyone can see this list',
          PhosphorIcons.globe(),
          Colors.green,
        ),
        const SizedBox(height: 12),
        
        _buildPrivacyOption(
          ListPrivacy.unlisted,
          'Unlisted',
          'Only people with the link can see this list',
          PhosphorIcons.link(),
          Colors.orange,
        ),
        const SizedBox(height: 12),
        
        _buildPrivacyOption(
          ListPrivacy.private,
          'Private',
          'Only you can see this list',
          PhosphorIcons.lock(),
          Colors.red,
        ),
        
        const SizedBox(height: 32),
        
        // Interaction Settings
        Text(
          'Interaction Settings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildToggleOption(
          'Allow Comments',
          'Let others comment on your list',
          PhosphorIcons.chatCircle(),
          allowComments,
          onCommentsChanged,
        ),
        const SizedBox(height: 12),
        
        _buildToggleOption(
          'Allow Collaboration',
          'Let others add items to your list',
          PhosphorIcons.users(),
          allowCollaboration,
          onCollaborationChanged,
        ),
      ],
    );
  }

  Widget _buildPrivacyOption(
    ListPrivacy privacy,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedPrivacy == privacy;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onPrivacyChanged(privacy),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.orange.shade600 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.orange.shade50 : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? PhosphorIcons.radioButton(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
                color: isSelected ? Colors.orange.shade600 : Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.orange.shade600,
            activeTrackColor: Colors.orange.shade200,
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}