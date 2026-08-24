import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../../experience/models/experience_model.dart';
import '../controllers/review_controller.dart';
import '../widgets/rating_input.dart';

class WriteReviewScreen extends StatelessWidget {
  const WriteReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Experience meetup = Get.arguments as Experience;
    final controller = Get.put(ReviewController(meetupId: meetup.id), tag: meetup.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text("Write a Review", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meetup.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Center(child: Text("Rate your experience", style: TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(height: 8),
              Obx(() => RatingInput(
                    value: controller.rating.value,
                    onChanged: (v) => controller.rating.value = v,
                  )),
              const SizedBox(height: 20),
              TextField(
                controller: controller.commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Share details about your experience...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...List.generate(controller.selectedPhotos.length, (i) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(controller.selectedPhotos[i], width: 70, height: 70, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () => controller.removePhoto(i),
                                child: const CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      GestureDetector(
                        onTap: controller.pickPhoto,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Obx(() => ElevatedButton(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : () async {
                              final success = await controller.submitReview();
                              if (success) Get.back();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: controller.isSubmitting.value
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text("SUBMIT REVIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}