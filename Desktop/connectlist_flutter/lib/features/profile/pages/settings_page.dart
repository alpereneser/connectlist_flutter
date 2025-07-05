import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../core/providers/settings_providers.dart' as settings;
import 'privacy_settings_page.dart';
import 'notification_settings_page.dart';
import 'help_support_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  int _currentBottomIndex = 4; // Profile tab is selected
  final ImagePicker _imagePicker = ImagePicker();
  String? _newAvatarUrl;

  void _onBottomMenuTap(int index) {
    if (index == 4) {
      // Go back to profile page
      Navigator.of(context).pop();
    } else if (index == 2) {
      // TODO: Handle add button
    } else {
      // Navigate to other pages
      Navigator.of(context).pop(); // Go back to profile and handle navigation there
    }
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _locationController = TextEditingController();
    _phoneController = TextEditingController();
    
    // Initialize with current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      final supabase = ref.read(settings.supabaseProvider);
      if (user != null) {
        _fullNameController.text = user.fullName ?? '';
        _usernameController.text = user.username;
        _bioController.text = user.bio ?? '';
        _emailController.text = supabase.auth.currentUser?.email ?? '';
        // Note: website, location, phone will be loaded from extended profile
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare profile data
      final profileData = {
        'full_name': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      };
      
      // Add new avatar URL if uploaded
      if (_newAvatarUrl != null) {
        profileData['avatar_url'] = _newAvatarUrl;
      }
      
      // Remove empty values
      profileData.removeWhere((key, value) => value == null || value == '');
      
      await ref.read(settings.updateProfileProvider(profileData).future);
      
      // Refresh auth provider to get updated user data
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  PhosphorIcons.checkCircle(),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  PhosphorIcons.warning(),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      // Kullanıcıya kaynak seçimi sun
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (image != null) {
        setState(() {
          _isUploadingAvatar = true;
        });
        
        final bytes = await image.readAsBytes();
        final avatarUrl = await ref.read(settings.uploadAvatarProvider(bytes).future);
        
        setState(() {
          _newAvatarUrl = avatarUrl;
          _isUploadingAvatar = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Avatar yüklendi! Değişiklikleri kaydetmeyi unutmayın.'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar yüklenirken hata: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Fotoğraf Seç',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                PhosphorIcons.camera(),
                color: Colors.orange.shade600,
              ),
              title: Text(
                'Kameradan Çek',
                style: GoogleFonts.inter(),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(
                PhosphorIcons.image(),
                color: Colors.orange.shade600,
              ),
              title: Text(
                'Galeriden Seç',
                style: GoogleFonts.inter(),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Çıkış Yap',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Çıkış yapmak istediğinizden emin misiniz?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'İptal',
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Çıkış Yap',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
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
      body: currentUser == null
          ? const Center(
              child: Text('No user data available'),
            )
          : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Section
                _buildSection(
                  'Profil Fotoğrafı',
                  PhosphorIcons.camera(),
                  [
                    _buildAvatarSection(),
                  ],
                ),

                const SizedBox(height: 24),

                // Profile Section
                _buildSection(
                  'Profil Bilgileri',
                  PhosphorIcons.user(),
                  [
                    _buildTextField(
                      'Ad Soyad',
                      _fullNameController,
                      PhosphorIcons.user(),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Kullanıcı Adı',
                      _usernameController,
                      PhosphorIcons.at(),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Bio',
                      _bioController,
                      PhosphorIcons.note(),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Website',
                      _websiteController,
                      PhosphorIcons.globe(),
                      placeholder: 'https://example.com',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Konum',
                      _locationController,
                      PhosphorIcons.mapPin(),
                      placeholder: 'İstanbul, Türkiye',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Telefon',
                      _phoneController,
                      PhosphorIcons.phone(),
                      placeholder: '+90 555 123 45 67',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'E-posta',
                      _emailController,
                      PhosphorIcons.envelope(),
                      enabled: false,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Updating...',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Değişiklikleri Kaydet',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Account Section
                _buildSection(
                  'Hesap Ayarları',
                  PhosphorIcons.gear(),
                  [
                    _buildSettingsTile(
                      'Gizlilik ve Güvenlik',
                      PhosphorIcons.shield(),
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PrivacySettingsPage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      'Bildirimler',
                      PhosphorIcons.bell(),
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationSettingsPage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      'Yardım ve Destek',
                      PhosphorIcons.question(),
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _signOut,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade400),
                      foregroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.signOut(),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Çıkış Yap',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
      bottomNavigationBar: BottomMenu(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomMenuTap,
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final currentUser = ref.watch(currentUserProvider);
    final avatarUrl = _newAvatarUrl ?? currentUser?.avatarUrl;
    
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Icon(
                          PhosphorIcons.user(),
                          size: 40,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: _isUploadingAvatar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            PhosphorIcons.camera(),
                            color: Colors.white,
                            size: 16,
                          ),
                    onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Profil fotoğrafını değiştirmek için kameraya tıklayın',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool enabled = true,
    String? placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: enabled ? Colors.grey.shade800 : Colors.grey.shade500,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.orange.shade400,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(),
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}