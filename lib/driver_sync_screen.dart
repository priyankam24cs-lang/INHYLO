import 'dart:async';

import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// THEME (dark driver app) – edit to match your branding.
/// ---------------------------------------------------------------------------
class _DriverTheme {
  static const Color yellow = Color(0xFFFFDD00);
  static const Color black = Color(0xFF111111);
  static const Color card = Color(0xFF1E1E1E);
  static const Color pill = Color(0xFF262626);
  static const Color white = Colors.white;
  static const Color muted = Color(0xFFA0A0A0);
  static const Color green = Color(0xFF3DDC84);
  static const Color amber = Color(0xFFFFB020);
  static const Color red = Color(0xFFD93A3A);
  static const double radius = 18;
}

/// Everything shown on the screen. Fill this from your backend / local DB.
class DriverSyncData {
  final DateTime? lastSynced;
  final int newAds;
  final int adsReady;
  final int storageMb;
  final int retrying;

  /// Earnings in rupees.
  final int pendingRupees;
  final int approvedRupees;
  final int paidRupees;

  const DriverSyncData({
    required this.lastSynced,
    required this.newAds,
    required this.adsReady,
    required this.storageMb,
    required this.retrying,
    required this.pendingRupees,
    required this.approvedRupees,
    required this.paidRupees,
  });
}

typedef DownloadAll = Future<DriverSyncData> Function(
    ValueChanged<double> onProgress);

class DriverSyncScreen extends StatefulWidget {
  final String driverName;
  final String vehicleNumber;

  /// Loads the current status when the screen opens. Demo data if null.
  final Future<DriverSyncData> Function()? loadData;

  /// Downloads all new ads. Call `onProgress(0.0 .. 1.0)` as it goes and return
  /// the updated data when done. Throw if it fails. Demo if null.
  final DownloadAll? downloadAll;

  /// Emits true/false as the tablet goes online/offline
  /// (e.g. from connectivity_plus). If null, the tablet is shown as online.
  final Stream<bool>? connectivityStream;
  final bool initialOnline;

  final VoidCallback? onEarnings;
  final VoidCallback? onHelp;

  const DriverSyncScreen({
    super.key,
    this.driverName = 'Driver name',
    this.vehicleNumber = '—',
    this.loadData,
    this.downloadAll,
    this.connectivityStream,
    this.initialOnline = true,
    this.onEarnings,
    this.onHelp,
  });

  @override
  State<DriverSyncScreen> createState() => _DriverSyncScreenState();
}

class _DriverSyncScreenState extends State<DriverSyncScreen> {
  DriverSyncData? _data;
  bool _loading = true;
  bool _downloading = false;
  double _progress = 0;
  late bool _online;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _online = widget.initialOnline;
    _connSub = widget.connectivityStream?.listen((v) {
      if (mounted) setState(() => _online = v);
    });
    _load();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------------ data

  Future<void> _load() async {
    try {
      final d = await (widget.loadData ?? _demoLoad)();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Could not load sync status');
    }
  }

  Future<void> _downloadAll() async {
    if (_downloading) return;
    if (!_online) {
      _toast('You are offline. Connect to the internet to download.');
      return;
    }
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    try {
      final d = await (widget.downloadAll ?? _demoDownload)((p) {
        if (mounted) setState(() => _progress = p.clamp(0.0, 1.0).toDouble());
      });
      if (!mounted) return;
      setState(() => _data = d);
      _toast('This tablet is up to date');
    } catch (_) {
      _toast('Download failed. It will retry. Please check your connection.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // Demo data so the screen runs before your backend is connected.
  Future<DriverSyncData> _demoLoad() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return DriverSyncData(
      lastSynced: DateTime.now().subtract(const Duration(hours: 2)),
      newAds: 4,
      adsReady: 18,
      storageMb: 620,
      retrying: 1,
      pendingRupees: 340,
      approvedRupees: 1200,
      paidRupees: 5600,
    );
  }

  Future<DriverSyncData> _demoDownload(ValueChanged<double> onProgress) async {
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress(i / 10);
    }
    final old = _data;
    return DriverSyncData(
      lastSynced: DateTime.now(),
      newAds: 0,
      adsReady: (old?.adsReady ?? 0) + (old?.newAds ?? 0),
      storageMb: (old?.storageMb ?? 0) + 140,
      retrying: 0,
      pendingRupees: old?.pendingRupees ?? 0,
      approvedRupees: old?.approvedRupees ?? 0,
      paidRupees: old?.paidRupees ?? 0,
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _DriverTheme.yellow,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          content: Text(message,
              style: const TextStyle(
                  color: _DriverTheme.black, fontWeight: FontWeight.w700)),
        ),
      );
  }

