import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final orderId = args?['orderId'] as String?;
    final repo = OrderRepository();

    if (orderId == null) {
      return const Scaffold(
        body: Center(child: Text("Order not found.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Track Order",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<FoodOrder>(
        stream: repo.streamOrder(orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                "Order #${order.id.substring(0, 8).toUpperCase()}",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 24),
              _StatusTimeline(order: order),
              const SizedBox(height: 28),
              const Text("Items",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              ...order.items.map((line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${line.name} x${line.quantity}",
                            style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        Text("\u20b9${(line.price * line.quantity).toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  )),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text("\u20b9${order.total.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 32),
              if (order.status != 'delivered')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => repo.advanceStatus(order.id, order.status),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Advance Status (debug)"),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final FoodOrder order;
  const _StatusTimeline({required this.order});

  static const _labels = {
    'placed': 'Order Placed',
    'preparing': 'Preparing',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
  };

  @override
  Widget build(BuildContext context) {
    final currentIndex = order.statusIndex;

    return Column(
      children: List.generate(kOrderStatusSteps.length, (i) {
        final step = kOrderStatusSteps[i];
        final done = i <= currentIndex;
        final isLast = i == kOrderStatusSteps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.primary : Colors.grey.shade300,
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: i < currentIndex ? AppColors.primary : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _labels[step] ?? step,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                  color: done ? Colors.black87 : Colors.black38,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}