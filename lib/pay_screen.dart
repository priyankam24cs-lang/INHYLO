import 'package:flutter/material.dart';

import 'payment_success_screen.dart';

/// ---------------------------------------------------------------------------
/// THEME – same values as the other INHYLO screens. Edit to match login_screen.dart.
/// ---------------------------------------------------------------------------
class _PayTheme {
  static const Color yellow = Color(0xFFFFDD00);
  static const Color black = Color(0xFF111111);
  static const Color red = Color(0xFFD93A3A);
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF7F7F2);
  static const Color border = Color(0xFFDADAD5);
  static const Color mutedText = Color(0xFF6B6B6B);
  static const Color greenSoft = Color(0xFFD9F2E3);
  static const Color greenDark = Color(0xFF1E6B3E);
  static const double radius = 14;
}

/// GST rate in percent. Change if your rate differs.
const int kGstPercent = 18;

enum PayMethod { upi, card, netBanking }

enum UnspentPolicy { refunded, keptAsBalance }

/// What your payment gateway returns to the Pay screen.
class PaymentResult {
  final bool success;
  final String? paymentId;

  const PaymentResult.success(String this.paymentId) : success = true;
  const PaymentResult.failed()
      : success = false,
        paymentId = null;
}

extension on PayMethod {
  String get title {
    switch (this) {
      case PayMethod.upi:
        return 'UPI';
      case PayMethod.card:
        return 'Card';
      case PayMethod.netBanking:
        return 'Net banking';
    }
  }

  String get subtitle {
    switch (this) {
      case PayMethod.upi:
        return 'Google Pay, PhonePe, Paytm and more';
      case PayMethod.card:
        return 'Debit or credit card';
      case PayMethod.netBanking:
        return 'Pay from your bank';
    }
  }
}

class PayScreen extends StatefulWidget {
  final String campaignName;
  final DateTime startDate;
  final DateTime endDate;
  final int locationCount;

  /// Campaign budget in rupees (before GST).
  final int budget;
  final int gstPercent;

  /// What happens to money the ad doesn't spend.
  final UnspentPolicy unspentPolicy;

  /// Start the real payment (e.g. with Razorpay). [totalPaise] is the amount
  /// including GST, in paise. Return PaymentResult.success(paymentId) when
  /// paid, or PaymentResult.failed() if cancelled. You may also throw to show
  /// an error. If null, a demo payment succeeds after a short delay.
  final Future<PaymentResult> Function(PayMethod method, int totalPaise)? onPay;

  /// "Go to my campaigns" on the success screen.
  /// If null, the app returns to the first route.
  final VoidCallback? onPaid;

  /// "Download receipt" on the success screen (receives the receipt text).
  /// If null, the receipt is copied to the clipboard.
  final void Function(String receiptText)? onDownloadReceipt;

  const PayScreen({
    super.key,
    required this.campaignName,
    required this.startDate,
    required this.endDate,
    required this.locationCount,
    required this.budget,
    this.gstPercent = kGstPercent,
    this.unspentPolicy = UnspentPolicy.refunded,
    this.onPay,
    this.onPaid,
    this.onDownloadReceipt,
  });

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  PayMethod _method = PayMethod.upi;
  bool _paying = false;

