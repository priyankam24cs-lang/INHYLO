
import 'package:flutter/material.dart';

class HyloColors {
  static const yellow = Color(0xFFFFD84D);
  static const black = Color(0xFF171717);
  static const red = Color(0xFFB83232);
}

const String kFont = 'Arial';
enum CampaignStatus { live, inReview, draft }

class Campaign {
  const Campaign({
    required this.name,
    required this.status,
    this.dateRange = '[START] – [END]',
    this.locationCount = '[N]',
    this.budgetUsed = 0.6,
    this.budgetUsedLabel = '[—]%',
    this.countedPlays = '[—]',
    this.submittedOn = '[DATE]',
  });

  final String name;
  final CampaignStatus status;
  final String dateRange;
  final String locationCount;
  final double budgetUsed;
  final String budgetUsedLabel;
  final String countedPlays;
  final String submittedOn;
}

class HomeStats {
  const HomeStats({
    this.countedPlays = '[—]',
    this.changeVsLastWeek = '[—]%',
    this.spent = '₹ [—]',
    this.pendingCheck = '[—]',
    this.balanceLeft = '₹ [—]',
    this.dailyPlays = const [3, 5, 4, 8, 7, 11, 13],
  });

  final String countedPlays;
  final String changeVsLastWeek;
  final String spent;
  final String pendingCheck;
  final String balanceLeft;
  final List<double> dailyPlays;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.brandName = '[BRAND NAME]',
    this.stats = const HomeStats(),
    this.campaigns = const [
      Campaign(name: '[CAMPAIGN NAME]', status: CampaignStatus.live),
      Campaign(name: '[CAMPAIGN NAME]', status: CampaignStatus.inReview),
      Campaign(name: '[CAMPAIGN NAME]', status: CampaignStatus.draft),
    ],
    this.onNewCampaign,
    this.onCampaignTap,
    this.onContinueDraft,
    this.onNavTap,
  });

  final String brandName;
  final HomeStats stats;
  final List<Campaign> campaigns;
  final VoidCallback? onNewCampaign;
  final void Function(Campaign campaign)? onCampaignTap;
  final void Function(Campaign campaign)? onContinueDraft;
  final void Function(int index)? onNavTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CampaignStatus? _filter;

  List<Campaign> get _visible => _filter == null
      ? widget.campaigns
      : widget.campaigns.where((c) => c.status == _filter).toList();

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                  ..._buildCampaignList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HyloBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (widget.onNavTap != null) {
            widget.onNavTap!(i);
          } else if (i != 0) {
            _snack('${i == 1 ? 'Reports' : 'Account'} screen coming next');
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: HyloColors.yellow,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _HyloWordmark(),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      widget.brandName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: HyloColors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Your campaigns',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: HyloColors.black,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: widget.onNewCampaign ??
                    () => _snack('New campaign flow coming next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HyloColors.black,
                  foregroundColor: HyloColors.yellow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  '+ New campaign',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final s = widget.stats;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Counted plays · last 7 days',
            style: TextStyle(fontSize: 12, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.countedPlays,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                  color: HyloColors.black,
                  height: 1.1,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3E3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${s.changeVsLastWeek} vs last week',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF13663A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(painter: _TrendChartPainter(s.dailyPlays)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(
                      d,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF444444),
                      ),
                    ))
                .toList(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE4E4DE)),
          ),
          Row(
            children: [
              _stat('Spent', s.spent),
              _stat('Pending check', s.pendingCheck),
              _stat('Balance left', s.balanceLeft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF444444))),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: HyloColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final items = <(String, CampaignStatus?)>[
      ('All', null),
      ('Live', CampaignStatus.live),
      ('In review', CampaignStatus.inReview),
      ('Draft', CampaignStatus.draft),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, status) in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: label,
                selected: _filter == status,
                onTap: () => setState(() => _filter = status),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCampaignList() {
    final list = _visible;
    if (list.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'No campaigns here yet',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ),
        ),
      ];
    }

    return [
      for (final c in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CampaignCard(
            campaign: c,
            onTap: () => widget.onCampaignTap?.call(c),
            onContinue: () {
              if (widget.onContinueDraft != null) {
                widget.onContinueDraft!(c);
              } else {
                _snack('Continue draft coming next');
              }
            },
          ),
        ),
    ];
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.onTap,
    required this.onContinue,
  });

  final Campaign campaign;
  final VoidCallback onTap;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      campaign.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: HyloColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: campaign.status),
                ],
              ),
              const SizedBox(height: 8),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    const sub = TextStyle(fontSize: 13, color: Color(0xFF555555));

    switch (campaign.status) {
      case CampaignStatus.live:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${campaign.dateRange} · ${campaign.locationCount} locations',
              style: sub,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: campaign.budgetUsed.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: const Color(0xFFE9E9E3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(HyloColors.black),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget used ${campaign.budgetUsedLabel}', style: sub),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: kFont,
                      fontSize: 13,
                      color: HyloColors.black,
                    ),
                    children: [
                      TextSpan(
                        text: campaign.countedPlays,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' counted plays'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );

      case CampaignStatus.inReview:
        return Text(
          'Submitted ${campaign.submittedOn} · We will notify you after approval',
          style: sub,
        );

      case CampaignStatus.draft:
        return Row(
          children: [
            const Text('Not submitted · ', style: sub),
            GestureDetector(
              onTap: onContinue,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HyloColors.red,
                    decoration: TextDecoration.underline,
                    decorationColor: HyloColors.red,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case CampaignStatus.live:
        label = 'Live';
        bg = const Color(0xFFD8F3E3);
        fg = const Color(0xFF13663A);
      case CampaignStatus.inReview:
        label = 'In review';
        bg = const Color(0xFFFFF0B3);
        fg = const Color(0xFF5A4300);
      case CampaignStatus.draft:
        label = 'Draft';
        bg = const Color(0xFFE6E6E0);
        fg = const Color(0xFF333333);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? HyloColors.black : const Color(0xFFEAEAE4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? HyloColors.yellow : HyloColors.black,
          ),
        ),
      ),
    );
  }
}

