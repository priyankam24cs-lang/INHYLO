import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ---------------------------------------------------------------------------
/// THEME – same values as the other INHYLO screens. Edit to match login_screen.dart.
/// ---------------------------------------------------------------------------
class _SuccessTheme {
  static const Color yellow = Color(0xFFFFDD00);
  static const Color black = Color(0xFF111111);
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF7F7F2);
  static const Color border = Color(0xFFDADAD5);
  static const Color mutedText = Color(0xFF6B6B6B);
  static const double radius = 14;
}

class PaymentSuccessScreen extends StatelessWidget {
  final String campaignName;

  /// Amount paid including GST, in paise.
  final int amountPaise;

  /// e.g. "UPI", "Card", "Net banking".
  final String paidWith;
  final String paymentId;
  final DateTime paidAt;
  final DateTime goLiveDate;

  /// Receives a plain-text receipt. If null, the receipt is copied to the
  /// clipboard.
  final void Function(String receiptText)? onDownloadReceipt;

  /// "Go to my campaigns". If null, the app returns to the first route.
  final VoidCallback? onGoToCampaigns;

  const PaymentSuccessScreen({
    super.key,
    required this.campaignName,
    required this.amountPaise,
    required this.paidWith,
    required this.paymentId,
    required this.paidAt,
    required this.goLiveDate,
    this.onDownloadReceipt,
    this.onGoToCampaigns,
  });

  String _receiptText() => [
        'INHYLO payment receipt',
        '',
        'Campaign: $campaignName',
        'Amount paid: ₹${_rupees(amountPaise)}',
        'Paid with: $paidWith',
        'Payment ID: $paymentId',
        'Date: ${_formatDate(paidAt)}',
        'Goes live on: ${_formatDate(goLiveDate)}',
      ].join('\n');

  Future<void> _download(BuildContext context) async {
    final text = _receiptText();
    if (onDownloadReceipt != null) {
      onDownloadReceipt!(text);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) _toast(context, 'Receipt copied to clipboard');
  }

  Future<void> _copyId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: paymentId));
    if (context.mounted) _toast(context, 'Payment ID copied');
  }

  void _goToCampaigns(BuildContext context) {
    if (onGoToCampaigns != null) {
      onGoToCampaigns!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _SuccessTheme.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_SuccessTheme.radius)),
          content: Text(message,
              style: const TextStyle(color: _SuccessTheme.yellow)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // The payment is done, so the system back button goes to campaigns
    // instead of returning to the Pay screen.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToCampaigns(context);
      },
      child: Scaffold(
        backgroundColor: _SuccessTheme.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                                color: _SuccessTheme.black,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded,
                                size: 56, color: _SuccessTheme.yellow),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Payment successful',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 32,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                color: _SuccessTheme.black),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your ad goes live on ${_formatDate(goLiveDate)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, color: _SuccessTheme.mutedText),
                          ),
                          const SizedBox(height: 28),
                          _buildDetailsCard(context),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _SuccessTheme.white,
        borderRadius: BorderRadius.circular(_SuccessTheme.radius + 2),
        border: Border.all(color: _SuccessTheme.border),
      ),
      child: Column(
        children: [
          _DetailRow(label: 'Campaign', value: campaignName),
          _DetailRow(label: 'Amount paid', value: '₹${_rupees(amountPaise)}'),
          _DetailRow(label: 'Paid with', value: paidWith),
          _DetailRow(
            label: 'Payment ID',
            value: paymentId,
            onTap: () => _copyId(context),
          ),
          _DetailRow(label: 'Date', value: _formatDate(paidAt)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => _download(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _SuccessTheme.black,
                backgroundColor: _SuccessTheme.white,
                side: const BorderSide(color: _SuccessTheme.black, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_SuccessTheme.radius)),
              ),
              child: const Text('Download receipt',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _goToCampaigns(context),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _SuccessTheme.black,
                foregroundColor: _SuccessTheme.yellow,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_SuccessTheme.radius)),
              ),
              child: const Text('Go to my campaigns',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DetailRow({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: _SuccessTheme.mutedText)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _SuccessTheme.black),
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