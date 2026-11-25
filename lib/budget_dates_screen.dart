import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ---------------------------------------------------------------------------
/// THEME – same values as the other INHYLO screens. Edit to match login_screen.dart.
/// ---------------------------------------------------------------------------
class _BudgetTheme {
  static const Color yellow = Color(0xFFFFDD00);
  static const Color yellowSoft = Color(0xFFFFF3A6);
  static const Color yellowDim = Color.fromRGBO(255, 255, 255, 0.55);
  static const Color black = Color(0xFF111111);
  static const Color red = Color(0xFFD93A3A);
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF7F7F2);
  static const Color chipGrey = Color(0xFFEAEAE6);
  static const Color border = Color(0xFFDADAD5);
  static const Color mutedText = Color(0xFF6B6B6B);
  static const double radius = 14;
}

/// ---------------------------------------------------------------------------
/// PRICING – change to your real rules.
/// ---------------------------------------------------------------------------
const int kMinBudget = 1000; // ₹
const double kCostPerPlay = 2.0; // ₹ per counted play (used for the estimate)
const List<int> kQuickAmounts = [2000, 5000, 10000];

enum AdTimeSlot { allDay, morning, afternoon, evening }

extension on AdTimeSlot {
  String get label {
    switch (this) {
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
}

/// What this screen hands to the next step.
class BudgetPlan {
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final int budget;
  final bool limitDailySpend;
  final AdTimeSlot timeOfDay;
  final int estimatedPlays;

  const BudgetPlan({
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.budget,
    required this.limitDailySpend,
    required this.timeOfDay,
    required this.estimatedPlays,
  });
}

class BudgetDatesScreen extends StatefulWidget {
  /// Number of locations chosen on the previous step (shown in the estimate).
  final int locationCount;

  /// Called with the chosen plan when "Next: Review" is tapped.
  final void Function(BudgetPlan plan)? onNext;

  /// Builder for the next screen ("Review").
  final WidgetBuilder? nextScreenBuilder;

  const BudgetDatesScreen({
    super.key,
    this.locationCount = 1,
    this.onNext,
    this.nextScreenBuilder,
  });

  @override
  State<BudgetDatesScreen> createState() => _BudgetDatesScreenState();
}

class _BudgetDatesScreenState extends State<BudgetDatesScreen> {
  final TextEditingController _budgetController = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  bool _limitDaily = false;
  AdTimeSlot _timeSlot = AdTimeSlot.allDay;

  @override
  void initState() {
    super.initState();
    _budgetController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- values

  int get _budget => int.tryParse(_budgetController.text) ?? 0;
  bool get _budgetOk => _budget >= kMinBudget;
  bool get _datesOk =>
      _start != null && _end != null && !_end!.isBefore(_start!);
  int get _days => _datesOk ? _end!.difference(_start!).inDays + 1 : 0;
  int get _estimatedPlays => (_budget / kCostPerPlay).floor();
  bool get _canContinue => _budgetOk && _datesOk;

  // ----------------------------------------------------------------- dates

  Future<void> _pickDate({required bool isStart}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first = isStart ? today : (_start ?? today);
    final initial = isStart
        ? (_start ?? today)
        : (_end != null && !_end!.isBefore(first) ? _end! : first);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _BudgetTheme.black,
            onPrimary: _BudgetTheme.yellow,
            surface: _BudgetTheme.white,
            onSurface: _BudgetTheme.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _BudgetTheme.black),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  // ------------------------------------------------------------ navigation

  void _goNext() {
    if (!_canContinue) return;
    final plan = BudgetPlan(
      startDate: _start!,
      endDate: _end!,
      days: _days,
      budget: _budget,
      limitDailySpend: _limitDaily,
      timeOfDay: _timeSlot,
      estimatedPlays: _estimatedPlays,
    );
    widget.onNext?.call(plan);
    final builder = widget.nextScreenBuilder;
    if (builder != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: builder));
    } else if (widget.onNext == null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Review screen goes here')),
        ),
      ));
    }
  }

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BudgetTheme.background,
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
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDates(),
                              const SizedBox(height: 18),
                              _buildBudgetField(),
                              const SizedBox(height: 12),
                              _buildQuickAmounts(),
                              const SizedBox(height: 10),
                              _buildBudgetHint(),
                              const SizedBox(height: 18),
                              _buildDailyLimit(),
                              const SizedBox(height: 18),
                              _buildTimeOfDay(),
                              const SizedBox(height: 18),
                              _buildEstimateCard(),
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
      color: _BudgetTheme.yellow,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, size: 20, color: _BudgetTheme.black),
                  Text('Back',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _BudgetTheme.black)),
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
                    color: i <= 2 ? _BudgetTheme.black : _BudgetTheme.yellowDim,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          const Text('Step 3 of 4 · Budget and dates',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _BudgetTheme.black)),
          const SizedBox(height: 6),
          const Text('When and how much?',
              style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: _BudgetTheme.black)),
        ],
      ),
    );
  }

  Widget _buildDates() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _DateField(
            label: 'Start date',
            value: _start,
            onTap: () => _pickDate(isStart: true),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _DateField(
            label: 'End date',
            value: _end,
            onTap: () => _pickDate(isStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Total budget',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _BudgetTheme.black),
          decoration: InputDecoration(
            hintText: 'Amount',
            hintStyle: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _BudgetTheme.mutedText),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 6),
              child: Text('₹',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _BudgetTheme.mutedText)),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: _BudgetTheme.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_BudgetTheme.radius),
              borderSide: const BorderSide(color: _BudgetTheme.black, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_BudgetTheme.radius),
              borderSide: const BorderSide(color: _BudgetTheme.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAmounts() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kQuickAmounts.map((amount) {
        final selected = _budget == amount;
        return GestureDetector(
          onTap: () {
            _budgetController.text = '$amount';
            _budgetController.selection =
                TextSelection.collapsed(offset: _budgetController.text.length);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? _BudgetTheme.black : _BudgetTheme.white,
              borderRadius: BorderRadius.circular(_BudgetTheme.radius),
              border: Border.all(color: _BudgetTheme.black, width: 1.5),
            ),
            child: Text(
              '₹${_inr(amount)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? _BudgetTheme.yellow : _BudgetTheme.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetHint() {
    final tooLow = _budgetController.text.isNotEmpty && !_budgetOk;
    return Text(
      tooLow
          ? 'Minimum budget is ₹${_inr(kMinBudget)}.'
          : 'Minimum budget ₹${_inr(kMinBudget)}. GST is added at payment.',
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: tooLow ? FontWeight.w700 : FontWeight.w400,
        color: tooLow ? _BudgetTheme.red : _BudgetTheme.mutedText,
      ),
    );
  }

  Widget _buildDailyLimit() {
    final perDay = (_datesOk && _budgetOk) ? (_budget / _days).floor() : null;
    return GestureDetector(
      onTap: () => setState(() => _limitDaily = !_limitDaily),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _limitDaily ? _BudgetTheme.black : _BudgetTheme.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _BudgetTheme.black, width: 1.5),
            ),
            child: _limitDaily
                ? const Icon(Icons.check, size: 16, color: _BudgetTheme.yellow)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Limit daily spend',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  _limitDaily && perDay != null
                      ? 'Up to about ₹${_inr(perDay)} per day.'
                      : 'Stops your budget from running out on day one',
                  style: const TextStyle(
                      fontSize: 11.5, color: _BudgetTheme.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOfDay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time of day',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AdTimeSlot.values.map((t) {
            final selected = t == _timeSlot;
            return GestureDetector(
              onTap: () => setState(() => _timeSlot = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? _BudgetTheme.black : _BudgetTheme.chipGrey,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  t.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? _BudgetTheme.yellow : _BudgetTheme.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEstimateCard() {
    final hasPlays = _budgetOk;
    final locs = widget.locationCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: _BudgetTheme.yellowSoft,
        borderRadius: BorderRadius.circular(_BudgetTheme.radius + 2),
        border: Border.all(color: _BudgetTheme.black, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your budget gives about',
              style: TextStyle(fontSize: 12.5, color: _BudgetTheme.black)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hasPlays ? '${_inr(_estimatedPlays)} plays' : '— plays',
              style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: _BudgetTheme.black),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'across $locs ${locs == 1 ? 'location' : 'locations'} over '
            '${_datesOk ? _days : '—'} ${_days == 1 ? 'day' : 'days'}',
            style: const TextStyle(fontSize: 12, color: _BudgetTheme.black),
          ),
          const SizedBox(height: 10),
          const Text(
            'This is an estimate. You only pay for plays that pass our checks.',
            style: TextStyle(fontSize: 11, color: _BudgetTheme.black),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: _BudgetTheme.background,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _BudgetTheme.black,
                  backgroundColor: _BudgetTheme.white,
                  side: const BorderSide(color: _BudgetTheme.black, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_BudgetTheme.radius)),
                ),
                child: const Text('Back',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
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
                  backgroundColor: _BudgetTheme.black,
                  foregroundColor: _BudgetTheme.yellow,
                  disabledBackgroundColor: const Color(0xFFD5D5D2),
                  disabledForegroundColor: _BudgetTheme.mutedText,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_BudgetTheme.radius)),
                ),
                child: const Text('Next: Review',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: _BudgetTheme.white,
              borderRadius: BorderRadius.circular(_BudgetTheme.radius),
              border: Border.all(color: _BudgetTheme.black, width: 1),
            ),
            child: Text(
              value == null ? 'DD/MM/YYYY' : _formatDate(value!),
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: value == null ? FontWeight.w400 : FontWeight.w700,
                color: value == null
                    ? _BudgetTheme.mutedText
                    : _BudgetTheme.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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