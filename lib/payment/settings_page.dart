import 'package:callme/payment/settings_controller.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  final SettingsController _settings = SettingsController.instance;

  late final AnimationController _entranceController;

  static const int _sectionCount = 4; // header, appearance, notifications, account+data
  final List<Animation<double>> _fades = [];
  final List<Animation<Offset>> _slides = [];

  bool _busy = false;

  static const _accent = Color(0xFFB79CE0);

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    for (int i = 0; i < _sectionCount; i++) {
      final start = (i * 0.16).clamp(0.0, 0.8);
      final end = (start + 0.4).clamp(0.0, 1.0);
      final fade = CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
      _fades.add(fade);
      _slides.add(
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(fade),
      );
    }

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF3A3660),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // =====================================================
  // ACTIONS
  // =====================================================

  Future<void> _clearCache() async {
    setState(() => _busy = true);
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await Future.delayed(const Duration(milliseconds: 300));
      _showSnack('Cache cleared.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your CallMe account. This action '
          'cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final email = (user.email ?? '').trim().toLowerCase();

      // Soft-mark the Firestore profile before the auth user is gone, so
      // any Cloud Function / admin view can tell this account was deleted
      // rather than just vanishing.
      if (email.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(email).set(
          {
            'accountDeleted': true,
            'accountDeletedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await user.delete();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnack(
          'Please log out and log back in, then try deleting your account again.',
          isError: true,
        );
      } else {
        _showSnack(e.message ?? 'Could not delete account.', isError: true);
      }
    } catch (e) {
      _showSnack('Could not delete account.', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final double sp = (sw / 390).clamp(0.85, 1.25);
    final double bottomSafePad = mq.viewPadding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121016) : const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22 * sp,
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 24 + bottomSafePad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animatedSection(
                  0,
                  _headerCard(sp, isDark),
                ),
                const SizedBox(height: 24),
                _animatedSection(
                  1,
                  _sectionCard(
                    sp: sp,
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    color: const Color(0xFF7C6FE0),
                    isDark: isDark,
                    child: _themeSelector(sp, isDark),
                  ),
                ),
                const SizedBox(height: 18),
                _animatedSection(
                  2,
                  _sectionCard(
                    sp: sp,
                    title: 'Notifications',
                    icon: Icons.notifications_none_rounded,
                    color: const Color(0xFFE07C9B),
                    isDark: isDark,
                    child: Column(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _settings.notificationsEnabled,
                          builder: (context, value, _) => _switchRow(
                            sp: sp,
                            isDark: isDark,
                            title: 'Push Notifications',
                            subtitle: 'Order updates, offers & alerts',
                            value: value,
                            onChanged: (v) =>
                                _settings.setNotificationsEnabled(v),
                          ),
                        ),
                        Divider(
                          height: 24 * sp,
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade200,
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: _settings.soundEnabled,
                          builder: (context, value, _) => _switchRow(
                            sp: sp,
                            isDark: isDark,
                            title: 'Sound & Vibration',
                            subtitle: 'Play a sound when alerts arrive',
                            value: value,
                            onChanged: (v) => _settings.setSoundEnabled(v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _animatedSection(
                  3,
                  Column(
                    children: [
                      _sectionCard(
                        sp: sp,
                        title: 'Account',
                        icon: Icons.shield_outlined,
                        color: const Color(0xFF4FA0D9),
                        isDark: isDark,
                        child: _actionRow(
                          sp: sp,
                          isDark: isDark,
                          icon: Icons.delete_outline_rounded,
                          title: 'Delete Account',
                          subtitle: 'Permanently remove your account',
                          titleColor: Colors.red,
                          onTap: _confirmDeleteAccount,
                        ),
                      ),
                      SizedBox(height: 18 * sp),
                      _sectionCard(
                        sp: sp,
                        title: 'Storage',
                        icon: Icons.storage_rounded,
                        color: const Color(0xFF56B98C),
                        isDark: isDark,
                        child: _actionRow(
                          sp: sp,
                          isDark: isDark,
                          icon: Icons.cleaning_services_outlined,
                          title: 'Clear Cache',
                          subtitle: 'Free up space used by cached images',
                          onTap: _clearCache,
                        ),
                      ),
                      SizedBox(height: 18 * sp),
                      _versionFooter(sp, isDark),
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

  Widget _animatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fades[index],
      child: SlideTransition(position: _slides[index], child: child),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _headerCard(double sp, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22 * sp),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD6E4FF), Color(0xFFE7D9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB9A6E0).withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52 * sp,
            height: 52 * sp,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.tune_rounded,
                color: const Color(0xFF3A3660), size: 26 * sp),
          ),
          SizedBox(width: 16 * sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize CallMe',
                  style: TextStyle(
                    fontSize: 17 * sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2D2A45),
                  ),
                ),
                SizedBox(height: 4 * sp),
                Text(
                  'Theme, notifications, and account preferences',
                  style: TextStyle(
                    fontSize: 12.5 * sp,
                    color: const Color(0xFF5C5780),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SECTION CARD SHELL
  // =====================================================

  Widget _sectionCard({
    required double sp,
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1922) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34 * sp,
                height: 34 * sp,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18 * sp),
              ),
              SizedBox(width: 10 * sp),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.5 * sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * sp),
          child,
        ],
      ),
    );
  }

  // =====================================================
  // THEME SELECTOR (Light / Dark / System)
  // =====================================================

  Widget _themeSelector(double sp, bool isDark) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _settings.themeMode,
      builder: (context, mode, _) {
        final options = <_ThemeOption>[
          _ThemeOption(ThemeMode.light, 'Light', Icons.light_mode_rounded),
          _ThemeOption(ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
          _ThemeOption(ThemeMode.system, 'System', Icons.brightness_auto_rounded),
        ];

        return Row(
          children: options.map((opt) {
            final selected = mode == opt.mode;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4 * sp),
                child: GestureDetector(
                  onTap: () => _settings.setThemeMode(opt.mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(vertical: 14 * sp),
                    decoration: BoxDecoration(
                      color: selected
                          ? _accent.withOpacity(0.15)
                          : (isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? _accent : Colors.transparent,
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt.icon,
                          size: 20 * sp,
                          color: selected
                              ? _accent
                              : (isDark ? Colors.white70 : Colors.black45),
                        ),
                        SizedBox(height: 6 * sp),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 12 * sp,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? _accent
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // =====================================================
  // SWITCH ROW
  // =====================================================

  Widget _switchRow({
    required double sp,
    required bool isDark,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5 * sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              SizedBox(height: 3 * sp),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12 * sp,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _accent,
        ),
      ],
    );
  }

  // =====================================================
  // ACTION ROW (tap-to-do-something)
  // =====================================================

  Widget _actionRow({
    required double sp,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * sp),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20 * sp,
              color: titleColor ?? (isDark ? Colors.white70 : Colors.black54),
            ),
            SizedBox(width: 12 * sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5 * sp,
                      fontWeight: FontWeight.w600,
                      color: titleColor ??
                          (isDark ? Colors.white : const Color(0xFF111827)),
                    ),
                  ),
                  SizedBox(height: 3 * sp),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12 * sp,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13 * sp,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // VERSION FOOTER
  // =====================================================

  Widget _versionFooter(double sp, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8 * sp),
        child: Text(
          'CallMe · Version 1.0.0',
          style: TextStyle(
            fontSize: 12 * sp,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }
}

class _ThemeOption {
  final ThemeMode mode;
  final String label;
  final IconData icon;
  _ThemeOption(this.mode, this.label, this.icon);
}