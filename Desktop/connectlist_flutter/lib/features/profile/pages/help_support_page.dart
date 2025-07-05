import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/settings_providers.dart' as settings;

class HelpSupportPage extends ConsumerStatefulWidget {
  const HelpSupportPage({super.key});

  @override
  ConsumerState<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends ConsumerState<HelpSupportPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _deletionReasonController = TextEditingController();
  
  String _selectedCategory = 'general';
  bool _isSubmittingTicket = false;
  bool _isRequestingDeletion = false;

  @override
  void initState() {
    super.initState();
    // Set current user's email
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supabase = ref.read(settings.supabaseProvider);
      final email = supabase.auth.currentUser?.email ?? '';
      _emailController.text = email;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _deletionReasonController.dispose();
    super.dispose();
  }

  Future<void> _submitSupportTicket() async {
    if (_emailController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingTicket = true;
    });

    try {
      final ticketData = {
        'email': _emailController.text.trim(),
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'category': _selectedCategory,
      };

      await ref.read(settings.createSupportTicketProvider(ticketData).future);

      if (mounted) {
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedCategory = 'general';
        });

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
                const Text('Destek talebiniz başarıyla gönderildi'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmittingTicket = false;
      });
    }
  }

  Future<void> _requestAccountDeletion() async {
    final confirmed = await _showAccountDeletionDialog();
    if (!confirmed) return;

    setState(() {
      _isRequestingDeletion = true;
    });

    try {
      final reason = _deletionReasonController.text.trim();
      await ref.read(settings.createAccountDeletionRequestProvider(reason).future);

      if (mounted) {
        _deletionReasonController.clear();
        Navigator.of(context).pop(); // Close dialog if open

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  PhosphorIcons.checkCircle(),
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text('Hesap Silme Talebi Alındı'),
              ],
            ),
            content: const Text(
              'Hesap silme talebiniz alınmıştır. Hesabınız 30 gün sonra kalıcı olarak silinecektir. Bu süre içinde giriş yaparak işlemi iptal edebilirsiniz.',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to settings
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                ),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      setState(() {
        _isRequestingDeletion = false;
      });
    }
  }

  Future<bool> _showAccountDeletionDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              PhosphorIcons.warning(),
              color: Colors.red.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Hesap Silme'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesabınızı silmek istediğinizden emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Tüm listeleriniz silinecek\n'
              '• Profil bilgileriniz silinecek\n'
              '• Bu işlem geri alınamaz\n'
              '• 30 gün sonra kalıcı olarak silinecek',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silme sebebinizi belirtebilirsiniz (isteğe bağlı):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deletionReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Hesabımı neden silmek istiyorum...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hesabımı Sil'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Yardım ve Destek',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            _buildSection(
              'Sık Sorulan Sorular',
              PhosphorIcons.question(),
              [
                _buildFAQItem(
                  'Liste nasıl oluştururum?',
                  'Ana sayfada + butonuna tıklayarak kategori seçin ve öğeleri ekleyin.',
                ),
                _buildFAQItem(
                  'Profilimi nasıl özelleştiririm?',
                  'Profil sayfanızda ayarlar butonuna tıklayarak bilgilerinizi güncelleyebilirsiniz.',
                ),
                _buildFAQItem(
                  'Listelerimi nasıl paylaşırım?',
                  'Liste detay sayfasında paylaş butonunu kullanarak sosyal medyada paylaşabilirsiniz.',
                ),
                _buildFAQItem(
                  'Hesabımı nasıl güvende tutarım?',
                  'Güçlü bir şifre kullanın ve gizlilik ayarlarınızı kontrol edin.',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Contact Support Section
            _buildSection(
              'Destek Ekibiyle İletişim',
              PhosphorIcons.chatCircle(),
              [
                const Text(
                  'Sorununuz FAQ\'lerde yer almıyorsa, destek ekibimizle iletişime geçebilirsiniz:',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 16),
                
                // Category Selection
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(PhosphorIcons.tag()),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('Genel')),
                    DropdownMenuItem(value: 'bug_report', child: Text('Hata Bildirimi')),
                    DropdownMenuItem(value: 'feature_request', child: Text('Özellik İsteği')),
                    DropdownMenuItem(value: 'account_issue', child: Text('Hesap Sorunu')),
                    DropdownMenuItem(value: 'privacy_concern', child: Text('Gizlilik Sorunu')),
                    DropdownMenuItem(value: 'other', child: Text('Diğer')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-posta Adresiniz',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(PhosphorIcons.envelope()),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: 16),
                
                // Subject Field
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Konu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(PhosphorIcons.textT()),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Message Field
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Mesajınız',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Icon(PhosphorIcons.note()),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingTicket ? null : _submitSupportTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmittingTicket
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Gönderiliyor...',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Destek Talebi Gönder',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Danger Zone Section
            _buildSection(
              'Tehlikeli Bölge',
              PhosphorIcons.warning(),
              [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.warning(),
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hesap Silme',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hesabınızı kalıcı olarak silmek istiyorsanız aşağıdaki butonu kullanabilirsiniz. Bu işlem geri alınamaz.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.red.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isRequestingDeletion ? null : _requestAccountDeletion,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade400),
                            foregroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isRequestingDeletion
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('İşleniyor...'),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      PhosphorIcons.trash(),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Hesabımı Sil'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  color: title == 'Tehlikeli Bölge' ? Colors.red.shade600 : Colors.orange.shade600,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: EdgeInsets.zero,
      ),
    );
  }
}