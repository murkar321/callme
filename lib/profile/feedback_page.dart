import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FeedbackPage
// ─────────────────────────────────────────────────────────────────────────────
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocus = FocusNode();

  int _rating = 0;
  bool _isSending = false;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _brandBlue = Color(0xFF3B5BDB);
  static const Color _bgColor = Color(0xFFF0F4FF);
    
  static const Color _textPrimary = Color(0xFF1A1D2E);
  static const Color _textMuted = Color(0xFF8B92A5);

  static const List<String> _labels = [
    '', 'Terrible', 'Poor', 'Okay', 'Good', 'Excellent',
  ];
  static const List<String> _emojis = ['', '😣', '😕', '😐', '😊', '🤩'];
  static const List<Color> _starColors = [
    Colors.transparent,
    Color(0xFFE53935),
    Color(0xFFFF7043),
    Color(0xFFFFB300),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
  ];

  Color get _accent => _rating > 0 ? _starColors[_rating] : _brandBlue;

  // ── Tags ───────────────────────────────────────────────────────────────────
  final List<String> _tags = [
    '📱 Easy to use',
    '⚡ Fast',
    '💰 Affordable',
    '🤝 Great support',
    '🎨 Nice design',
    '🐛 Has bugs',
    '🔧 Needs work',
  ];
  final Set<int> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _textFocus.addListener(() {
      // Scroll so text field is visible above keyboard
      if (_textFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _onStarTap(int star) {
    HapticFeedback.lightImpact();
    setState(() => _rating = star);
  }

  void _onTagTap(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTags.contains(index)) {
        _selectedTags.remove(index);
      } else {
        _selectedTags.add(index);
        final cur = _controller.text;
        _controller.text =
            cur.isEmpty ? _tags[index] : '$cur, ${_tags[index]}';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    });
  }

  Future<void> _send() async {
    if (_rating == 0) {
      _snack('Please select a rating first');
      return;
    }
    if (_controller.text.trim().isEmpty) {
      _snack('Please write some feedback');
      return;
    }

    setState(() => _isSending = true);

    final msg = '''
${'⭐' * _rating} CallMe Feedback

Rating: $_rating/5 – ${_labels[_rating]} ${_emojis[_rating]}

${_controller.text.trim()}
''';

    final uri = Uri.parse(
        'https://wa.me/918668425211?text=${Uri.encodeComponent(msg)}');

    setState(() => _isSending = false);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _controller.clear();
      setState(() {
        _rating = 0;
        _selectedTags.clear();
      });
      _snack('Opening WhatsApp…', ok: true);
    } else {
      _snack('WhatsApp is not installed');
    }
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      // Lets the Scaffold resize content when keyboard appears
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _Header(accent: _accent, onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RatingCard(
                      rating: _rating,
                      accent: _accent,
                      labels: _labels,
                      emojis: _emojis,
                      starColors: _starColors,
                      onTap: _onStarTap,
                    ),
                    if (_rating > 0) ...[
                      const SizedBox(height: 16),
                      _TagSection(
                        tags: _tags,
                        selected: _selectedTags,
                        accent: _accent,
                        onTap: _onTagTap,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _FeedbackField(
                      controller: _controller,
                      focusNode: _textFocus,
                      accent: _accent,
                    ),
                    const SizedBox(height: 24),
                    _SendButton(
                      accent: _accent,
                      isSending: _isSending,
                      onTap: _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Color accent;
  final VoidCallback onBack;

  const _Header({required this.accent, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button — min 44×44 touch target
          SizedBox(
            width: 44,
            height: 44,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onBack,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Share Your\nExperience',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your feedback helps us build better.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Rating Card
// ─────────────────────────────────────────────────────────────────────────────
class _RatingCard extends StatelessWidget {
  final int rating;
  final Color accent;
  final List<String> labels;
  final List<String> emojis;
  final List<Color> starColors;
  final ValueChanged<int> onTap;

  const _RatingCard({
    required this.rating,
    required this.accent,
    required this.labels,
    required this.emojis,
    required this.starColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          const Text(
            'How would you rate CallMe?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _FeedbackPageState._textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final int s = i + 1;
              final bool filled = s <= rating;
              return GestureDetector(
                onTap: () => onTap(s),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: AnimatedScale(
                      scale: filled ? 1.18 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 40,
                        color: filled
                            ? const Color(0xFFFFB300)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: rating > 0
                ? _RatingPill(
                    key: ValueKey(rating),
                    label: '${emojis[rating]}  ${labels[rating]}',
                    color: starColors[rating],
                  )
                : Text(
                    'Tap a star to rate',
                    key: const ValueKey('empty'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final String label;
  final Color color;

  const _RatingPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tag Section
// ─────────────────────────────────────────────────────────────────────────────
class _TagSection extends StatelessWidget {
  final List<String> tags;
  final Set<int> selected;
  final Color accent;
  final ValueChanged<int> onTap;

  const _TagSection({
    required this.tags,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'What stood out?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _FeedbackPageState._textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(tags.length, (i) {
            final sel = selected.contains(i);
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? accent.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: sel ? accent : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  tags[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? accent : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Feedback Text Field
// ─────────────────────────────────────────────────────────────────────────────
class _FeedbackField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accent;

  const _FeedbackField({
    required this.controller,
    required this.focusNode,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: accent, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Your Feedback',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _FeedbackPageState._textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 5,
            minLines: 4,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: _FeedbackPageState._textPrimary,
            ),
            decoration: InputDecoration(
              hintText:
                  'Tell us what you liked or what can be improved…',
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13, height: 1.5),
              filled: true,
              fillColor: const Color(0xFFF4F6FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accent, width: 1.8),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Send Button
// ─────────────────────────────────────────────────────────────────────────────
class _SendButton extends StatelessWidget {
  final Color accent;
  final bool isSending;
  final VoidCallback onTap;

  const _SendButton({
    required this.accent,
    required this.isSending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      height: 56,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isSending ? null : onTap,
          child: Center(
            child: isSending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _WhatsAppIcon(size: 22, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Send via WhatsApp',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WhatsApp Icon  (custom painter — no external package needed)
// ─────────────────────────────────────────────────────────────────────────────
class _WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _WhatsAppIcon({this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppPainter(color: color),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  final Color color;
  const _WhatsAppPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;

    // White phone handset drawn via SVG-style path, no circle background
    // (button itself is colored, so icon is white)
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Scale factor: path designed in a 24×24 grid
    final double sc = s / 24.0;
    canvas.save();
    canvas.scale(sc, sc);

    // WhatsApp-style phone handset path (24×24 grid)
    final Path path = Path();
    path.moveTo(6.6, 10.8);
    path.cubicTo(7.8, 13.4, 10.0, 15.6, 12.6, 16.8);
    path.lineTo(14.2, 15.2);
    path.cubicTo(14.4, 15.0, 14.7, 14.95, 14.95, 15.1);
    path.cubicTo(15.8, 15.4, 16.7, 15.55, 17.6, 15.55);
    path.cubicTo(18.15, 15.55, 18.6, 16.0, 18.6, 16.55);
    path.lineTo(18.6, 18.6);
    path.cubicTo(18.6, 19.15, 18.15, 19.6, 17.6, 19.6);
    path.cubicTo(9.76, 19.6, 3.4, 13.24, 3.4, 5.4);
    path.cubicTo(3.4, 4.85, 3.85, 4.4, 4.4, 4.4);
    path.lineTo(6.45, 4.4);
    path.cubicTo(7.0, 4.4, 7.45, 4.85, 7.45, 5.4);
    path.cubicTo(7.45, 6.3, 7.6, 7.2, 7.9, 8.05);
    path.cubicTo(8.05, 8.3, 8.0, 8.6, 7.8, 8.8);
    path.close();

    canvas.drawPath(path, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WhatsAppPainter old) => old.color != color;
}