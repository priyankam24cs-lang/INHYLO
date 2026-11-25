
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

class _LocTheme {
  static const Color yellow = Color(0xFFFFDD00);
  static const Color yellowSoft = Color(0xFFFFF3A6);
  static const Color yellowDim = Color.fromRGBO(255, 255, 255, 0.55);
  static const Color black = Color(0xFF111111);
  static const Color red = Color(0xFFD93A3A);
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF7F7F2);
  static const Color border = Color(0xFFDADAD5);
  static const Color mutedText = Color(0xFF6B6B6B);
  static const double radius = 14;
}

const int kMaxLocations = 5;
const double kMinRadiusKm = 0.5;
const double kMaxRadiusKm = 25;
const double kRadiusStepKm = 0.5;
const double kDefaultRadiusKm = 2;

class AdLocation {
  final int id;
  String label;
  final LatLng point;
  double radiusKm;

  AdLocation({
    required this.id,
    required this.label,
    required this.point,
    this.radiusKm = kDefaultRadiusKm,
  });
}

class LocationsScreen extends StatefulWidget {
  final LatLng initialCenter;
  final List<AdLocation> initialLocations;
  final void Function(List<AdLocation> locations)? onNext;
  final WidgetBuilder? nextScreenBuilder;

  const LocationsScreen({
    super.key,
    this.initialCenter = const LatLng(12.9716, 77.5946),
    this.initialLocations = const [],
    this.onNext,
    this.nextScreenBuilder,
  });

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  final List<AdLocation> _locations = [];
  int _nextId = 1;
  int? _selectedId;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();

