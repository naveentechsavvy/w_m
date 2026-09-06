import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
              _createdTab(context, controller),
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

  Widget _createdTab(BuildContext context, MyMeetupsController controller) {
    if (controller.created.isEmpty) {
      return _emptyState("You haven't created any meetups yet.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: controller.created.length,
      itemBuilder: (context, index) {
        final meetup = controller.created[index];
        final pendingCount = controller.pendingRequestCountFor(meetup.id);
        final isCancelled = meetup.cancelled;
        final canCancel = !isCancelled && meetup.joined == 0;

        return MeetupStatusCard(
          experience: meetup,
          statusLabel: isCancelled
              ? "Cancelled"
              : (pendingCount > 0 ? "$pendingCount Pending" : null),
          statusColor: isCancelled ? Colors.red : AppColors.warning,
          actionLabel: canCancel ? "Cancel" : null,
          onActionTap: canCancel
              ? () => _confirmCancel(context, controller, meetup.id)
              : null,
        );
      },
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    MyMeetupsController controller,
    String meetupId,
  ) async {
    final reasonController = TextEditingController();
    String? errorText;

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text("Cancel this meetup?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "This will permanently remove the meetup. This can't be undone.",
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    maxLines: 3,
                    minLines: 2,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: "Reason for cancelling",
                      hintText: "e.g. Not enough people joined",
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () {
                    final text = reasonController.text.trim();
                    if (text.isEmpty) {
                      setState(() => errorText = "Please enter a reason");
                      return;
                    }
                    Navigator.pop(ctx, text);
                  },
                  child: const Text(
                    "Yes, Cancel",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();

    if (reason == null || reason.isEmpty) return;

    try {
      await controller.cancelMeetup(meetupId, reason: reason);
      Get.snackbar(
        "Meetup Cancelled",
        "Your meetup has been cancelled.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        "Couldn't Cancel",
        "Something went wrong. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
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
