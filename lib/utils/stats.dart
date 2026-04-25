import 'package:flutter/material.dart';

class Stats extends StatelessWidget {
  static const String id = "stats_page";
  const Stats({super.key, this.label, this.amount, this.dotColor});

  final String? label;
  final String? amount;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3150) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(height: 2),
          Column(
            children: [
              Text(
                label!,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 2),
              Text(
                amount!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFF9FAFB) : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
