import 'package:dermai/utils/app_colors.dart';
import 'package:flutter/material.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final bool isActive = index <= currentStep;
          final bool isLast = index == totalSteps - 1;

          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: isLast ? EdgeInsets.zero : const EdgeInsets.only(right: 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey[300],
              ),
            ),
          );
        }),
      ),
    );
  }
}