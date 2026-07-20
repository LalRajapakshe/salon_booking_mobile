import 'package:flutter/material.dart';

class AiSummaryCard extends StatelessWidget {
  const AiSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "AI Business Assistant",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "Today's Summary",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "• Expected Revenue : Rs. 96,000\n"
              "• Appointment load is higher than usual.\n"
              "• Hair Spa bookings are increasing.\n"
              "• Amanda is almost fully booked.\n"
              "• Consider promoting Facial packages.",
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 22),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: .94,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: const [
                Text(
                  "Business Health",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Text(
                  "94%",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}