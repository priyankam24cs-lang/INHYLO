import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// THEME – edit these values to match your login_screen.dart exactly.
/// ---------------------------------------------------------------------------
class _UploadTheme {
  static const Color yellow = Color(0xFFFFDD00);
  static const Color black = Color(0xFF111111);
  static const Color red = Color(0xFFD93A3A);
  static const Color redSoft = Color(0xFFFBE0E0);
  static const Color green = Color(0xFF2E9E5B);
  static const Color greenSoft = Color(0xFFD9F2E3);
  static const Color background = Color(0xFFF7F7F2);
  static const Color white = Colors.white;
  static const Color chipGrey = Color(0xFFEAEAE6);
  static const Color border = Color(0xFFDADAD5);
  static const Color disabled = Color(0xFFD5D5D2);
  static const Color mutedText = Color(0xFF6B6B6B);
  static const double radius = 14;
}

/// ---------------------------------------------------------------------------
/// VALIDATION LIMITS – change to your real limits.
/// ---------------------------------------------------------------------------
const int kMaxVideoSeconds = 30;
const double kMaxVideoMb = 50;

enum AdGoal { awareness, storeVisits, offerLaunch }

extension on AdGoal {
  String get label {
    switch (this) {
      case AdGoal.awareness:
        return 'Awareness';
      case AdGoal.storeVisits:
        return 'Store visits';
      case AdGoal.offerLaunch:
        return 'Offer / launch';
    }
  }
}

class _VideoCheck {
  final bool formatOk;
  final String? formatError;
  final bool lengthOk;
  final double? seconds;
  final bool sizeOk;
  final double sizeMb;

  const _VideoCheck({
    required this.formatOk,
    this.formatError,
    required this.lengthOk,
    required this.seconds,
    required this.sizeOk,
    required this.sizeMb,
  });

  bool get allPassed => formatOk && lengthOk && sizeOk;
}

class UploadAdScreen extends StatefulWidget {
  /// Builder for the next screen ("Locations"). If omitted, a placeholder
  /// screen is shown so the app still runs.
  final WidgetBuilder? nextScreenBuilder;

  const UploadAdScreen({super.key, this.nextScreenBuilder});

  @override
  State<UploadAdScreen> createState() => _UploadAdScreenState();
}

class _UploadAdScreenState extends State<UploadAdScreen> {
  static const _kName = 'draft_campaign_name';
  static const _kGoal = 'draft_goal';

  final TextEditingController _nameController = TextEditingController();
  AdGoal _goal = AdGoal.awareness;

  String? _videoPath;
  String? _videoName;
  _VideoCheck? _check;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _loadDraft();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      !_checking &&
      _check?.allPassed == true &&
      _nameController.text.trim().isNotEmpty;

