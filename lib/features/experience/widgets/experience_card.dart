import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../models/experience_model.dart';

class ExperienceCard extends StatelessWidget {

  final Experience experience;

  /// Optional override for tap behaviour. If not provided, tapping the
  /// card navigates to the experience details screen, passing this
  /// [experience] as the route argument.
  final VoidCallback? onTap;

  const ExperienceCard({
    super.key,
    required this.experience,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap ??
          () => Get.toNamed(
                AppRoutes.experienceDetails,
                arguments: experience,
              ),
      child: Container(

      margin: const EdgeInsets.only(bottom: 18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: const [

          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0,4),
          )

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          ClipRRect(
  borderRadius: const BorderRadius.vertical(
    top: Radius.circular(22),
  ),
  child: Image.asset(
    experience.image,
    height: 180,
    width: double.infinity,
    fit: BoxFit.cover,
  ),
),

          Padding(

            padding: const EdgeInsets.all(18),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  experience.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                if (experience.reviewCount > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Color(0xFFFFB300)),
                      const SizedBox(width: 4),
                      Text(
                        experience.avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "· ${experience.reviewCount} ${experience.reviewCount == 1 ? 'review' : 'reviews'}",
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),

                const SizedBox(height:8),

                Text(experience.location),

                const SizedBox(height:8),

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    Text("₹ ${experience.price.toInt()}"),

                    Text(
                      "${experience.joined}/${experience.seats} Joined",
                    ),

                  ],

                ),

              ],

            ),

          )

        ],

      ),

      ),
    );

  }

}