    for (final location in widget.initialLocations) {
      _locations.add(location);
      if (location.id >= _nextId) {
        _nextId = location.id + 1;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  bool get _canContinue => _locations.isNotEmpty;

  void _toast(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _LocTheme.black,
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: const TextStyle(color: _LocTheme.yellow),
          ),
        ),
      );
  }

  void _addLocation(LatLng point, {String? label}) {
    if (_locations.length >= kMaxLocations) {
      _toast('You can add up to $kMaxLocations locations');
      return;
    }

    final location = AdLocation(
      id: _nextId++,
      label: label ?? 'Location ${_locations.length + 1}',
      point: point,
    );

    setState(() {
      _locations.add(location);
      _selectedId = location.id;
    });
  }

  void _removeLocation(AdLocation location) {
    setState(() {
      _locations.removeWhere((l) => l.id == location.id);

      if (_selectedId == location.id) {
        _selectedId =
            _locations.isEmpty ? null : _locations.last.id;
      }
    });
  }

  void _changeRadius(AdLocation location, double delta) {
    final next = (location.radiusKm + delta)
        .clamp(kMinRadiusKm, kMaxRadiusKm)
        .toDouble();

    if (next == location.radiusKm) return;

    setState(() {
      location.radiusKm = next;
      _selectedId = location.id;
    });
  }

  void _selectLocation(AdLocation location) {
    setState(() => _selectedId = location.id);

    if (_mapReady) {
      _mapController.move(
        location.point,
        _mapController.camera.zoom,
      );
    }
  }

  void _addAtMapCenter() {
    final center = _mapReady
        ? _mapController.camera.center
        : widget.initialCenter;

    final offset = _locations.length * 0.002;

    _addLocation(
      LatLng(
        center.latitude + offset,
        center.longitude + offset,
      ),
    );
  }

  void _search() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _toast('Enter a place name');
      return;
    }

    _toast(
      'Address search is not enabled yet. Tap the map to add a location.',
    );
  }

  void _goNext() {
    if (!_canContinue) return;

    widget.onNext?.call(List.unmodifiable(_locations));

    if (widget.nextScreenBuilder != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: widget.nextScreenBuilder!,
        ),
      );
    } else if (widget.onNext == null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Budget and dates screen goes here'),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LocTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchField(),
                              const SizedBox(height: 14),
                              _buildMap(),
                              const SizedBox(height: 10),
                              const Text(
                                'Tap the map to drop a pin. The red circle shows where your ad can play.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.35,
                                  color: _LocTheme.mutedText,
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_locations.isEmpty)
                                _buildEmptyState()
                              else
                                for (var i = 0;
                                    i < _locations.length;
                                    i++)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12,
                                    ),
                                    child: _buildLocationCard(i),
                                  ),
                              _buildAddButton(),
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
      color: _LocTheme.yellow,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: _LocTheme.black,
                  ),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _LocTheme.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: i == 3 ? 0 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: i <= 1
                        ? _LocTheme.black
                        : _LocTheme.yellowDim,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Step 2 of 4 · Locations',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _LocTheme.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Where should your ad play?',
            style: TextStyle(
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: _LocTheme.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _search(),
      style: const TextStyle(
        fontSize: 15,
        color: _LocTheme.black,
      ),
      decoration: InputDecoration(
        hintText: 'Search address or place',
        hintStyle: const TextStyle(
          color: _LocTheme.mutedText,
        ),
        filled: true,
        fillColor: _LocTheme.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.search,
            color: _LocTheme.black,
          ),
          onPressed: _search,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_LocTheme.radius),
          borderSide: const BorderSide(
            color: _LocTheme.black,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_LocTheme.radius),
          borderSide: const BorderSide(
            color: _LocTheme.black,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final width = MediaQuery.of(context).size.width;
    final height = (width * 0.55).clamp(190.0, 280.0);

    final start = _locations.isNotEmpty
        ? _locations.first.point
        : widget.initialCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_LocTheme.radius + 2),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: _LocTheme.border),
          borderRadius: BorderRadius.circular(
            _LocTheme.radius + 2,
          ),
        ),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: start,
            initialZoom: 13,
            minZoom: 4,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all &
                  ~InteractiveFlag.rotate,
            ),
            onMapReady: () => _mapReady = true,
            onTap: (_, point) => _addLocation(point),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.inhylo.app',
            ),
            CircleLayer(
              circles: [
                for (final location in _locations)
                  CircleMarker(
                    point: location.point,
                    radius: location.radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: _LocTheme.red.withOpacity(
                      location.id == _selectedId ? 0.28 : 0.18,
                    ),
                    borderColor: _LocTheme.red,
                    borderStrokeWidth:
                        location.id == _selectedId ? 2.5 : 1.5,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < _locations.length; i++)
                  Marker(
                    point: _locations[i].point,
                    width: 32,
                    height: 32,
                    child: GestureDetector(
                      onTap: () =>
                          _selectLocation(_locations[i]),
                      child: _NumberBadge(
                        number: i + 1,
                        size: 28,
                        selected:
                            _locations[i].id == _selectedId,
                      ),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: const Text(
        'No locations yet. Tap the map to drop your first pin.',
        style: TextStyle(
          fontSize: 12.5,
          color: _LocTheme.mutedText,
        ),
      ),
    );
  }

  Widget _buildLocationCard(int index) {
    final location = _locations[index];
    final selected = location.id == _selectedId;

    return GestureDetector(
      onTap: () => _selectLocation(location),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: _LocTheme.white,
          borderRadius: BorderRadius.circular(
            _LocTheme.radius + 2,
          ),
          border: Border.all(
            color: selected
                ? _LocTheme.black
                : _LocTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _NumberBadge(
                  number: index + 1,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    location.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeLocation(location),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _LocTheme.red,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Radius',
                  style: TextStyle(
                    fontSize: 12,
                    color: _LocTheme.mutedText,
                  ),
                ),
                const Spacer(),
                _StepButton(
                  icon: Icons.remove,
                  enabled:
                      location.radiusKm > kMinRadiusKm,
                  onTap: () =>
                      _changeRadius(location, -kRadiusStepKm),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    '${_kmText(location.radiusKm)} km',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add,
                  enabled:
                      location.radiusKm < kMaxRadiusKm,
                  onTap: () =>
                      _changeRadius(location, kRadiusStepKm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _addAtMapCenter,
      child: CustomPaint(
        foregroundPainter: _DashedRRectPainter(
          color: _LocTheme.black,
          radius: _LocTheme.radius,
        ),
        child: Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _LocTheme.yellowSoft,
            borderRadius: BorderRadius.circular(
              _LocTheme.radius,
            ),
          ),
          child: const Text(
            '+ Add another location',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: _LocTheme.background,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _LocTheme.black,
                  backgroundColor: _LocTheme.white,
                  side: const BorderSide(
                    color: _LocTheme.black,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _LocTheme.radius,
                    ),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canContinue ? _goNext : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _LocTheme.black,
                  foregroundColor: _LocTheme.yellow,
                  disabledBackgroundColor:
                      const Color(0xFFD5D5D2),
                  disabledForegroundColor:
                      _LocTheme.mutedText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _LocTheme.radius,
                    ),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Next: Budget and dates',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _LocTheme.white,
      borderRadius: BorderRadius.circular(
        _LocTheme.radius + 2,
      ),
      border: Border.all(color: _LocTheme.border),
    );
  }
}

String _kmText(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _NumberBadge extends StatelessWidget {
  final int number;
  final double size;
  final bool selected;

  const _NumberBadge({
    required this.number,
    required this.size,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _LocTheme.red,
        shape: BoxShape.circle,
        border: Border.all(
          color: _LocTheme.white,
          width: selected ? 3 : 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: _LocTheme.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _LocTheme.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _LocTheme.black,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: _LocTheme.black,
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.dash = 6,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final end =
            (distance + dash).clamp(0, metric.length).toDouble();

        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );

        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _DashedRRectPainter old,
  ) {
    return old.color != color || old.radius != radius;
  }
}
