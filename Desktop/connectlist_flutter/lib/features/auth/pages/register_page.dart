import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/terms_checkbox.dart';
import 'email_verification_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _privacyPolicyAccepted = false;
  bool _termsAccepted = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_privacyPolicyAccepted || !_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Privacy Policy and Terms of Service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(currentUserProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Handle specific error messages
        if (errorMessage.contains('Username already taken')) {
          errorMessage = 'This username is already taken. Please choose another one.';
        } else if (errorMessage.contains('User already registered')) {
          errorMessage = 'This email address is already registered. Please use a different email or try logging in.';
        } else if (errorMessage.contains('email')) {
          errorMessage = 'Please check your email address and try again.';
        } else if (errorMessage.contains('password')) {
          errorMessage = 'Password must be at least 8 characters long.';
        }
        
        IconData errorIcon = Icons.error_outline;
        
        if (errorMessage.contains('username')) {
          errorIcon = Icons.person_outline;
        } else if (errorMessage.contains('email')) {
          errorIcon = Icons.email_outlined;
        } else if (errorMessage.contains('password')) {
          errorIcon = Icons.lock_outline;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  errorIcon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Privacy Policy',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Text(
                  '''Privacy Policy

Last updated: ${DateTime.now().year}

ConnectList ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.

Information We Collect

Personal Information
- Name and contact information
- Email address and phone number
- Profile information and preferences
- Account credentials

Usage Information
- App usage statistics
- Device information
- Location data (with permission)
- Interaction patterns

How We Use Your Information

We use the information we collect to:
- Provide and maintain our services
- Improve user experience
- Send important notifications
- Ensure platform security
- Analyze usage patterns

Information Sharing

We do not sell, trade, or rent your personal information to third parties. We may share information in these circumstances:
- With your explicit consent
- To comply with legal obligations
- To protect our rights and safety
- With trusted service providers

Data Security

We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

Your Rights

You have the right to:
- Access your personal information
- Correct inaccurate data
- Delete your account and data
- Opt-out of communications
- Export your data

Contact Us

If you have questions about this Privacy Policy, please contact us at:
Email: privacy@connectlist.com
Address: Merkez, Abide-i Hürriyet Cd No:211, 34381 Şişli/İstanbul

Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.''',
                  style: GoogleFonts.inter(fontSize: 14, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Terms of Service',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Text(
                  '''Terms of Service

Last updated: ${DateTime.now().year}

Welcome to ConnectList. These Terms of Service ("Terms") govern your use of our mobile application and services operated by ConnectList ("we," "us," or "our").

Acceptance of Terms

By accessing and using ConnectList, you accept and agree to be bound by the terms and provision of this agreement.

Use License

Permission is granted to temporarily use ConnectList for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:
- Modify or copy the materials
- Use the materials for commercial purposes
- Attempt to reverse engineer any software
- Remove any copyright or proprietary notations

User Accounts

When you create an account with us, you must provide accurate, complete, and current information. You are responsible for:
- Safeguarding your account credentials
- All activities under your account
- Notifying us of unauthorized use

User Content

You retain rights to content you submit, post or display on ConnectList. By posting content, you grant us a worldwide, non-exclusive, royalty-free license to use, modify, and distribute your content.

Prohibited Uses

You may not use ConnectList:
- For unlawful purposes or to solicit unlawful acts
- To violate any international, federal, provincial, or state regulations or laws
- To transmit or procure sending of advertising or promotional material
- To impersonate another person or entity
- To upload viruses or malicious code

Termination

We may terminate or suspend your account immediately, without prior notice, for any reason, including but not limited to breach of the Terms.

Disclaimer

The information on ConnectList is provided on an "as is" basis. We disclaim all warranties, whether express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose.

Limitations

In no event shall ConnectList or its suppliers be liable for any damages arising out of the use or inability to use the materials on ConnectList.

Revisions

We may revise these Terms at any time without notice. By using ConnectList, you agree to be bound by the current version of these Terms.

Contact Information

If you have any questions about these Terms, please contact us at:
Email: support@connectlist.com
Address: Merkez, Abide-i Hürriyet Cd No:211, 34381 Şişli/İstanbul''',
                  style: GoogleFonts.inter(fontSize: 14, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AuthHeader(
                      title: 'Create Account',
                      subtitle: 'Join ConnectList and start creating lists',
                    ),
                    const SizedBox(height: 40),
                    
                    // Username Field
                    AuthTextField(
                      label: 'Username',
                      hint: 'Choose a unique username',
                      controller: _usernameController,
                      prefixIcon: PhosphorIcons.at(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return 'Username can only contain letters, numbers, and underscores';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Full Name Field
                    AuthTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _fullNameController,
                      prefixIcon: PhosphorIcons.user(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Field
                    AuthTextField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: PhosphorIcons.envelope(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    AuthTextField(
                      label: 'Password',
                      hint: 'Create a strong password',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: PhosphorIcons.lock(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Privacy Policy Checkbox
                    TermsCheckbox(
                      value: _privacyPolicyAccepted,
                      onChanged: (value) {
                        setState(() {
                          _privacyPolicyAccepted = value ?? false;
                        });
                      },
                      text: 'I have read and accept the ',
                      linkText: 'Privacy Policy',
                      onLinkTap: _showPrivacyPolicy,
                    ),
                    const SizedBox(height: 12),
                    
                    // Terms of Service Checkbox
                    TermsCheckbox(
                      value: _termsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                      text: 'I agree to the ',
                      linkText: 'Terms of Service',
                      onLinkTap: _showTermsOfService,
                    ),
                    const SizedBox(height: 24),
                    
                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Create Account',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Login',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.orange.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}