import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../controllers/food_menu_controller.dart';
import '../models/food_item_model.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  late final FoodMenuController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<FoodMenuController>()
        ? Get.find<FoodMenuController>()
        : Get.put(FoodMenuController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 26),
            color: Colors.black87,
            tooltip: "Profile",
            onPressed: () => Get.toNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(controller: controller),
          _CategoryChips(controller: controller),
          Expanded(
            child: Obx(() {
              if (!controller.isReady.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final grouped = controller.filteredGroupedByCategory;

              // ignore: avoid_print
              print(
                  'BUILD: filter=${controller.selectedFilter.value}, categories=${grouped.keys.toList()}');

              if (grouped.isEmpty) {
                final isFiltering =
                    controller.searchQuery.value.trim().isNotEmpty ||
                        controller.selectedFilter.value != 'All';
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      isFiltering
                          ? "No dishes match your search or filter."
                          : "No food items available right now. Check back soon!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black45, fontSize: 15),
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: grouped.entries.map((entry) {
                  final category = entry.key;
                  final categoryItems = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$category (${categoryItems.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...categoryItems.map((item) => _FoodItemTile(
                              item: item,
                              controller: controller,
                            )),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        if (controller.cart.isEmpty) return const SizedBox.shrink();

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.cart),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${controller.cartItemCount} item"
                      "${controller.cartItemCount == 1 ? '' : 's'}  •  "
                      "\u20b9${controller.cartTotal.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Text(
                    "View Cart",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ======================================================================
// SEARCH BAR  (now with voice search, like Swiggy's mic icon)
// ======================================================================

class _SearchBar extends StatefulWidget {
  final FoodMenuController controller;
  const _SearchBar({required this.controller});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _textController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    // Sets up the speech engine once, so tapping the mic later is instant.
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      Get.snackbar(
        "Voice Search Unavailable",
        "Please enable microphone permission to use voice search.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        _textController.text = result.recognizedWords;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
        widget.controller.searchQuery.value = result.recognizedWords;
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: "en_IN",
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _textController,
          onChanged: (value) => widget.controller.searchQuery.value = value,
          decoration: InputDecoration(
            hintText: _isListening ? 'Listening...' : "Search for a dish...",
            hintStyle: TextStyle(
              color: _isListening ? AppColors.primary : Colors.black38,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.black45),
            suffixIcon: IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: AppColors.primary,
              ),
              tooltip: "Voice search",
              onPressed: _toggleListening,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// CATEGORY CHIPS (built only from real categories in your data)
// ======================================================================

class _CategoryChips extends StatelessWidget {
  final FoodMenuController controller;
  const _CategoryChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filters = ['All', ...controller.allCategories];

      // ignore: avoid_print
      print('CHIPS BUILD: filters=$filters, selected=${controller.selectedFilter.value}');

      return SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final selected = controller.selectedFilter.value == filter;
            return ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                // ignore: avoid_print
                print('Chip tapped: $filter');
                controller.selectedFilter.value = filter;
                // ignore: avoid_print
                print('selectedFilter is now: ${controller.selectedFilter.value}');
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
            );
          },
        ),
      );
    });
  }
}

// ======================================================================
// FOOD ITEM TILE (real fields only: name, description, price, image)
// ======================================================================

class _FoodItemTile extends StatelessWidget {
  final FoodItem item;
  final FoodMenuController controller;

  const _FoodItemTile({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderIcon(),
                  )
                : _placeholderIcon(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "\u20b9${item.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary),
                    ),
                    const Spacer(),
                    Obx(() {
                      final qty = controller.quantityOf(item.id);
                      if (qty == 0) {
                        return OutlinedButton(
                          onPressed: () => controller.addToCart(item),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Add", style: TextStyle(fontSize: 12)),
                        );
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _stepperButton(
                            icon: Icons.remove,
                            onTap: () => controller.removeFromCart(item),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('$qty',
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _stepperButton(
                            icon: Icons.add,
                            onTap: () => controller.addToCart(item),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 84,
      height: 84,
      color: AppColors.primaryTint,
      child: const Icon(Icons.restaurant, color: AppColors.primary, size: 26),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
