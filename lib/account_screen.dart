import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// THEME – same values as upload_ad_screen.dart. Edit to match login_screen.dart.
/// ---------------------------------------------------------------------------
class _AccountTheme {
  static const Color yellow = Color(0xFFFFDD00);
  static const Color yellowSoft = Color(0xFFFFF3A6);
  static const Color black = Color(0xFF111111);
  static const Color red = Color(0xFFD93A3A);
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF7F7F2);
  static const Color border = Color(0xFFDADAD5);
  static const Color mutedText = Color(0xFF6B6B6B);
  static const double radius = 14;
}

class AccountScreen extends StatefulWidget {
  final String brandName;
  final String contactName;
  final String phone;

  /// Row callbacks. If null, a "Coming soon" message is shown on tap.
  final VoidCallback? onBrandProfile;
  final VoidCallback? onNotifications;
  final VoidCallback? onPaymentHistory;
  final VoidCallback? onInvoices;
  final VoidCallback? onHelpAndSupport;
  final VoidCallback? onTermsAndAdRules;

  /// Bottom navigation callbacks (Account is the current tab).
  final VoidCallback? onHome;
  final VoidCallback? onReports;

  /// Called after the user confirms "Log out".
  final VoidCallback? onLogout;

  const AccountScreen({
    super.key,
    this.brandName = 'Brand name',
    this.contactName = 'Name',
    this.phone = '+91 00000 00000',
    this.onBrandProfile,
    this.onNotifications,
    this.onPaymentHistory,
    this.onInvoices,
    this.onHelpAndSupport,
    this.onTermsAndAdRules,
    this.onHome,
    this.onReports,
    this.onLogout,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _logoPath;

  Future<void> _pickLogo() async {
    _toast('Logo upload will be available when image storage is connected.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _AccountTheme.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_AccountTheme.radius)),
          content: Text(message,
              style: const TextStyle(color: _AccountTheme.yellow)),
        ),
      );
  }

  void _open(VoidCallback? cb) {
    if (cb != null) {
      cb();
    } else {
      _toast('Coming soon');
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _AccountTheme.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_AccountTheme.radius + 4)),
        title: const Text('Log out?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: _AccountTheme.black)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out',
                style: TextStyle(
                    color: _AccountTheme.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (widget.onLogout != null) {
      widget.onLogout!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AccountTheme.background,
      body: SafeArea(
        bottom: false,
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
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileCard(),
                              _sectionLabel('BRAND'),
                              _menuCard([
                                _MenuItem(
                                  'Brand profile',
                                  'Name, logo, email, GST',
                                  () => _open(widget.onBrandProfile),
                                ),
                                _MenuItem(
                                  'Notifications',
                                  'Approval, payment and campaign updates',
                                  () => _open(widget.onNotifications),
                                ),
                              ]),
                              _sectionLabel('PAYMENTS'),
                              _menuCard([
                                _MenuItem(
                                  'Payment history',
                                  'All payments and receipts',
                                  () => _open(widget.onPaymentHistory),
                                ),
                                _MenuItem(
                                  'Invoices',
                                  'Download GST invoices',
                                  () => _open(widget.onInvoices),
                                ),
                              ]),
                              _sectionLabel('SUPPORT'),
                              _menuCard([
                                _MenuItem(
                                  'Help and support',
                                  'Chat or call us',
                                  () => _open(widget.onHelpAndSupport),
                                ),
                                _MenuItem(
                                  'Terms and ad rules',
                                  null,
                                  () => _open(widget.onTermsAndAdRules),
                                ),
                              ]),
                              const SizedBox(height: 16),
                              _buildLogoutButton(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- header

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _AccountTheme.yellow,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3),
                  children: [
                    TextSpan(
                        text: 'IN',
                        style: TextStyle(color: _AccountTheme.red)),
                    TextSpan(
                        text: 'HYLO',
                        style: TextStyle(color: _AccountTheme.black)),
                  ],
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  widget.brandName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _AccountTheme.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Account',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _AccountTheme.black)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- profile

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickLogo,
            child: CustomPaint(
              foregroundPainter: _logoPath == null
                  ? _DashedRRectPainter(
                      color: _AccountTheme.black,
                      radius: 12,
                    )
                  : null,
              child: Container(
                width: 60,
                height: 60,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _AccountTheme.yellowSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: _AccountTheme.black,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.contactName} · ${widget.phone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: _AccountTheme.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- menus

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: _AccountTheme.mutedText,
        ),
      ),
    );
  }

  Widget _menuCard(List<_MenuItem> items) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: items[i].onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].title,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800)),
                          if (items[i].subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(items[i].subtitle!,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _AccountTheme.mutedText)),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: _AccountTheme.black),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1)
              const Divider(
                  height: 1, thickness: 1, color: _AccountTheme.border),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _confirmLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AccountTheme.red,
          backgroundColor: _AccountTheme.white,
          side: const BorderSide(color: _AccountTheme.red, width: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_AccountTheme.radius)),
        ),
        child: const Text('Log out',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      ),
    );
  }

  // ------------------------------------------------------------ bottom nav

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: _AccountTheme.white,
        border: Border(top: BorderSide(color: _AccountTheme.border)),
      ),
      child: Row(
        children: [
          _navItem('Home', false, widget.onHome),
          _navItem('Reports', false, widget.onReports),
          _navItem('Account', true, null),
        ],
      ),
    );
  }

  Widget _navItem(String label, bool selected, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: selected ? null : () => _open(onTap),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _AccountTheme.yellow : Colors.transparent,
            borderRadius: BorderRadius.circular(_AccountTheme.radius),
          ),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _AccountTheme.black),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: _AccountTheme.white,
        borderRadius: BorderRadius.circular(_AccountTheme.radius + 2),
        border: Border.all(color: _AccountTheme.border),
      );
}

class _MenuItem {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _MenuItem(this.title, this.subtitle, this.onTap);
}

/// Draws the dashed rounded border around the "add logo" box.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.dash = 5,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}