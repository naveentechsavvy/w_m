import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

/// Preset interests: emoji + label. Only the LABEL is saved to
/// Firestore (users/{uid}.interests), the same format the website uses.
const List<(String, String)> kInterestOptions = [
  ('🌙', 'Late night walks'),
  ('🎬', 'Matinee shows'),
  ('🎤', 'Concerts'),
  ('🎸', 'Live music'),
  ('😂', 'Stand-up comedy'),
  ('🍔', 'Food'),
  ('🌮', 'Street food'),
  ('☕', 'Cafe hopping'),
  ('🥾', 'Trekking'),
  ('🚗', 'Road trips'),
  ('🏍️', 'Bike rides'),
  ('🌅', 'Sunrise rides'),
  ('🚴', 'Cycling'),
  ('🏕️', 'Camping'),
  ('🏖️', 'Beach outings'),
  ('🏏', 'Cricket'),
  ('⚽', 'Football'),
  ('🏸', 'Badminton'),
  ('💪', 'Gym & fitness'),
  ('🧘', 'Yoga'),
  ('💃', 'Dance'),
  ('🎶', 'Karaoke'),
  ('🎲', 'Board games'),
  ('🎮', 'Gaming'),
  ('📸', 'Photography'),
  ('🎨', 'Art & painting'),
  ('📚', 'Book club'),
  ('🍳', 'Cooking'),
  ('🛍️', 'Shopping'),
  ('🐶', 'Pet meetups'),
  ('🤝', 'Volunteering'),
];

const int kMinInterests = 3;
const int kMaxCustomInterestLength = 30;
const String kPickMoreInterestsMessage = 'Please pick at least 3 interests.';

/// Emoji for a preset label, or ✨ for a custom one.
String interestEmoji(String label) {
  final lower = label.toLowerCase();
  for (final o in kInterestOptions) {
    if (o.$2.toLowerCase() == lower) return o.$1;
  }
  return '✨';
}

bool _isPreset(String label) =>
    kInterestOptions.any((o) => o.$2.toLowerCase() == label.toLowerCase());

/// Reads users/{uid}.interests safely (list of strings, anything else
/// ignored).
List<String> parseInterests(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Tap-to-select interest chips + "type your own" field + counter.
/// Reports the selected labels (no emoji) through [onChanged].
class InterestsPicker extends StatefulWidget {
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  const InterestsPicker({
    super.key,
    this.initial = const [],
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<InterestsPicker> createState() => _InterestsPickerState();
}

class _InterestsPickerState extends State<InterestsPicker> {
  late final List<String> _selected;
  final List<String> _custom = [];
  final _customController = TextEditingController();
  String? _customError;

  @override
  void initState() {
    super.initState();
    _selected = [];
    for (final label in widget.initial) {
      if (_contains(_selected, label)) continue;
      // Use the preset's exact spelling when it matches.
      final preset = kInterestOptions
          .where((o) => o.$2.toLowerCase() == label.toLowerCase())
          .map((o) => o.$2)
          .firstOrNull;
      _selected.add(preset ?? label);
      if (preset == null) _custom.add(label);
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  bool _contains(List<String> list, String label) =>
      list.any((s) => s.toLowerCase() == label.toLowerCase());

  void _notify() => widget.onChanged(List.unmodifiable(_selected));

  void _togglePreset(String label) {
    setState(() {
      if (_contains(_selected, label)) {
        _selected.removeWhere((s) => s.toLowerCase() == label.toLowerCase());
      } else {
        _selected.add(label);
      }
    });
    _notify();
  }

  void _removeCustom(String label) {
    setState(() {
      _custom.remove(label);
      _selected.remove(label);
    });
    _notify();
  }

  void _addCustom() {
    final text = _customController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return;
    if (text.length > kMaxCustomInterestLength) {
      setState(() => _customError = 'Max $kMaxCustomInterestLength characters.');
      return;
    }
    if (_contains(_selected, text)) {
      setState(() => _customError = 'Already added.');
      return;
    }
    setState(() {
      _customError = null;
      if (_isPreset(text)) {
        // Typed a preset name: just select that preset chip.
        _selected.add(kInterestOptions
            .firstWhere((o) => o.$2.toLowerCase() == text.toLowerCase())
            .$2);
      } else {
        _custom.add(text);
        _selected.add(text);
      }
      _customController.clear();
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    final done = count >= kMinInterests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          done
              ? '✓ $count selected'
              : 'Pick ${kMinInterests - count} more ($count/$kMinInterests selected)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: done ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final o in kInterestOptions)
              _InterestChip(
                text: '${o.$1} ${o.$2}',
                selected: _contains(_selected, o.$2),
                onTap: widget.enabled ? () => _togglePreset(o.$2) : null,
              ),
            for (final c in _custom)
              _InterestChip(
                text: '✨ $c',
                selected: true,
                trailing: Icons.close_rounded,
                onTap: widget.enabled ? () => _removeCustom(c) : null,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _customController,
                enabled: widget.enabled,
                maxLength: kMaxCustomInterestLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCustom(),
                onChanged: (_) {
                  if (_customError != null) setState(() => _customError = null);
                },
                decoration: InputDecoration(
                  hintText: "Don't see yours? Type it here",
                  counterText: '',
                  errorText: _customError,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: widget.enabled ? _addCustom : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(64, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? trailing;

  const _InterestChip({
    required this.text,
    required this.selected,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                Icon(trailing, size: 15, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only interest chips for the Profile screen.
class InterestChipsView extends StatelessWidget {
  final List<String> interests;
  const InterestChipsView({super.key, required this.interests});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final i in interests)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${interestEmoji(i)} $i',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
