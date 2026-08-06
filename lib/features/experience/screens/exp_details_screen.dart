import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../controllers/join_requests_controller.dart';
import '../models/experience_model.dart';
import '../models/join_request_model.dart';

class ExpDetailsScreen extends StatelessWidget {
  const ExpDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Experience experience = Get.arguments as Experience;
    final joinRequestsController = Get.find<JoinRequestsController>();

    final bool isMine = experience.organizerName == "You";

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
                    Text(
                      experience.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          experience.location,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          "${experience.date.day}/${experience.date.month}/${experience.date.year}",
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 16),
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
                        _statPill(
                          "${experience.joined}/${experience.seats} Joined",
                          Icons.groups_outlined,
                        ),
                      ],
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
                        final requested = joinRequestsController
                            .hasRequested(experience.id);

                        return SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: requested
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
                              backgroundColor: requested
                                  ? AppColors.textLight
                                  : AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              requested
                                  ? (existing?.status ==
                                          JoinRequestStatus.pending
                                      ? "Request Pending"
                                      : "Requested")
                                  : "Request to Join",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
