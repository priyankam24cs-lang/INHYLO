import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ---------------------------------------------------------------------------
/// THEME – same values as the other INHYLO screens. Edit to match login_screen.dart.
/// ---------------------------------------------------------------------------
class _ReportsTheme {
  static const Color yellow = Color(0xFFFFDD00);
  static const Color black = Color(0xFF111111);
  static const Color red = Color(0xFFD93A3A);
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF7F7F2);
  static const Color chipGrey = Color(0xFFEAEAE6);
  static const Color track = Color(0xFFEDEDE8);
  static const Color border = Color(0xFFDADAD5);
  static const Color mutedText = Color(0xFF6B6B6B);
  static const double radius = 14;
}

enum ReportRange { sevenDays, thirtyDays, allTime }

extension on ReportRange {
  String get label {
    switch (this) {
      case ReportRange.sevenDays:
        return '7 days';
      case ReportRange.thirtyDays:
        return '30 days';
      case ReportRange.allTime:
        return 'All time';
    }
  }
}

class LocationPlays {
  final String name;
  final double radiusKm;
  final int plays;
  const LocationPlays(this.name, this.radiusKm, this.plays);
}

class ReportData {
  final int counted;
  final int pending;
  final int rejected;

  /// Order: morning, midday, afternoon, evening.
  final List<int> byTimeOfDay;
  final List<LocationPlays> locations;

  const ReportData({
    required this.counted,
    required this.pending,
    required this.rejected,
    required this.byTimeOfDay,
    required this.locations,
  });
}

typedef ReportLoader = Future<ReportData> Function(
    String campaign, ReportRange range);

class ReportsScreen extends StatefulWidget {
  final String brandName;

  /// First entry should be "All campaigns".
  final List<String> campaigns;

  /// Plug in your API here. If null, sample data is shown.
  final ReportLoader? loader;

  /// Called when "Download report" is tapped with the report as CSV text.
  /// If null, the CSV is copied to the clipboard.
  final void Function(String csv)? onDownload;

  final VoidCallback? onHome;
  final VoidCallback? onAccount;