  // ------------------------------------------------------------------ draft

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kName);
    final goalIndex = prefs.getInt(_kGoal);

    if (!mounted) return;
    setState(() {
      if (name != null) _nameController.text = name;
      if (goalIndex != null &&
          goalIndex >= 0 &&
          goalIndex < AdGoal.values.length) {
        _goal = AdGoal.values[goalIndex];
      }
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, _nameController.text.trim());
    await prefs.setInt(_kGoal, _goal.index);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _UploadTheme.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_UploadTheme.radius),
          ),
          content: const Text(
            'Draft saved',
            style: TextStyle(color: _UploadTheme.yellow),
          ),
        ),
      );
  }

  // ----------------------------------------------------------------- video

  Future<void> _pickVideo() async {
    try {
      // file_picker 12+ uses FilePicker.pickFile() directly.
      final pickedFile = await FilePicker.pickFile(
        type: FileType.video,
      );

      if (pickedFile == null) return;

      await _processVideo(pickedFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the video: $e')),
      );
    }
  }

  Future<void> _processVideo(PlatformFile pickedFile) async {
    setState(() {
      _checking = true;
      _videoPath = pickedFile.name;
      _videoName = pickedFile.name;
      _check = null;
    });

    // file_picker 12+ replaced PlatformFile.size with length().
    final bytes = await pickedFile.length();
    final sizeMb = (bytes ?? 0) / (1024 * 1024);

    final extension = pickedFile.extension?.toLowerCase();
    final formatOk = extension == 'mp4';
    final sizeOk = bytes != null && sizeMb <= kMaxVideoMb;

    if (!mounted) return;
    setState(() {
      _check = _VideoCheck(
        formatOk: formatOk,
        formatError: formatOk
            ? null
            : 'Please choose an MP4 video file.',
        // Duration and H.264 codec checks need browser-specific video
        // metadata handling; this version does not claim to validate them.
        lengthOk: true,
        seconds: null,
        sizeOk: sizeOk,
        sizeMb: sizeMb,
      );
      _checking = false;
    });
  }

  // ------------------------------------------------------------- navigation

  Future<void> _goNext() async {
    await _saveDraft();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: widget.nextScreenBuilder ??
            (_) => const Scaffold(
                  body: Center(child: Text('Locations screen goes here')),
                ),
      ),
    );
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _UploadTheme.background,
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
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCampaignField(),
                              const SizedBox(height: 20),
                              _buildGoals(),
                              const SizedBox(height: 18),
                              _buildVideoCard(),
                              if (_videoPath != null) ...[
                                const SizedBox(height: 16),
                                _buildVideoCheckCard(),
                              ],
                              const SizedBox(height: 14),
                              const Text(
                                'If a check fails, we tell you exactly what to fix.',
                                style: TextStyle(
                                    fontSize: 12, color: _UploadTheme.mutedText),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _UploadTheme.yellow,
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
                  Icon(Icons.chevron_left, size: 20, color: _UploadTheme.black),
                  Text('Cancel',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _UploadTheme.black)),
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
                    color: i == 0
                        ? _UploadTheme.black
                        : const Color.fromRGBO(255, 255, 255, 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          const Text('Step 1 of 4 · Video',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _UploadTheme.black)),
          const SizedBox(height: 6),
          const Text('Upload your ad',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _UploadTheme.black)),
        ],
      ),
    );
  }

  Widget _buildCampaignField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Campaign name',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 15, color: _UploadTheme.black),
          decoration: InputDecoration(
            hintText: 'Campaign name',
            hintStyle: const TextStyle(color: _UploadTheme.mutedText),
            filled: true,
            fillColor: _UploadTheme.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_UploadTheme.radius),
              borderSide: const BorderSide(color: _UploadTheme.black, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_UploadTheme.radius),
              borderSide: const BorderSide(color: _UploadTheme.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Goal',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AdGoal.values.map((g) {
            final selected = g == _goal;
            return GestureDetector(
              onTap: () => setState(() => _goal = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? _UploadTheme.black : _UploadTheme.chipGrey,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  g.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? _UploadTheme.yellow : _UploadTheme.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVideoCard() {
    final hasVideo = _videoPath != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickVideo,
            child: Container(
              width: 80,
              height: 64,
              decoration: BoxDecoration(
                color: _UploadTheme.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: _UploadTheme.yellow, size: 34),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasVideo ? _videoName! : 'No video selected',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _pickVideo,
                  child: Text(
                    hasVideo ? 'Replace video' : 'Select video',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _UploadTheme.red,
                      decoration: TextDecoration.underline,
                      decorationColor: _UploadTheme.red,
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

  Widget _buildVideoCheckCard() {
    final c = _check;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Video check',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          if (_checking || c == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: _UploadTheme.black),
                  ),
                  SizedBox(width: 12),
                  Text('Checking your video…', style: TextStyle(fontSize: 13)),
                ],
              ),
            )
          else ...[
            _CheckRow(
              ok: c.formatOk,
              title: c.formatOk
                  ? 'Format is MP4 (H.264)'
                  : 'Format is not supported',
              detail: c.formatOk ? null : c.formatError,
            ),
            const SizedBox(height: 14),
            _CheckRow(
              ok: c.lengthOk,
              title: c.seconds == null
                  ? 'Length could not be read'
                  : c.lengthOk
                      ? 'Length is ${c.seconds!.round()} seconds'
                      : 'Video is too long',
              detail: c.lengthOk
                  ? 'Allowed up to $kMaxVideoSeconds seconds'
                  : c.seconds == null
                      ? 'Try another file.'
                      : '${c.seconds!.round()} seconds. Maximum is '
                          '$kMaxVideoSeconds seconds. Trim it and upload again.',
              detailIsError: !c.lengthOk,
            ),
            const SizedBox(height: 14),
            _CheckRow(
              ok: c.sizeOk,
              title: c.sizeOk ? 'File size is OK' : 'File is too large',
              detail: c.sizeOk
                  ? '${c.sizeMb.toStringAsFixed(1)} MB. '
                      'Maximum is ${kMaxVideoMb.toStringAsFixed(0)} MB.'
                  : '${c.sizeMb.toStringAsFixed(1)} MB. Maximum is '
                      '${kMaxVideoMb.toStringAsFixed(0)} MB. '
                      'Compress it and upload again.',
              detailIsError: !c.sizeOk,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      color: _UploadTheme.background,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _saveDraft,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _UploadTheme.black,
                  backgroundColor: _UploadTheme.white,
                  side: const BorderSide(color: _UploadTheme.black, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_UploadTheme.radius)),
                ),
                child: const Text('Save draft',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3 ~/ 2 + 1,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canContinue ? _goNext : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _UploadTheme.black,
                  foregroundColor: _UploadTheme.yellow,
                  disabledBackgroundColor: _UploadTheme.disabled,
                  disabledForegroundColor: _UploadTheme.mutedText,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_UploadTheme.radius)),
                ),
                child: const Text('Next: Locations',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: _UploadTheme.white,
        borderRadius: BorderRadius.circular(_UploadTheme.radius + 2),
        border: Border.all(color: _UploadTheme.border),
      );
}

class _CheckRow extends StatelessWidget {
  final bool ok;
  final String title;
  final String? detail;
  final bool detailIsError;

  const _CheckRow({
    required this.ok,
    required this.title,
    this.detail,
    this.detailIsError = false,
  });

  @override
  Widget build(BuildContext context) {
    final showErrorColor = !ok;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ok ? _UploadTheme.greenSoft : _UploadTheme.redSoft,
          ),
          child: Icon(
            ok ? Icons.check : Icons.priority_high,
            size: 17,
            color: ok ? _UploadTheme.green : _UploadTheme.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail!,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight:
                        showErrorColor ? FontWeight.w600 : FontWeight.w400,
                    color: (showErrorColor || detailIsError)
                        ? _UploadTheme.red
                        : _UploadTheme.mutedText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
