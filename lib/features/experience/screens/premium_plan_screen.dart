import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../../experience/controllers/app_config_controller.dart';
import '../controllers/payment_controller.dart';

class _Plan {
  final String name;
  final String price;
  final String period;
  final int amountInPaise;
  final String? saveNote;

  const _Plan({
    required this.name,
    required this.price,
    required this.period,
    required this.amountInPaise,
    this.saveNote,
  });
}

class PremiumPlanScreen extends StatefulWidget {
  const PremiumPlanScreen({super.key});

  @override
  State<PremiumPlanScreen> createState() => _PremiumPlanScreenState();
}

class _PremiumPlanScreenState extends State<PremiumPlanScreen> {
  int _selectedIndex = 0;

  static const List<_Plan> _plans = [
    _Plan(name: "Monthly", price: "₹99", period: "/ month", amountInPaise: 9900),
    _Plan(
      name: "Yearly",
      price: "₹799",
      period: "/ year",
      amountInPaise: 79900,
      saveNote: "Save ₹389 with the yearly plan",
    ),
  ];

  static const List<String> _features = [
    "Create your own meetups",
    "Unlimited meetups, no limits",
    "Manage join requests from participants",
    "Group chat with your meetup members",
    "Priority visibility in Explore",
  ];

  @override
  Widget build(BuildContext context) {
    final appConfigController = Get.isRegistered<AppConfigController>()
        ? Get.find<AppConfigController>()
        : Get.put(AppConfigController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Weekend Masti Premium",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        // Whole-screen gate: if the admin-controlled flag is off
        // (Firestore: app_config/settings.premiumEnabled), show a
        // simple unavailable state instead of the paywall — covers
        // anyone who navigates here directly (e.g. a deep link or an
        // old bookmark), not just the Home banner tap, which is
        // already hidden separately when the flag is off.
        child: Obx(() {
          if (!appConfigController.premiumEnabled.value) {
            return _PremiumUnavailable(onBack: () => Get.back());
          }
          return _PremiumPlanContent(
            selectedIndex: _selectedIndex,
            plans: _plans,
            features: _features,
            onSelectPlan: (index) => setState(() => _selectedIndex = index),
          );
        }),
      ),
    );
  }
}

class _PremiumUnavailable extends StatelessWidget {
  final VoidCallback onBack;

  const _PremiumUnavailable({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            "Premium isn't available right now",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Check back soon — everyone can explore and join meetups for free in the meantime.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onBack,
            child: const Text("Go back"),
          ),
        ],
      ),
    );
  }
}

class _PremiumPlanContent extends StatelessWidget {
  final int selectedIndex;
  final List<_Plan> plans;
  final List<String> features;
  final ValueChanged<int> onSelectPlan;

  const _PremiumPlanContent({
    required this.selectedIndex,
    required this.plans,
    required this.features,
    required this.onSelectPlan,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentController());
    final plan = plans[selectedIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Create your own meetups",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Premium members can create meetups. Free members can explore and join.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),

          const SizedBox(height: 24),

          // Monthly / Yearly toggle — pill style, matches CategoryChip look
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: List.generate(plans.length, (index) {
                final isSelected = index == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectPlan(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        plans[index].name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.price,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Text(
                            plan.period,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (plan.saveNote != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plan.saveNote!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    ...features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryTint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: AppColors.primary, size: 14),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            "Your membership renews automatically at ${plan.price} per ${plan.name == "Monthly" ? "month" : "year"} unless cancelled. Cancel anytime.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),

          const SizedBox(height: 16),

          Obx(() => SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: controller.isProcessing.value
                      ? null
                      : () => controller.startCheckout(
                            planName: plan.name,
                            amountInPaise: plan.amountInPaise,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    controller.isProcessing.value ? "Please wait..." : "Subscribe Now",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),

          const SizedBox(height: 8),

          Center(
            child: TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                "Skip for now",
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
