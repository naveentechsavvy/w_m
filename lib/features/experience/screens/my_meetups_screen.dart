import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../controllers/join_requests_controller.dart';
import '../controllers/my_meetups_controller.dart';
import '../models/join_request_model.dart';
import '../widgets/meetup_status_card.dart';

class MyMeetupsScreen extends StatelessWidget {
  const MyMeetupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<JoinRequestsController>()) {
      Get.put(JoinRequestsController(), permanent: true);
    }
    final controller = Get.put(MyMeetupsController());

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          title: const Text(
            "My Meetups",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Created"),
              Tab(text: "Joined"),
              Tab(text: "Upcoming"),
              Tab(text: "Completed"),
              Tab(text: "Cancelled"),
            ],
          ),
        ),
        body: Obx(
          () => TabBarView(
            children: [
              _createdTab(controller),
              _requestListTab(
                controller.joined,
                emptyText: "You haven't joined any meetups yet.",
                showCancel: true,
              ),
              _requestListTab(
                controller.upcoming,
                emptyText: "No upcoming meetups.",
              ),
              _requestListTab(
                controller.completed,
                emptyText: "No completed meetups yet.",
              ),
              _requestListTab(
                controller.cancelled,
                emptyText: "No cancelled or rejected requests.",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createdTab(MyMeetupsController controller) {
    if (controller.created.isEmpty) {
      return _emptyState("You haven't created any meetups yet.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: controller.created.length,
      itemBuilder: (context, index) {
        final meetup = controller.created[index];
        final pendingCount = controller.pendingRequestCountFor(meetup.id);

        return MeetupStatusCard(
          experience: meetup,
          statusLabel: pendingCount > 0 ? "$pendingCount Pending" : null,
          statusColor: AppColors.warning,
          actionLabel: "View Requests",
          onActionTap: () => Get.toNamed(
            AppRoutes.joinRequests,
            arguments: meetup.id,
          ),
        );
      },
    );
  }

  Widget _requestListTab(
    List<JoinRequest> items, {
    required String emptyText,
    bool showCancel = false,
  }) {
    if (items.isEmpty) {
      return _emptyState(emptyText);
    }

    final joinRequestsController = Get.find<JoinRequestsController>();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final request = items[index];
        final canCancel =
            showCancel && request.status == JoinRequestStatus.pending;

        return MeetupStatusCard(
          experience: request.meetup,
          statusLabel: request.status.label,
          statusColor: request.status.color,
          actionLabel: canCancel ? "Cancel Request" : null,
          onActionTap: canCancel
              ? () => joinRequestsController.cancel(request.id)
              : null,
        );
      },
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ),
    );
  }
}