  const ReportsScreen({
    super.key,
    this.brandName = 'Brand name',
    this.campaigns = const ['All campaigns'],
    this.loader,
    this.onDownload,
    this.onHome,
    this.onAccount,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late String _campaign;
  ReportRange _range = ReportRange.sevenDays;

  ReportData? _data;
  bool _loading = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaigns.first;
    _load();
  }

  Future<void> _load() async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loader = widget.loader ?? _sampleLoader;
      final result = await loader(_campaign, _range);
      if (!mounted || id != _requestId) return;
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = 'Could not load the report. Tap to retry.';
        _loading = false;
      });
    }
  }

  // Sample data so the screen works before the backend is connected.
  Future<ReportData> _sampleLoader(String campaign, ReportRange range) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final rnd = Random(campaign.hashCode ^ range.index * 7919);
    final scale = range == ReportRange.sevenDays
        ? 1
        : range == ReportRange.thirtyDays
            ? 4
            : 12;
    int v(int base) => (base + rnd.nextInt(base ~/ 2 + 1)) * scale;
    final byTime = [v(120), v(190), v(140), v(240)];
    final counted = byTime.reduce((a, b) => a + b);
    return ReportData(
      counted: counted,
      pending: v(30),
      rejected: v(12),
      byTimeOfDay: byTime,
      locations: [
        LocationPlays('Location 1', 3, (counted * 0.45).round()),
        LocationPlays('Location 2', 5, (counted * 0.30).round()),
        LocationPlays('Location 3', 2, (counted * 0.17).round()),
      ],
    );
  }

  String _buildCsv(ReportData d) {
    final b = StringBuffer()
      ..writeln('INHYLO report')
      ..writeln('Brand,${widget.brandName}')
      ..writeln('Campaign,$_campaign')
      ..writeln('Period,${_range.label}')
      ..writeln()
      ..writeln('Metric,Value')
      ..writeln('Counted plays,${d.counted}')
      ..writeln('Pending check,${d.pending}')
      ..writeln('Rejected,${d.rejected}')
      ..writeln()
      ..writeln('Time of day,Plays');
    const names = ['Morning', 'Midday', 'Afternoon', 'Evening'];
    for (var i = 0; i < 4; i++) {
      b.writeln('${names[i]},${d.byTimeOfDay[i]}');
    }
    b
      ..writeln()
      ..writeln('Location,Radius (km),Plays');
    for (final l in d.locations) {
      b.writeln('"${l.name}",${_km(l.radiusKm)},${l.plays}');
    }
    return b.toString();
  }

  Future<void> _download() async {
    final d = _data;
    if (d == null) return;
    final csv = _buildCsv(d);
    if (widget.onDownload != null) {
      widget.onDownload!(csv);
      return;
    }
    await Clipboard.setData(ClipboardData(text: csv));
    _toast('Report copied to clipboard');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _ReportsTheme.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_ReportsTheme.radius)),
          content: Text(message,
              style: const TextStyle(color: _ReportsTheme.yellow)),
        ),
      );
  }

  void _nav(VoidCallback? cb) {
    if (cb != null) {
      cb();
    } else {
      _toast('Coming soon');
    }
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ReportsTheme.background,
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
                              _buildCampaignDropdown(),
                              const SizedBox(height: 14),
                              _buildRangeChips(),
                              const SizedBox(height: 14),
                              if (_error != null)
                                _buildError()
                              else ...[
                                _buildStatCards(),
                                const SizedBox(height: 14),
                                _buildTimeOfDayCard(),
                                const SizedBox(height: 14),
                                _buildLocationCard(),
                              ],
                              const SizedBox(height: 14),
                              const Text(
                                'A counted play means the ad played fully on a cab '
                                'tablet and passed our checks. It does not measure '
                                'who watched.',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: _ReportsTheme.mutedText),
                              ),
                              const SizedBox(height: 14),
                              _buildDownloadButton(),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _ReportsTheme.yellow,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3),
                  children: [
                    TextSpan(
                        text: 'IN', style: TextStyle(color: _ReportsTheme.red)),
                    TextSpan(
                        text: 'HYLO',
                        style: TextStyle(color: _ReportsTheme.black)),
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
                      color: _ReportsTheme.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Reports',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _ReportsTheme.black)),
        ],
      ),
    );
  }

  Widget _buildCampaignDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Campaign',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _ReportsTheme.white,
            borderRadius: BorderRadius.circular(_ReportsTheme.radius),
            border: Border.all(color: _ReportsTheme.black, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _campaign,
              isExpanded: true,
              borderRadius: BorderRadius.circular(_ReportsTheme.radius),
              dropdownColor: _ReportsTheme.white,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: _ReportsTheme.black),
              style: const TextStyle(
                  fontSize: 15,
                  color: _ReportsTheme.black,
                  fontWeight: FontWeight.w500),
              items: widget.campaigns
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null || value == _campaign) return;
                setState(() => _campaign = value);
                _load();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ReportRange.values.map((r) {
        final selected = r == _range;
        return GestureDetector(
          onTap: () {
            if (r == _range) return;
            setState(() => _range = r);
            _load();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? _ReportsTheme.black : _ReportsTheme.chipGrey,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              r.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? _ReportsTheme.yellow : _ReportsTheme.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildError() {
    return GestureDetector(
      onTap: _load,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Text(
          _error!,
          style: const TextStyle(
              color: _ReportsTheme.red, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final d = _data;
    final show = d != null && !_loading;
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                value: show ? _fmt(d.counted) : '—', label: 'Counted plays')),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                value: show ? _fmt(d.pending) : '—', label: 'Pending check')),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                value: show ? _fmt(d.rejected) : '—', label: 'Rejected')),
      ],
    );
  }

  Widget _buildTimeOfDayCard() {
    final d = _data;
    final values = (d != null && !_loading) ? d.byTimeOfDay : [0, 0, 0, 0];
    const labels = ['Morning', 'Midday', 'Afternoon', 'Evening'];
    final maxV = values.reduce(max);
    const chartHeight = 100.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plays by time of day',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SizedBox(
            height: chartHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(height: 1, color: _ReportsTheme.border),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(4, (i) {
                    final isTop = maxV > 0 && values[i] == maxV;
                    final h = maxV == 0
                        ? 6.0
                        : max(6.0, chartHeight * values[i] / maxV);
                    return Expanded(
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          width: 46,
                          height: h,
                          decoration: BoxDecoration(
                            color: isTop
                                ? _ReportsTheme.red
                                : _ReportsTheme.black,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: labels
                .map((l) => Expanded(
                      child: Text(l,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 10.5,
                              color: _ReportsTheme.mutedText)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final d = _data;
    final locations = (d != null && !_loading) ? d.locations : <LocationPlays>[];
    final maxPlays = locations.isEmpty
        ? 1
        : max(1, locations.map((l) => l.plays).reduce(max));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plays by location',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_loading && d == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _ReportsTheme.black),
                ),
              ),
            )
          else if (locations.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('No location data yet.',
                  style: TextStyle(
                      fontSize: 12, color: _ReportsTheme.mutedText)),
            )
          else
            for (final l in locations)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l.name} · ${_km(l.radiusKm)} km',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(_fmt(l.plays),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: l.plays / maxPlays),
                        duration: const Duration(milliseconds: 400),
                        builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: _ReportsTheme.track,
                          valueColor: const AlwaysStoppedAnimation(
                              _ReportsTheme.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: (_data == null || _loading) ? null : _download,
        style: OutlinedButton.styleFrom(
          foregroundColor: _ReportsTheme.black,
          backgroundColor: _ReportsTheme.white,
          side: const BorderSide(color: _ReportsTheme.black, width: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_ReportsTheme.radius)),
        ),
        child: const Text('Download report',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: _ReportsTheme.white,
        border: Border(top: BorderSide(color: _ReportsTheme.border)),
      ),
      child: Row(
        children: [
          _navItem('Home', false, widget.onHome),
          _navItem('Reports', true, null),
          _navItem('Account', false, widget.onAccount),
        ],
      ),
    );
  }

  Widget _navItem(String label, bool selected, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: selected ? null : () => _nav(onTap),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _ReportsTheme.yellow : Colors.transparent,
            borderRadius: BorderRadius.circular(_ReportsTheme.radius),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _ReportsTheme.black)),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: _ReportsTheme.white,
        borderRadius: BorderRadius.circular(_ReportsTheme.radius + 2),
        border: Border.all(color: _ReportsTheme.border),
      );
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _ReportsTheme.white,
        borderRadius: BorderRadius.circular(_ReportsTheme.radius + 2),
        border: Border.all(color: _ReportsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _ReportsTheme.black)),
          ),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 2,
              style: const TextStyle(
                  fontSize: 10.5, color: _ReportsTheme.mutedText)),
        ],
      ),
    );
  }
}

String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

String _km(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);