class HyloBottomNav extends StatelessWidget {
  const HyloBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _labels = ['Home', 'Reports', 'Account'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E4DE))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              for (var i = 0; i < _labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == currentIndex
                            ? HyloColors.yellow
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _labels[i],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: HyloColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE0E0DA)),
  );
}

class _HyloWordmark extends StatelessWidget {
  const _HyloWordmark();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: kFont,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
        children: [
          TextSpan(text: 'IN', style: TextStyle(color: HyloColors.red)),
          TextSpan(text: 'HYLO', style: TextStyle(color: HyloColors.black)),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV == 0 ? 1 : maxV;

    const topPad = 10.0;
    const sidePad = 8.0;
    final chartH = size.height - topPad;
    final stepX = (size.width - sidePad * 2) / (values.length - 1);

    Offset point(int i) => Offset(
          sidePad + stepX * i,
          topPad + chartH - (values[i] / range) * chartH,
        );

    final gridPaint = Paint()
      ..color = const Color(0xFFD9D9D3)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      gridPaint,
    );

    canvas.drawLine(
      Offset(0, topPad + chartH / 2),
      Offset(size.width, topPad + chartH / 2),
      gridPaint,
    );

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }

    final area = Path.from(line)
      ..lineTo(point(values.length - 1).dx, size.height - 1)
      ..lineTo(point(0).dx, size.height - 1)
      ..close();

    canvas.drawPath(
      area,
      Paint()..color = HyloColors.yellow.withOpacity(0.5),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = HyloColors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      point(values.length - 1),
      5,
      Paint()..color = HyloColors.red,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) =>
      old.values != values;
}
