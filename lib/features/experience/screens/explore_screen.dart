import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../controllers/app_config_controller.dart';
import '../controllers/subscription_controller.dart';
import '../controllers/experience_controller.dart';
import '../widgets/experience_card.dart';
import '../widgets/bottom_navigation.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final cityController = TextEditingController();
  final cityFocusNode = FocusNode();
  bool showCitySuggestions = false;

  late final ExperienceController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ExperienceController());

    cityFocusNode.addListener(() {
      setState(() {
        showCitySuggestions =
            cityFocusNode.hasFocus && cityController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    cityController.dispose();
    cityFocusNode.dispose();
    super.dispose();
  }

  /// Real city list (excludes the synthetic "All" entry from the
  /// controller) filtered live against whatever's typed so far.
  List<String> get filteredCityOptions {
    final query = cityController.text.trim().toLowerCase();
    final realCities = controller.cities.where((c) => c != "All").toList();
    if (query.isEmpty) return realCities;
    return realCities.where((c) => c.toLowerCase().contains(query)).toList();
  }

  void selectCity(String city) {
    setState(() {
      cityController.text = city;
      showCitySuggestions = false;
    });
    cityFocusNode.unfocus();
    controller.changeCity(city);
  }

  void clearCity() {
    setState(() {
      cityController.clear();
      showCitySuggestions = false;
    });
    cityFocusNode.unfocus();
    controller.changeCity("All");
  }

  /// Explicit dismissal for taps that land outside both the city field
  /// and the suggestion list. We don't rely on TextField's built-in
  /// onTapOutside for this because that fires on tap-down and can race
  /// with (and cancel) a tap-up on a ListTile suggestion — see
  /// onTapOutside override below.
  void dismissCitySuggestions() {
    if (showCitySuggestions) {
      setState(() => showCitySuggestions = false);
      cityFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionController = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController(), permanent: true);
    final appConfigController = Get.isRegistered<AppConfigController>()
        ? Get.find<AppConfigController>()
        : Get.put(AppConfigController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: GestureDetector(
          // translucent so this still lets taps pass through to the
          // ListTile suggestions / TextField underneath; it only acts
          // as a catch-all for taps on empty space.
          behavior: HitTestBehavior.translucent,
          onTap: dismissCitySuggestions,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ===========================
                // City search (left) + Categories (right) — one row,
                // City now leads since it's the primary way people
                // narrow down meetups. On narrow screens this wraps to
                // a Column instead so the city field never gets
                // squeezed unreadably thin.
                // ===========================
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;

                    // FIX: Categories was a horizontally-scrolling row
                    // of pill chips — once the category list grows it
                    // gets cramped and requires side-scrolling to find
                    // options. Replaced with a dropdown, styled the
                    // same as the City search box below it.
                    final categoriesBlock = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Categories",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Obx(() {
                          final currentValue =
                              controller.categories.contains(
                            controller.selectedCategory.value,
                          )
                              ? controller.selectedCategory.value
                              : controller.categories.first;

                          return Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: currentValue,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.primary,
                                ),
                                items: controller.categories
                                    .map((cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(
                                            cat,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.changeCategory(value);
                                  }
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    );

                    final cityBlock = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "City",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: cityController,
                            focusNode: cityFocusNode,
                            // IMPORTANT: override the default "tap
                            // outside unfocuses" behavior. The default
                            // fires on tap-DOWN, which was unfocusing
                            // the field (and collapsing the suggestion
                            // list via the focus listener) before a
                            // tap-UP on a ListTile suggestion had a
                            // chance to register — so taps on the
                            // dropdown appeared to do nothing. We
                            // handle dismissal explicitly instead, via
                            // selectCity/clearCity/dismissCitySuggestions.
                            onTapOutside: (event) {},
                            onChanged: (value) {
                              setState(() {
                                showCitySuggestions =
                                    value.trim().isNotEmpty;
                              });
                              // Live filter: every keystroke re-filters
                              // the meetup list (case-insensitive
                              // substring match happens in the
                              // controller), not just when a suggestion
                              // is tapped. Falling back to "All" when
                              // the field is empty clears the filter
                              // entirely.
                              controller.changeCity(
                                  value.trim().isEmpty ? "All" : value);
                            },
                            decoration: InputDecoration(
                              hintText: "Search a city, e.g. Chennai",
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.primary),
                              suffixIcon: cityController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 18),
                                      onPressed: clearCity,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Obx(() {
                          final options = filteredCityOptions;
                          if (!showCitySuggestions || options.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: const EdgeInsets.only(top: 6),
                            constraints:
                                const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              itemCount: options.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final c = options[index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: AppColors.primary),
                                  title: Text(c,
                                      style: const TextStyle(fontSize: 14)),
                                  onTap: () => selectCity(c),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          cityBlock,
                          const SizedBox(height: 24),
                          categoriesBlock,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: cityBlock),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: categoriesBlock),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),

                // ===========================
                // Nearby You — meetups within 30km of the user's
                // current GPS position (see _nearbyRadiusKm in
                // ExperienceController). Renders nothing at all (no
                // heading, no message) whenever there's no location
                // fix yet or nothing nearby — only takes up space when
                // there's an actual result to show.
                // ===========================
                const Text(
                  "Nearby You",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Obx(() {
                  if (controller.currentPosition.value == null) {
                    return const SizedBox.shrink();
                  }

                  final nearbyList = controller.nearby;
                  if (nearbyList.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children:
                        nearbyList.map((e) => ExperienceCard(experience: e)).toList(),
                  );
                }),

                const SizedBox(height: 20),

              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      floatingActionButton: Obx(() {
        final canCreate = !appConfigController.premiumEnabled.value ||
            subscriptionController.isPremium.value;

        if (!canCreate) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () => Get.toNamed(AppRoutes.createExperience),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Create",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }
}