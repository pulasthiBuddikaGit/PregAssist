import 'package:flutter/material.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ProgressIndicatorWidget({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final step = index + 1;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: step <= currentStep
                    ? const Color(0xFFEC4899)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
