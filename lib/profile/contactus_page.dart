import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  static const String _phoneNumber = '918668425211'; // WhatsApp: country code + number
  static const String _emailAddress = 'allinone@gmail.com';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── Launch WhatsApp ──────────────────────────────────────────────────────────
  Future<void> _openWhatsApp() async {
    final Uri uri = Uri.parse('https://wa.me/$_phoneNumber');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('Could not open WhatsApp. Please check your installation.');
    }
  }

  // ── Open Email App ───────────────────────────────────────────────────────────
  Future<void> _openEmail() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: _emailAddress,
      query: 'subject=Support Request',
    );
    if (!await launchUrl(uri)) {
      _showSnack('Could not open email app.');
    }
  }

  // ── Send message via WhatsApp with form content ──────────────────────────────
  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String message = _messageController.text.trim();

    final String whatsappText =
        'Hello, I\'m *$name*${email.isNotEmpty ? ' ($email)' : ''}.\n\n$message';

    final Uri uri = Uri.parse(
      'https://wa.me/$_phoneNumber?text=${Uri.encodeComponent(whatsappText)}',
    );

    setState(() => _isSending = false);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback: try email
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: _emailAddress,
        queryParameters: {
          'subject': 'Message from $name',
          'body': message,
        },
      );
      if (!await launchUrl(emailUri)) {
        _showSnack('Could not send message. Please contact us directly.');
        return;
      }
    }

    // Clear form on success
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    _showSnack('Opening WhatsApp to send your message…', success: true);
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          'Contact Us',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'We\'re here to help 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Have questions or need support? Reach out directly via WhatsApp, email, or send us a message below.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick Action Buttons ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: _openWhatsApp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    icon: Icons.email_outlined,
                    label: 'Email Us',
                    color: const Color(0xFF1565C0),
                    onTap: _openEmail,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Info Cards ──────────────────────────────────────────────────
            _infoCard(
              icon: Icons.phone,
              title: 'Phone / WhatsApp',
              value: '+91 86684 25211',
              onTap: _openWhatsApp,
              tapLabel: 'Open WhatsApp',
            ),
            _infoCard(
              icon: Icons.email,
              title: 'Email',
              value: _emailAddress,
              onTap: _openEmail,
              tapLabel: 'Open Email',
            ),
            _infoCard(
              icon: Icons.location_on,
              title: 'Office Address',
              value: 'Mumbai, Maharashtra, India',
            ),

            const SizedBox(height: 24),

            // ── Contact Form ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send us a message',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'We\'ll reply via WhatsApp or email.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _formField(
                      controller: _nameController,
                      label: 'Your Name',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                    ),
                    _formField(
                      controller: _emailController,
                      label: 'Email (Optional)',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final emailRegex =
                            RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        return emailRegex.hasMatch(v.trim())
                            ? null
                            : 'Enter a valid email';
                      },
                    ),
                    _formField(
                      controller: _messageController,
                      label: 'Message',
                      icon: Icons.message_outlined,
                      maxLines: 4,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please write a message' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _isSending ? 'Opening…' : 'Send via WhatsApp',
                          style: const TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    String? tapLabel,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: onTap != null
              ? Border.all(color: Colors.blue.shade50, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(icon, color: Colors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey.shade400),
            ],
          ],
        ),
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
          filled: true,
          fillColor: const Color(0xFFF5F7FB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }
}