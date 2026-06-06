import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentPage extends StatefulWidget {
  final String serviceName;
  final int amount;

  const PaymentPage({
    super.key,
    required this.serviceName,
    required this.amount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  late Razorpay _razorpay;
  bool isLoading = false;
  String? selectedMethod;

  late AnimationController _shimmerController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() => isLoading = false);
    _showSnackBar('Payment Successful! 🎉', isSuccess: true);
    Navigator.pop(context, true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => isLoading = false);
    _showSnackBar(response.message ?? 'Payment Failed. Please try again.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackBar('Wallet Selected: ${response.walletName}');
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFF00C896) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openCheckout(String method) {
    setState(() {
      isLoading = true;
      selectedMethod = method;
    });

    // Configure allowed payment methods based on selection
    Map<String, dynamic> options = {
      'key': 'rzp_test_Sxslhrz99Bxbpn',
      'amount': widget.amount * 100,
      'name': 'CallMe',
      'description': widget.serviceName,
      'timeout': 300,
      'retry': {
        'enabled': true,
        'max_count': 1,
      },
      'prefill': {
        'contact': '9876543210',
        'email': 'test@example.com',
      },
    };

    // Restrict to only the chosen method
    if (method == 'upi') {
      options['method'] = {
        'upi': true,
        'card': false,
        'netbanking': false,
        'wallet': false,
        'emi': false,
      };
    } else if (method == 'card') {
      options['method'] = {
        'upi': false,
        'card': true,
        'netbanking': false,
        'wallet': false,
        'emi': false,
      };
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _shimmerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Booking Summary Card ──────────────────────────────────
              _BookingSummaryCard(
                serviceName: widget.serviceName,
                amount: widget.amount,
                shimmerController: _shimmerController,
              ),

              const SizedBox(height: 28),

              // ── Section Title ─────────────────────────────────────────
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 14),

              // ── UPI ───────────────────────────────────────────────────
              _PaymentOptionTile(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFF6C47FF),
                iconBg: const Color(0xFFEEE9FF),
                title: 'UPI',
                subtitle: 'Google Pay, PhonePe, Paytm & more',
                badge: 'INSTANT',
                badgeColor: const Color(0xFF00C896),
                isEnabled: true,
                isLoading: isLoading && selectedMethod == 'upi',
                onTap: isLoading ? null : () => _openCheckout('upi'),
              ),

              const SizedBox(height: 12),

              // ── Card ──────────────────────────────────────────────────
              _PaymentOptionTile(
                icon: Icons.credit_card_rounded,
                iconColor: const Color(0xFF0066FF),
                iconBg: const Color(0xFFE0ECFF),
                title: 'Credit / Debit Card',
                subtitle: 'Visa, Mastercard, RuPay',
                badge: 'SECURE',
                badgeColor: const Color(0xFF0066FF),
                isEnabled: true,
                isLoading: isLoading && selectedMethod == 'card',
                onTap: isLoading ? null : () => _openCheckout('card'),
              ),

              const SizedBox(height: 12),

              // ── Offline ───────────────────────────────────────────────
              _PaymentOptionTile(
                icon: Icons.handshake_rounded,
                iconColor: const Color(0xFFFF8C00),
                iconBg: const Color(0xFFFFF0DC),
                title: 'Offline Payment',
                subtitle: 'Pay cash after service completion',
                isEnabled: true,
                onTap: isLoading
                    ? null
                    : () => Navigator.pop(context, 'offline'),
              ),

              const SizedBox(height: 12),

              // ── Net Banking (disabled) ────────────────────────────────
              _PaymentOptionTile(
                icon: Icons.account_balance_rounded,
                iconColor: Colors.grey,
                iconBg: const Color(0xFFF0F0F0),
                title: 'Net Banking',
                subtitle: 'Coming soon',
                isEnabled: false,
                onTap: null,
              ),

              const SizedBox(height: 12),

              // ── Wallets (disabled) ────────────────────────────────────
              _PaymentOptionTile(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: Colors.grey,
                iconBg: const Color(0xFFF0F0F0),
                title: 'Wallets',
                subtitle: 'Coming soon',
                isEnabled: false,
                onTap: null,
              ),

              const SizedBox(height: 24),

              // ── Security Badge ────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB2EDD8)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_rounded,
                        color: Color(0xFF00C896), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All transactions are encrypted and secured by Razorpay',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2D7A5E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking Summary Card with shimmer pulse
// ─────────────────────────────────────────────────────────────────────────────
class _BookingSummaryCard extends StatelessWidget {
  final String serviceName;
  final int amount;
  final AnimationController shimmerController;

  const _BookingSummaryCard({
    required this.serviceName,
    required this.amount,
    required this.shimmerController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        final shimmerValue = shimmerController.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [Color(0xFF6C47FF), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C47FF).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Opacity(
                    opacity: 0.08,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [
                            (shimmerValue - 0.3).clamp(0.0, 1.0),
                            shimmerValue.clamp(0.0, 1.0),
                            (shimmerValue + 0.3).clamp(0.0, 1.0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'BOOKING SUMMARY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    serviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$amount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Option Tile
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentOptionTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    required this.isEnabled,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  State<_PaymentOptionTile> createState() => _PaymentOptionTileState();
}

class _PaymentOptionTileState extends State<_PaymentOptionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _pressController;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.isEnabled && widget.onTap != null
            ? (_) => _pressController.reverse()
            : null,
        onTapUp: widget.isEnabled && widget.onTap != null
            ? (_) {
                _pressController.forward();
                widget.onTap?.call();
              }
            : null,
        onTapCancel: () => _pressController.forward(),
        child: AnimatedOpacity(
          opacity: widget.isEnabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isEnabled
                    ? Colors.transparent
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: widget.isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: widget.isEnabled
                                  ? const Color(0xFF1A1A2E)
                                  : Colors.grey,
                            ),
                          ),
                          if (widget.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    widget.badgeColor!.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.badge!,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: widget.badgeColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                          if (!widget.isEnabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'SOON',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing
                if (widget.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF6C47FF),
                    ),
                  )
                else if (widget.isEnabled)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFB0B7C3),
                    size: 22,
                  )
                else
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.grey,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}