  void _tab(VoidCallback? cb) {
    if (cb != null) {
      cb();
    } else {
      _toast('Coming soon');
    }
  }

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DriverTheme.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopRow(),
                        const SizedBox(height: 16),
                        Text(widget.driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _DriverTheme.white)),
                        const SizedBox(height: 2),
                        Text('Vehicle ${widget.vehicleNumber}',
                            style: const TextStyle(
                                fontSize: 12, color: _DriverTheme.muted)),
                        const SizedBox(height: 16),
                        _buildDownloadButton(),
                        const SizedBox(height: 16),
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildEarningsCard(),
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

  Widget _buildTopRow() {
    return Row(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.3),
            children: [
              TextSpan(text: 'IN', style: TextStyle(color: _DriverTheme.yellow)),
              TextSpan(text: 'HYLO', style: TextStyle(color: _DriverTheme.white)),
            ],
          ),
        ),
        const Spacer(),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _online ? _DriverTheme.green : _DriverTheme.red,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          _online ? 'Online' : 'Offline',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _online ? _DriverTheme.green : _DriverTheme.red),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    final percent = (_progress * 100).round();
    return Opacity(
      opacity: (!_online && !_downloading) ? 0.55 : 1,
      child: Material(
        color: _DriverTheme.yellow,
        borderRadius: BorderRadius.circular(_DriverTheme.radius + 4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _downloading ? null : _downloadAll,
          child: Container(
            width: double.infinity,
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              children: [
                if (_downloading)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: const Color(0x33000000),
                      valueColor:
                          const AlwaysStoppedAnimation(_DriverTheme.black),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _downloading ? 'DOWNLOADING $percent%' : 'DOWNLOAD ALL',
                          style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: _DriverTheme.black),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _downloading
                            ? 'Keep this tablet on and connected'
                            : _online
                                ? 'Make this tablet up to date'
                                : 'Connect to the internet to download',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _DriverTheme.black),
                      ),
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

  Widget _buildStatusCard() {
    final d = _data;
    final show = d != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: _DriverTheme.card,
        borderRadius: BorderRadius.circular(_DriverTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loading
                ? 'Checking…'
                : (d?.lastSynced == null
                    ? 'Not synced yet'
                    : 'Last synced ${_formatSynced(d!.lastSynced!)}'),
            style: const TextStyle(fontSize: 12.5, color: _DriverTheme.muted),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _Stat(
                      value: show ? '${d.newAds}' : '—', label: 'New ads')),
              Expanded(
                  child: _Stat(
                      value: show ? '${d.adsReady}' : '—', label: 'Ads ready')),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _Stat(
                      value: show ? _formatStorage(d.storageMb) : '—',
                      label: 'Storage used')),
              Expanded(
                  child: _Stat(
                      value: show ? '${d.retrying}' : '—', label: 'Retrying')),
            ],
          ),
          if (show) ...[
            const SizedBox(height: 16),
            if (d.adsReady > 0)
              const Text('Ready for offline playback',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _DriverTheme.green))
            else
              const Text('No ads on this tablet yet. Tap Download all.',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _DriverTheme.amber)),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    final d = _data;
    String money(int? v) => v == null ? '₹ —' : '₹ ${_inr(v)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: _DriverTheme.card,
        borderRadius: BorderRadius.circular(_DriverTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Earnings',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _DriverTheme.white)),
          const SizedBox(height: 10),
          _EarningRow(
              label: 'Pending verification', value: money(d?.pendingRupees)),
          _EarningRow(label: 'Approved', value: money(d?.approvedRupees)),
          _EarningRow(label: 'Paid', value: money(d?.paidRupees)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Row(
        children: [
          _TabPill(label: 'Sync', selected: true, onTap: null),
          const SizedBox(width: 10),
          _TabPill(
              label: 'Earnings',
              selected: false,
              onTap: () => _tab(widget.onEarnings)),
          const SizedBox(width: 10),
          _TabPill(
              label: 'Help',
              selected: false,
              onTap: () => _tab(widget.onHelp)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _DriverTheme.white)),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11.5, color: _DriverTheme.muted)),
      ],
    );
  }
}

class _EarningRow extends StatelessWidget {
  final String label;
  final String value;
  const _EarningRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: _DriverTheme.muted)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _DriverTheme.muted)),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: selected ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _DriverTheme.yellow : _DriverTheme.pill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? _DriverTheme.black : _DriverTheme.white)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- helpers

/// "10:42 AM" for today, "23/11, 10:42 AM" otherwise.
String _formatSynced(DateTime t) {
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final suffix = t.hour < 12 ? 'AM' : 'PM';
  final time = '$hour12:$minute $suffix';
  final now = DateTime.now();
  final sameDay =
      t.year == now.year && t.month == now.month && t.day == now.day;
  if (sameDay) return time;
  final d = t.day.toString().padLeft(2, '0');
  final m = t.month.toString().padLeft(2, '0');
  return '$d/$m, $time';
}

String _formatStorage(int mb) => mb >= 1024
    ? '${(mb / 1024).toStringAsFixed(1)} GB'
    : '$mb MB';

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