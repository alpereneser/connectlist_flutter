import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/settings_providers.dart' as settings;

class PrivacySettingsPage extends ConsumerStatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  ConsumerState<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends ConsumerState<PrivacySettingsPage> {
  String _profileVisibility = 'public';
  bool _showEmail = false;
  bool _showPhone = false;
  bool _showLocation = true;
  bool _showBirthDate = false;
  bool _allowSearchByEmail = true;
  bool _allowSearchByPhone = false;
  bool _showOnlineStatus = true;
  bool _allowFriendRequests = true;
  bool _allowListComments = true;
  bool _allowListLikes = true;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final privacySettings = await ref.read(settings.privacySettingsProvider.future);
      if (privacySettings != null && mounted) {
        setState(() {
          _profileVisibility = privacySettings['profile_visibility'] ?? 'public';
          _showEmail = privacySettings['show_email'] ?? false;
          _showPhone = privacySettings['show_phone'] ?? false;
          _showLocation = privacySettings['show_location'] ?? true;
          _showBirthDate = privacySettings['show_birth_date'] ?? false;
          _allowSearchByEmail = privacySettings['allow_search_by_email'] ?? true;
          _allowSearchByPhone = privacySettings['allow_search_by_phone'] ?? false;
          _showOnlineStatus = privacySettings['show_online_status'] ?? true;
          _allowFriendRequests = privacySettings['allow_friend_requests'] ?? true;
          _allowListComments = privacySettings['allow_list_comments'] ?? true;
          _allowListLikes = privacySettings['allow_list_likes'] ?? true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePrivacySettings() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final settingsData = {
        'profile_visibility': _profileVisibility,
        'show_email': _showEmail,
        'show_phone': _showPhone,
        'show_location': _showLocation,
        'show_birth_date': _showBirthDate,
        'allow_search_by_email': _allowSearchByEmail,
        'allow_search_by_phone': _allowSearchByPhone,
        'show_online_status': _showOnlineStatus,
        'allow_friend_requests': _allowFriendRequests,
        'allow_list_comments': _allowListComments,
        'allow_list_likes': _allowListLikes,
      };

      final notifier = ref.read(settings.privacySettingsNotifierProvider.notifier);
      await notifier.updatePrivacySettings(settingsData);

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
                const Text('Privacy settings updated successfully'),
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
                Text('Hata: ${e.toString()}'),
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
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Gizlilik ve Güvenlik',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.arrowLeft(),
            color: Colors.grey.shade800,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Visibility Section
                  _buildSection(
                    'Profil Görünürlüğü',
                    PhosphorIcons.eye(),
                    [
                      _buildRadioOption(
                        'Herkese Açık',
                        'Profilinizi herkes görebilir',
                        'public',
                        _profileVisibility,
                        (value) => setState(() => _profileVisibility = value!),
                      ),
                      _buildRadioOption(
                        'Özel',
                        'Sadece takipçileriniz görebilir',
                        'private',
                        _profileVisibility,
                        (value) => setState(() => _profileVisibility = value!),
                      ),
                      _buildRadioOption(
                        'Sadece Arkadaşlar',
                        'Sadece arkadaşlarınız görebilir',
                        'friends_only',
                        _profileVisibility,
                        (value) => setState(() => _profileVisibility = value!),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Information Visibility Section
                  _buildSection(
                    'Bilgi Görünürlüğü',
                    PhosphorIcons.info(),
                    [
                      _buildSwitchTile(
                        'E-posta Adresini Göster',
                        'Diğer kullanıcılar e-posta adresinizi görebilir',
                        _showEmail,
                        (value) => setState(() => _showEmail = value),
                      ),
                      _buildSwitchTile(
                        'Telefon Numarasını Göster',
                        'Diğer kullanıcılar telefon numaranızı görebilir',
                        _showPhone,
                        (value) => setState(() => _showPhone = value),
                      ),
                      _buildSwitchTile(
                        'Konumu Göster',
                        'Diğer kullanıcılar konumunuzu görebilir',
                        _showLocation,
                        (value) => setState(() => _showLocation = value),
                      ),
                      _buildSwitchTile(
                        'Doğum Tarihini Göster',
                        'Diğer kullanıcılar doğum tarihinizi görebilir',
                        _showBirthDate,
                        (value) => setState(() => _showBirthDate = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Search & Discovery Section
                  _buildSection(
                    'Arama ve Keşif',
                    PhosphorIcons.magnifyingGlass(),
                    [
                      _buildSwitchTile(
                        'E-posta ile Aranabilir',
                        'Diğer kullanıcılar sizi e-posta ile bulabilir',
                        _allowSearchByEmail,
                        (value) => setState(() => _allowSearchByEmail = value),
                      ),
                      _buildSwitchTile(
                        'Telefon ile Aranabilir',
                        'Diğer kullanıcılar sizi telefon ile bulabilir',
                        _allowSearchByPhone,
                        (value) => setState(() => _allowSearchByPhone = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Interaction Section
                  _buildSection(
                    'Etkileşim Ayarları',
                    PhosphorIcons.chatCircle(),
                    [
                      _buildSwitchTile(
                        'Çevrimiçi Durumu Göster',
                        'Diğer kullanıcılar çevrimiçi olduğunuzu görebilir',
                        _showOnlineStatus,
                        (value) => setState(() => _showOnlineStatus = value),
                      ),
                      _buildSwitchTile(
                        'Arkadaşlık İsteklerine İzin Ver',
                        'Diğer kullanıcılar size arkadaşlık isteği gönderebilir',
                        _allowFriendRequests,
                        (value) => setState(() => _allowFriendRequests = value),
                      ),
                      _buildSwitchTile(
                        'Liste Yorumlarına İzin Ver',
                        'Diğer kullanıcılar listelerinize yorum yapabilir',
                        _allowListComments,
                        (value) => setState(() => _allowListComments = value),
                      ),
                      _buildSwitchTile(
                        'Liste Beğenilerine İzin Ver',
                        'Diğer kullanıcılar listelerinizi beğenebilir',
                        _allowListLikes,
                        (value) => setState(() => _allowListLikes = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePrivacySettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
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
                                  'Kaydediliyor...',
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

                  const SizedBox(height: 20),
                ],
              ),
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

  Widget _buildRadioOption(
    String title,
    String subtitle,
    String value,
    String groupValue,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Radio<String>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: Colors.orange.shade600,
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
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
          ),
        ],
      ),
    );
  }
}