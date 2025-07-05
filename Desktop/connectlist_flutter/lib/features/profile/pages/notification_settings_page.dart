import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/settings_providers.dart' as settings;

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _listLikes = true;
  bool _listComments = true;
  bool _newFollowers = true;
  bool _listShares = true;
  bool _weeklyDigest = true;
  bool _productUpdates = false;
  bool _tipsAndTutorials = true;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final notificationSettings = await ref.read(settings.notificationSettingsProvider.future);
      if (notificationSettings != null && mounted) {
        setState(() {
          _emailNotifications = notificationSettings['email_notifications'] ?? true;
          _pushNotifications = notificationSettings['push_notifications'] ?? true;
          _smsNotifications = notificationSettings['sms_notifications'] ?? false;
          _listLikes = notificationSettings['list_likes'] ?? true;
          _listComments = notificationSettings['list_comments'] ?? true;
          _newFollowers = notificationSettings['new_followers'] ?? true;
          _listShares = notificationSettings['list_shares'] ?? true;
          _weeklyDigest = notificationSettings['weekly_digest'] ?? true;
          _productUpdates = notificationSettings['product_updates'] ?? false;
          _tipsAndTutorials = notificationSettings['tips_and_tutorials'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final settingsData = {
        'email_notifications': _emailNotifications,
        'push_notifications': _pushNotifications,
        'sms_notifications': _smsNotifications,
        'list_likes': _listLikes,
        'list_comments': _listComments,
        'new_followers': _newFollowers,
        'list_shares': _listShares,
        'weekly_digest': _weeklyDigest,
        'product_updates': _productUpdates,
        'tips_and_tutorials': _tipsAndTutorials,
      };

      final notifier = ref.read(settings.notificationSettingsNotifierProvider.notifier);
      await notifier.updateNotificationSettings(settingsData);

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
                const Text('Notification settings updated successfully'),
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
          'Bildirim Ayarları',
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
                  // General Notifications Section
                  _buildSection(
                    'Genel Bildirimler',
                    PhosphorIcons.bell(),
                    [
                      _buildSwitchTile(
                        'E-posta Bildirimleri',
                        'E-posta ile bildirim almak istiyorum',
                        _emailNotifications,
                        (value) => setState(() => _emailNotifications = value),
                      ),
                      _buildSwitchTile(
                        'Push Bildirimleri',
                        'Mobil cihazımda push bildirimleri almak istiyorum',
                        _pushNotifications,
                        (value) => setState(() => _pushNotifications = value),
                      ),
                      _buildSwitchTile(
                        'SMS Bildirimleri',
                        'SMS ile bildirim almak istiyorum',
                        _smsNotifications,
                        (value) => setState(() => _smsNotifications = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Activity Notifications Section
                  _buildSection(
                    'Aktivite Bildirimleri',
                    PhosphorIcons.pulse(),
                    [
                      _buildSwitchTile(
                        'Liste Beğenileri',
                        'Listelerim beğenildiğinde bildirim al',
                        _listLikes,
                        (value) => setState(() => _listLikes = value),
                      ),
                      _buildSwitchTile(
                        'Liste Yorumları',
                        'Listelerime yorum yapıldığında bildirim al',
                        _listComments,
                        (value) => setState(() => _listComments = value),
                      ),
                      _buildSwitchTile(
                        'Yeni Takipçiler',
                        'Beni takip etmeye başlayan kişiler için bildirim al',
                        _newFollowers,
                        (value) => setState(() => _newFollowers = value),
                      ),
                      _buildSwitchTile(
                        'Liste Paylaşımları',
                        'Listelerim paylaşıldığında bildirim al',
                        _listShares,
                        (value) => setState(() => _listShares = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Content Notifications Section
                  _buildSection(
                    'İçerik Bildirimleri',
                    PhosphorIcons.newspaper(),
                    [
                      _buildSwitchTile(
                        'Haftalık Özet',
                        'Haftanın en popüler listelerini içeren özet al',
                        _weeklyDigest,
                        (value) => setState(() => _weeklyDigest = value),
                      ),
                      _buildSwitchTile(
                        'Ürün Güncellemeleri',
                        'Yeni özellikler ve güncellemeler hakkında bilgi al',
                        _productUpdates,
                        (value) => setState(() => _productUpdates = value),
                      ),
                      _buildSwitchTile(
                        'İpuçları ve Öğreticiler',
                        'ConnectList\'i daha iyi kullanmak için ipuçları al',
                        _tipsAndTutorials,
                        (value) => setState(() => _tipsAndTutorials = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.info(),
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bildirim ayarlarınızı istediğiniz zaman değiştirebilirsiniz. Bazı güvenlik bildirimleri her zaman gönderilir.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNotificationSettings,
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