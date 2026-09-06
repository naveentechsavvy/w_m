import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../../reviews/controllers/review_controller.dart';
import '../../reviews/widgets/rating_summary.dart';
import '../../reviews/widgets/review_card.dart';
import '../controllers/experience_controller.dart';
import '../controllers/join_requests_controller.dart';
import '../models/experience_model.dart';
import '../models/join_request_model.dart';

class ExpDetailsScreen extends StatelessWidget {
  const ExpDetailsScreen({super.key});

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        "Couldn't open Maps",
        "Please check if Google Maps is installed.",
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final Experience experience = Get.arguments as Experience;
    final joinRequestsController = Get.find<JoinRequestsController>();
    final experienceController = Get.find<ExperienceController>();
    final reviewController = Get.put(
      ReviewController(meetupId: experience.id),
      tag: experience.id,
    );

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final bool isMine = experience.createdBy.isNotEmpty &&
        experience.createdBy == currentUid;

    final bool isParticipant = experience.participants.contains(currentUid);
    final bool canOpenChat = isMine || isParticipant;
    final bool hasCoordinates =
        experience.latitude != 0.0 && experience.longitude != 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    child: Image.asset(
                      experience.image,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.4),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            experience.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (canOpenChat)
                          IconButton(
                            tooltip: "Group Chat",
                            onPressed: () => Get.toNamed(
                              AppRoutes.chat,
                              arguments: {
                                'meetupId': experience.id,
                                'meetupTitle': experience.title,
                              },
                            ),
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    RatingSummary(
                      avgRating: experience.avgRating,
                      reviewCount: experience.reviewCount,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            experience.location,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        Obx(() {
                          final km = experienceController.distanceToKm(experience);
                          if (km == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              "${km.toStringAsFixed(1)} km away",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }),
                        if (hasCoordinates)
                          IconButton(
                            tooltip: "Get Directions",
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _openDirections(
                                experience.latitude, experience.longitude),
                            icon: const Icon(Icons.directions_outlined,
                                color: AppColors.primary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Date + start–end time row.
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          "${experience.date.day}/${experience.date.month}/${experience.date.year}",
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "· ${_formatTime(experience.date)} – ${_formatTime(experience.effectiveEndDate)}",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          "By ${experience.organizerName}",
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _statPill(
                          "₹ ${experience.price.toInt()}",
                          Icons.currency_rupee,
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Get.toNamed(
                            AppRoutes.participants,
                            arguments: experience,
                          ),
                          child: _statPill(
                            "${experience.joined}/${experience.seats} Joined",
                            Icons.groups_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _MeetupCountdown(
                      startDate: experience.date,
                      endDate: experience.effectiveEndDate,
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "About this meetup",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      experience.description.isEmpty
                          ? "No description provided."
                          : experience.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (isMine)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "This is your meetup. Manage join requests from My Meetups.",
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Obx(() {
                        final existing =
                            joinRequestsController.myRequestFor(experience.id);
                        final status = existing?.status;

                        final bool isPending =
                            status == JoinRequestStatus.pending;
                        final bool isApproved =
                            status == JoinRequestStatus.approved ||
                                isParticipant;
                        final bool isRejected =
                            status == JoinRequestStatus.rejected;

                        final bool disabled =
                            isPending || isApproved || isRejected;

                        String label;
                        Color bgColor;

                        if (isApproved) {
                          label = "Joined";
                          bgColor = AppColors.textLight;
                        } else if (isPending) {
                          label = "Request Pending";
                          bgColor = AppColors.textLight;
                        } else if (isRejected) {
                          label = "Rejected";
                          bgColor = Colors.red.shade300;
                        } else {
                          label = "Request to Join";
                          bgColor = AppColors.primary;
                        }

                        return SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: disabled
                                ? null
                                : () async {
                                    await joinRequestsController
                                        .sendRequest(experience);
                                    Get.snackbar(
                                      "Request Sent",
                                      "Your request to join \"${experience.title}\" has been sent",
                                      backgroundColor: AppColors.primary,
                                      colorText: Colors.white,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bgColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Reviews",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (experience.reviewCount > 0)
                          TextButton(
                            onPressed: () => Get.toNamed(
                              AppRoutes.reviews,
                              arguments: experience,
                            ),
                            child: const Text("See All"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Obx(() {
                      if (reviewController.isLoading.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (reviewController.reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            "No reviews yet. Be the first to share your experience!",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return Column(
                        children: reviewController.reviews
                            .take(2)
                            .map((r) => ReviewCard(review: r))
                            .toList(),
                      );
                    }),

                    const SizedBox(height: 8),

                    Obx(() {
                      if (!reviewController.canReview(experience)) {
                        return const SizedBox.shrink();
                      }
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => Get.toNamed(
                            AppRoutes.writeReview,
                            arguments: experience,
                          ),
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text("Write a Review"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a live countdown between [startDate] and [endDate].
///
/// - Hidden entirely if more than 1 hour from start.
/// - "Starts in Xh Ym" between 1 hour and 30 minutes before start.
/// - "Starts in X min" inside the last 30 minutes before start.
/// - "Happening now" while between start and end.
/// - "This meetup has ended" once past the end time.
class _MeetupCountdown extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _MeetupCountdown({required this.startDate, required this.endDate});

  @override
  State<_MeetupCountdown> createState() => _MeetupCountdownState();
}

class _MeetupCountdownState extends State<_MeetupCountdown> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final untilStart = widget.startDate.difference(_now);
    final untilEnd = widget.endDate.difference(_now);

    final bool notStartedYet = untilStart.isNegative == false;
    final bool isOngoing = untilStart.isNegative && !untilEnd.isNegative;
    final bool hasEnded = untilEnd.isNegative;

    // Only show the card within 1 hour of start, or while ongoing/ended.
    final bool withinWindow = isOngoing ||
        hasEnded ||
        (notStartedYet && untilStart <= const Duration(hours: 1));

    if (!withinWindow) return const SizedBox.shrink();

    String label;
    Color bgColor;
    Color fgColor;

    if (hasEnded) {
      label = "This meetup has ended";
      bgColor = AppColors.textLight;
      fgColor = AppColors.textSecondary;
    } else if (isOngoing) {
      label = "Happening now";
      bgColor = AppColors.primaryTint;
      fgColor = AppColors.primary;
    } else if (untilStart <= const Duration(minutes: 30)) {
      final minutes = untilStart.inMinutes;
      label = minutes <= 0 ? "Starting any moment" : "Starts in $minutes min";
      bgColor = AppColors.primaryTint;
      fgColor = AppColors.primary;
    } else {
      final minutes = untilStart.inMinutes % 60;
      label = "Starts in ${untilStart.inHours}h ${minutes}m";
      bgColor = AppColors.primaryTint;
      fgColor = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: fgColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: fgColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}