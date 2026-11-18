import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../../experience/models/experience_model.dart';
import '../../experience/repositories/experience_repository.dart';
import '../../food/models/food_item_model.dart';
import '../../food/repositories/food_repository.dart';

/// First screen after login: choose Explore or Order Food.
///
/// UI only. The name, meetups and dishes are READ once through the
/// existing repositories — nothing is written. Every load is
/// independent and fails quietly, so both banners always work, even
/// offline.
class ChoiceScreen extends StatefulWidget {
  const ChoiceScreen({super.key});

  @override
  State<ChoiceScreen> createState() => _ChoiceScreenState();
}

class _ChoiceScreenState extends State<ChoiceScreen> {
  static const _timeout = Duration(seconds: 10);

  /// Bumped on every reload and on dispose, so results from an older
  /// (or abandoned) load are ignored.
  int _loadToken = 0;

  String? _name;

  bool _meetupsLoading = true;
  int _meetupCount = 0;
  Experience? _nextPublic;

  bool _foodLoading = true;
  List<FoodItem> _dishes = const [];

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _loadToken++; // ignore anything still in flight
    super.dispose();
  }

  bool _isCurrent(int token) => mounted && token == _loadToken;

  /// Loads name, meetups and food in parallel. Used by initState and
  /// pull-to-refresh.
  Future<void> _loadAll() {
    final token = ++_loadToken;
    return Future.wait([
      _loadName(token),
      _loadMeetups(token),
      _loadFood(token),
    ]);
  }

  Future<void> _loadName(int token) async {
    String? name;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get()
            .timeout(_timeout);
        final n = doc.data()?['name'];
        // Same rule as Splash / Name entry: ignore the "User <phone>"
        // placeholder.
        if (n is String && n.trim().isNotEmpty && !n.startsWith('User ')) {
          name = n.trim();
        }
      }
    } catch (e) {
      debugPrint('[Choice] name load failed: $e');
    }
    if (!_isCurrent(token)) return;
    setState(() => _name = name);
  }

  Future<void> _loadMeetups(int token) async {
    int count = 0;
    Experience? next;
    try {
      final all = await ExperienceRepository().getAllMeetups().timeout(_timeout);
      final now = DateTime.now();
      // Same filter Explore uses: not cancelled and not yet ended.
      final active = all
          .where((e) => !e.cancelled && e.effectiveEndDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      count = active.length;
      next = active.where((e) => !e.isPrivate).firstOrNull;
    } catch (e) {
      debugPrint('[Choice] meetups load failed: $e');
    }
    if (!_isCurrent(token)) return;
    setState(() {
      _meetupCount = count;
      _nextPublic = next;
      _meetupsLoading = false;
    });
  }

  Future<void> _loadFood(int token) async {
    List<FoodItem> items = const [];
    try {
      items = await FoodRepository().streamAvailableItems().first.timeout(_timeout);
    } catch (e) {
      debugPrint('[Choice] food load failed: $e');
    }
    if (!_isCurrent(token)) return;
    setState(() {
      _dishes = items;
      _foodLoading = false;
    });
  }

  // ------------------------------------------------------------
  // Navigation — same routes as before.
  // ------------------------------------------------------------

  void _openExplore() => Get.offNamed(AppRoutes.home);
  void _openFood() => Get.toNamed(AppRoutes.food);

  // ------------------------------------------------------------
  // Live lines (null while loading)
  // ------------------------------------------------------------

  String _when(DateTime d) {
    final day = DateFormat('EEE').format(d);
    final time = d.minute == 0
        ? DateFormat('h a').format(d)
        : DateFormat('h:mm a').format(d);
    return '$day $time';
  }

  List<String>? get _meetupLines {
    if (_meetupsLoading) return null;
    if (_meetupCount == 0) return const ['New meetups added every week'];
    final n = _nextPublic;
    return [
      '$_meetupCount ${_meetupCount == 1 ? 'meetup' : 'meetups'} happening',
      if (n != null) 'Next: ${n.title} · ${_when(n.date)}',
    ];
  }

  List<String>? get _foodLines {
    if (_foodLoading) return null;
    if (_dishes.isEmpty) return const ['Menu updated daily'];
    return [
      '${_dishes.length} ${_dishes.length == 1 ? 'dish' : 'dishes'} available',
      _dishes.take(2).map((d) => d.name).join(', '),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // ~35% of the screen each, so header + both cards fit together.
    final cardHeight = (media.size.height * 0.35).clamp(220.0, 300.0);
    final compact = media.size.width < 380;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: RefreshIndicator(
            onRefresh: _loadAll,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Greeting(name: _name, compact: compact),
                      const SizedBox(height: 20),
                      _BannerCard(
                        height: cardHeight,
                        compact: compact,
                        semanticLabel: 'Explore meetups',
                        imageAsset: 'assets/images/banners/explore_banner.jpg',
                        imageAlignment: const Alignment(0, 0.35),
                        fallbackColors: const [
                          Color(0xFFFF5A3D),
                          Color(0xFFFF8A70),
                        ],
                        overlayColor: const Color(0xFF3B0E07),
                        strongOverlay: true,
                        tagIcon: Icons.celebration_rounded,
                        tagText: 'Meetups',
                        subtitle: "Discover what's happening around you",
                        liveLines: _meetupLines,
                        actionText: 'Explore',
                        actionColor: AppColors.primary,
                        actionTextColor: Colors.white,
                        onTap: _openExplore,
                      ),
                      const SizedBox(height: 16),
                      _BannerCard(
                        height: cardHeight,
                        compact: compact,
                        semanticLabel: 'Order food',
                        imageAsset: 'assets/images/banners/food_banner.jpg',
                        imageAlignment: const Alignment(0, 0.3),
                        fallbackColors: const [
                          Color(0xFFF4B400),
                          Color(0xFFFFB347),
                        ],
                        overlayColor: const Color(0xFF4A2604),
                        tagIcon: Icons.restaurant_rounded,
                        tagText: 'Food',
                        subtitle: 'Delicious food, delivered to your place',
                        liveLines: _foodLines,
                        actionText: 'Order Food',
                        actionColor: AppColors.accent,
                        actionTextColor: AppColors.textPrimary,
                        onTap: _openFood,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// GREETING
// ================================================================

class _Greeting extends StatelessWidget {
  final String? name;
  final bool compact;
  const _Greeting({required this.name, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name == null ? 'Hi there 👋' : 'Hi $name 👋',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 26 : 30,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "What's your plan today?",
          style: TextStyle(
            fontSize: compact ? 15.5 : 17,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// BANNER CARD
// ================================================================

class _BannerCard extends StatefulWidget {
  final double height;
  final bool compact;
  final String semanticLabel;
  final String imageAsset;
  final Alignment imageAlignment;
  final List<Color> fallbackColors;
  final Color overlayColor;

  /// Darker overlay reaching higher (used where text sits on a busy photo).
  final bool strongOverlay;
  final IconData tagIcon;
  final String tagText;
  final String subtitle;

  /// Null while loading (shows placeholder bars).
  final List<String>? liveLines;
  final String actionText;
  final Color actionColor;
  final Color actionTextColor;
  final VoidCallback onTap;

  const _BannerCard({
    required this.height,
    required this.compact,
    required this.semanticLabel,
    required this.imageAsset,
    required this.imageAlignment,
    required this.fallbackColors,
    required this.overlayColor,
    this.strongOverlay = false,
    required this.tagIcon,
    required this.tagText,
    required this.subtitle,
    required this.liveLines,
    required this.actionText,
    required this.actionColor,
    required this.actionTextColor,
    required this.onTap,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  static const _radius = 28.0;
  static const _textShadow = [Shadow(color: Color(0x55000000), blurRadius: 8)];

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo, or a gradient if it's missing / fails.
                  Image.asset(
                    widget.imageAsset,
                    fit: BoxFit.cover,
                    alignment: widget.imageAlignment,
                    errorBuilder: (_, _, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.fallbackColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  // Dark tinted gradient from the bottom for readable text.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        // Strong: solid dark over the bottom ~55% (all the
                        // text), fading out above so the top stays visible.
                        colors: widget.strongOverlay
                            ? [
                                widget.overlayColor.withValues(alpha: 0.92),
                                widget.overlayColor.withValues(alpha: 0.78),
                                widget.overlayColor.withValues(alpha: 0.45),
                                widget.overlayColor.withValues(alpha: 0.0),
                              ]
                            : [
                                widget.overlayColor.withValues(alpha: 0.85),
                                widget.overlayColor.withValues(alpha: 0.55),
                                widget.overlayColor.withValues(alpha: 0.0),
                              ],
                        stops: widget.strongOverlay
                            ? const [0.0, 0.45, 0.62, 0.9]
                            : const [0.0, 0.45, 0.85],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(widget.compact ? 16 : 20),
                    child: LayoutBuilder(
                      builder: (context, c) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Tag(icon: widget.tagIcon, text: widget.tagText),
                          const SizedBox(height: 8),
                          // Text block at the bottom. If it doesn't fit
                          // (small phone / large system font) it scales
                          // down instead of overflowing or cutting text.
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomLeft,
                              child: SizedBox(
                                width: c.maxWidth,
                                child: _content(c.maxWidth),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Ripple over everything; the whole card is the tap target.
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: widget.onTap,
                      onHighlightChanged: (v) => setState(() => _pressed = v),
                      splashColor: Colors.white.withValues(alpha: 0.15),
                      highlightColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(double width) {
    final compact = widget.compact;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle uses the full width (never beside the button).
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: compact ? 15 : 16,
            height: 1.3,
            color: Colors.white.withValues(alpha: 0.9),
            shadows: _textShadow,
          ),
        ),
        const SizedBox(height: 12),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
        const SizedBox(height: 12),
        _bottomRow(width),
      ],
    );
  }

  /// Live info + button. The button keeps its full natural width; if it
  /// doesn't leave room for the live text beside it (very large system
  /// font), the button moves below the live text instead of squeezing.
  Widget _bottomRow(double width) {
    final pill = _ActionPill(
      text: widget.actionText,
      color: widget.actionColor,
      textColor: widget.actionTextColor,
      compact: widget.compact,
    );
    final pillWidth = _ActionPill.naturalWidth(
      context,
      widget.actionText,
      widget.compact,
    );
    const minLiveWidth = 110.0;

    if (pillWidth + 12 + minLiveWidth <= width) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _liveText()),
          const SizedBox(width: 12),
          pill,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _liveText(),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          // Only if the pill is wider than the whole card: scale it down
          // as a whole (text stays complete, never cut).
          child: pillWidth <= width
              ? pill
              : FittedBox(fit: BoxFit.scaleDown, child: pill),
        ),
      ],
    );
  }

  Widget _liveText() {
    final lines = widget.liveLines;
    if (lines == null) return const _LinePlaceholder();
    return Text(
      lines.join('\n'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: widget.compact ? 13.5 : 14.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: Colors.white,
        shadows: _textShadow,
      ),
    );
  }
}

/// Frosted pill tag with a Material icon (no emoji).
class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Browse →" / "See menu →" pill. Visual only — the whole card is the
/// tap target.
class _ActionPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final bool compact;

  const _ActionPill({
    required this.text,
    required this.color,
    required this.textColor,
    required this.compact,
  });

  static double _hPad(bool compact) => compact ? 18 : 22;

  static TextStyle _style(bool compact, Color color) => TextStyle(
        fontSize: compact ? 15 : 16,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Full width the pill needs (text at the current system font size +
  /// arrow + padding), so the layout can make room for it.
  static double naturalWidth(BuildContext context, String text, bool compact) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(_style(compact, Colors.black)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width + 6 + 20 + _hPad(compact) * 2 + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 48 : 52,
      padding: EdgeInsets.symmetric(horizontal: _hPad(compact)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, maxLines: 1, softWrap: false, style: _style(compact, textColor)),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 20, color: textColor),
        ],
      ),
    );
  }
}

/// Soft pulsing bars shown while the live lines load.
class _LinePlaceholder extends StatefulWidget {
  const _LinePlaceholder();

  @override
  State<_LinePlaceholder> createState() => _LinePlaceholderState();
}

class _LinePlaceholderState extends State<_LinePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _bar(double width) => Container(
        width: width,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 0.8).animate(_c),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(140),
          const SizedBox(height: 8),
          _bar(100),
        ],
      ),
    );
  }
}
