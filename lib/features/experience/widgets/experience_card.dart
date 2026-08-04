import 'package:flutter/material.dart';

import '../models/experience_model.dart';

class ExperienceCard extends StatelessWidget {

  final Experience experience;

  const ExperienceCard({
    super.key,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

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

    );

  }

}