  // All money maths in paise to avoid rounding errors.
  int get _budgetPaise => widget.budget * 100;
  int get _gstPaise => widget.budget * widget.gstPercent; // budget*100*pct/100
  int get _totalPaise => _budgetPaise + _gstPaise;

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      final result = widget.onPay != null
          ? await widget.onPay!(_method, _totalPaise)
          : await Future.delayed(
              const Duration(milliseconds: 900),
              () => PaymentResult.success(
                  'demo_${DateTime.now().millisecondsSinceEpoch}'), // demo only
            );
      if (!mounted) return;
      if (result.success) {
        _showSuccess(result.paymentId ?? '—');
      } else {
        _toast('Payment was not completed. You have not been charged.');
      }
    } catch (_) {
      _toast('Payment failed. Please try again.');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _showSuccess(String paymentId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          campaignName: widget.campaignName,
          amountPaise: _totalPaise,
          paidWith: _method.title,
          paymentId: paymentId,
          paidAt: DateTime.now(),
          goLiveDate: widget.startDate,
          onDownloadReceipt: widget.onDownloadReceipt,
          onGoToCampaigns: widget.onPaid,
        ),
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _PayTheme.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_PayTheme.radius)),
          content:
              Text(message, style: const TextStyle(color: _PayTheme.yellow)),
        ),
      );
  }

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_paying,
      child: Scaffold(
        backgroundColor: _PayTheme.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildApprovedBanner(),
                                const SizedBox(height: 14),
                                _buildCampaignCard(),
                                const SizedBox(height: 14),
                                _buildPriceCard(),
                                const SizedBox(height: 18),
                                const Text('Pay with',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 10),
                                for (final m in PayMethod.values)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _MethodTile(
                                      method: m,
                                      selected: m == _method,
                                      onTap: _paying
                                          ? null
                                          : () => setState(() => _method = m),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Secure payment. Your ad goes live on '
                                  '${_formatDate(widget.startDate)} after payment. '
                                  'Unspent budget: ${_unspentText()}.',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      height: 1.35,
                                      color: _PayTheme.mutedText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _unspentText() => widget.unspentPolicy == UnspentPolicy.refunded
      ? 'refunded'
      : 'kept as balance';

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _PayTheme.yellow,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _paying ? null : () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, size: 20, color: _PayTheme.black),
                  Text('Back',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _PayTheme.black)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Pay to go live',
              style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: _PayTheme.black)),
        ],
      ),
    );
  }

  Widget _buildApprovedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _PayTheme.greenSoft,
        borderRadius: BorderRadius.circular(_PayTheme.radius),
      ),
      child: const Text('Your ad is approved',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _PayTheme.greenDark)),
    );
  }

  Widget _buildCampaignCard() {
    final n = widget.locationCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.campaignName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(widget.startDate)} – ${_formatDate(widget.endDate)}'
            ' · $n ${n == 1 ? 'location' : 'locations'}',
            style:
                const TextStyle(fontSize: 11.5, color: _PayTheme.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _PriceRow(label: 'Campaign budget', value: '₹${_rupees(_budgetPaise)}'),
          const SizedBox(height: 8),
          _PriceRow(
              label: 'GST (${widget.gstPercent}%)',
              value: '₹${_rupees(_gstPaise)}'),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: _PayTheme.border),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Total to pay',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('₹${_rupees(_totalPaise)}',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: _PayTheme.black)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: _PayTheme.background,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _paying ? null : _pay,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _PayTheme.black,
            foregroundColor: _PayTheme.yellow,
            disabledBackgroundColor: _PayTheme.black,
            disabledForegroundColor: _PayTheme.yellow,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_PayTheme.radius)),
          ),
          child: _paying
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _PayTheme.yellow),
                )
              : Text('Pay ₹${_rupees(_totalPaise)}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: _PayTheme.white,
        borderRadius: BorderRadius.circular(_PayTheme.radius + 2),
        border: Border.all(color: _PayTheme.border),
      );
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 12.5, color: _PayTheme.mutedText)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _PayTheme.black)),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final PayMethod method;
  final bool selected;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _PayTheme.white,
          borderRadius: BorderRadius.circular(_PayTheme.radius + 2),
          border: Border.all(
            color: selected ? _PayTheme.black : _PayTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _PayTheme.white,
                border: Border.all(
                  color: selected ? _PayTheme.black : _PayTheme.mutedText,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                            color: _PayTheme.black, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(method.subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: _PayTheme.mutedText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- helpers

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Paise -> "12,34,567" or "1,180.50" (decimals only when needed).
String _rupees(int paise) {
  final whole = paise ~/ 100;
  final frac = paise % 100;
  final w = _inr(whole);
  return frac == 0 ? w : '$w.${frac.toString().padLeft(2, '0')}';
}

/// Indian digit grouping: 1234567 -> 12,34,567
String _inr(int n) {
  final s = n.abs().toString();
  if (s.length <= 3) return n < 0 ? '-$s' : s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  final out = '${parts.join(',')},$last3';
  return n < 0 ? '-$out' : out;
}