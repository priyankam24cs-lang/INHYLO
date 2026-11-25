import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'budget_dates_screen.dart' show AdTimeSlot, BudgetPlan;
import 'locations_screen.dart' show AdLocation;

/// ---------------------------------------------------------------------------
/// THEME – same values as the other INHYLO screens. Edit to match login_screen.dart.
/// ---------------------------------------------------------------------------
class _ReviewTheme {
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

/// Typical review time shown in "What happens next". Change to your real figure.
const int kReviewHours = 24;

class ReviewScreen extends StatefulWidget {
  // Data collected in steps 1-3.
  final String campaignName;
  final String videoFileName;
  final int videoSeconds;
  final List<AdLocation> locations;
  final BudgetPlan plan;

  /// "Edit" buttons. If null, the screen simply goes back one step.
  final VoidCallback? onEditVideo;
  final VoidCallback? onEditLocations;
  final VoidCallback? onEditDatesAndBudget;

  /// Opens your "ad rules and terms" page.
  final VoidCallback? onOpenTerms;

  /// Send the ad to your backend. Throw to show an error message.
  final Future<void> Function()? onSubmit;

  /// Called when the user taps "Done" on the success dialog.
  /// If null, the app returns to the first route.
  final VoidCallback? onDone;

  const ReviewScreen({
    super.key,
    required this.campaignName,
    required this.videoFileName,
    required this.videoSeconds,
    required this.locations,
    required this.plan,
    this.onEditVideo,
    this.onEditLocations,
    this.onEditDatesAndBudget,
    this.onOpenTerms,
    this.onSubmit,
    this.onDone,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _accepted = false;
  bool _submitting = false;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openTerms;
  }

  @override
  void dispose() {
    _termsTap.dispose();
    super.dispose();
  }

  void _openTerms() {
    if (widget.onOpenTerms != null) {
      widget.onOpenTerms!();
    } else {
      _toast('Ad rules and terms coming soon');
    }
  }

  void _edit(VoidCallback? cb) {
    if (cb != null) {
      cb();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _submit() async {
    if (!_accepted || _submitting) return;
    setState(() => _submitting = true);
    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!();
      } else {
        await Future.delayed(const Duration(milliseconds: 800)); // demo only
      }
      if (!mounted) return;
      await _showSuccess();
    } catch (_) {
      _toast('Could not submit your ad. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccess() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _ReviewTheme.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ReviewTheme.radius + 4)),
        title: const Text('Submitted for review',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'We will review your ad, usually within $kReviewHours hours, and '
            'notify you once it is approved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done',
                style: TextStyle(
                    color: _ReviewTheme.black, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _ReviewTheme.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_ReviewTheme.radius)),
          content: Text(message,
              style: const TextStyle(color: _ReviewTheme.yellow)),
        ),
      );
  }

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ReviewTheme.background,
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
                              _buildVideoCard(),
                              const SizedBox(height: 14),
                              _buildLocationsCard(),
                              const SizedBox(height: 14),
                              _buildDatesBudgetCard(),
                              const SizedBox(height: 14),
                              _buildNextCard(),
                              const SizedBox(height: 16),
                              _buildTermsRow(),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _ReviewTheme.yellow,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _submitting ? null : () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, size: 20, color: _ReviewTheme.black),
                  Text('Back',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ReviewTheme.black)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: _ReviewTheme.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          const Text('Step 4 of 4 · Review',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _ReviewTheme.black)),
          const SizedBox(height: 6),
          const Text('Check and submit',
              style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: _ReviewTheme.black)),
        ],
      ),
    );
  }

  Widget _buildVideoCard() {
    return _SectionCard(
      title: 'Video',
      onEdit: () => _edit(widget.onEditVideo),
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 64,
              decoration: BoxDecoration(
                color: _ReviewTheme.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: _ReviewTheme.yellow, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.campaignName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.videoFileName} · ${widget.videoSeconds} sec',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: _ReviewTheme.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsCard() {
    return _SectionCard(
      title: 'Locations',
      onEdit: () => _edit(widget.onEditLocations),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            for (var i = 0; i < widget.locations.length; i++)
              _InfoRow(
                label: '${i + 1} · ${widget.locations[i].label}',
                value: '${_km(widget.locations[i].radiusKm)} km',
                labelIsMuted: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesBudgetCard() {
    final p = widget.plan;
    final perDay = p.days > 0 ? (p.budget / p.days).floor() : 0;
    return _SectionCard(
      title: 'Dates and budget',
      onEdit: () => _edit(widget.onEditDatesAndBudget),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            _InfoRow(
                label: 'Dates',
                value: '${_formatDate(p.startDate)} – ${_formatDate(p.endDate)}'),
            _InfoRow(label: 'Time of day', value: _slotLabel(p.timeOfDay)),
            _InfoRow(
                label: 'Daily limit',
                value: p.limitDailySpend ? '₹${_inr(perDay)} / day' : 'No limit'),
            _InfoRow(label: 'Total budget', value: '₹${_inr(p.budget)}'),
            _InfoRow(
                label: 'Estimated plays',
                value: 'about ${_inr(p.estimatedPlays)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildNextCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: _ReviewTheme.yellowSoft,
        borderRadius: BorderRadius.circular(_ReviewTheme.radius + 2),
        border: Border.all(color: _ReviewTheme.black, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What happens next',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          const _StepRow(
              number: 1,
              title: 'We review your ad',
              subtitle: 'Usually within $kReviewHours hours'),
          const SizedBox(height: 12),
          const _StepRow(
              number: 2,
              title: 'You pay',
              subtitle: 'We will notify you once it is approved'),
          const SizedBox(height: 12),
          const _StepRow(
              number: 3,
              title: 'Your ad goes live',
              subtitle: 'It starts on your start date'),
        ],
      ),
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _accepted = !_accepted),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _accepted ? _ReviewTheme.black : _ReviewTheme.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _ReviewTheme.black, width: 1.5),
            ),
            child: _accepted
                ? const Icon(Icons.check, size: 16, color: _ReviewTheme.yellow)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 12.5, color: _ReviewTheme.black, height: 1.3),
                children: [
                  const TextSpan(text: 'My ad follows the INHYLO '),
                  TextSpan(
                    text: 'ad rules and terms',
                    recognizer: _termsTap,
                    style: const TextStyle(
                      color: _ReviewTheme.red,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: _ReviewTheme.red,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final enabled = _accepted && !_submitting;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: _ReviewTheme.background,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: enabled ? _submit : null,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _ReviewTheme.black,
            foregroundColor: _ReviewTheme.yellow,
            disabledBackgroundColor:
                _submitting ? _ReviewTheme.black : const Color(0xFFD5D5D2),
            disabledForegroundColor:
                _submitting ? _ReviewTheme.yellow : _ReviewTheme.mutedText,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_ReviewTheme.radius)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _ReviewTheme.yellow),
                )
              : const Text('Submit for review',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.onEdit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _ReviewTheme.white,
        borderRadius: BorderRadius.circular(_ReviewTheme.radius + 2),
        border: Border.all(color: _ReviewTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _ReviewTheme.red,
                      decoration: TextDecoration.underline,
                      decorationColor: _ReviewTheme.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool labelIsMuted;

  const _InfoRow({
    required this.label,
    required this.value,
    this.labelIsMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: labelIsMuted
                      ? _ReviewTheme.black
                      : _ReviewTheme.mutedText),
            ),
          ),
          const SizedBox(width: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _ReviewTheme.black)),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;

  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: _ReviewTheme.black, shape: BoxShape.circle),
          child: Text('$number',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _ReviewTheme.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11.5, color: _ReviewTheme.black)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- helpers

String _slotLabel(AdTimeSlot t) {
  switch (t) {
    case AdTimeSlot.allDay:
      return 'All day';
    case AdTimeSlot.morning:
      return 'Morning';
    case AdTimeSlot.afternoon:
      return 'Afternoon';
    case AdTimeSlot.evening:
      return 'Evening';
  }
}

String _km(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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