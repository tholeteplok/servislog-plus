import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_widget.dart';

class StatistikSkeleton extends StatelessWidget {
  const StatistikSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range Selector Shimmer
          const ShimmerWidget.rectangular(height: 48),
          const SizedBox(height: 20),
          
          // Summary Cards
          Row(
            children: const [
              Expanded(child: ShimmerWidget.rectangular(height: 120)),
              SizedBox(width: 16),
              Expanded(child: ShimmerWidget.rectangular(height: 120)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Cash Flow Tracker
          const ShimmerWidget.rectangular(height: 200),
          const SizedBox(height: 20),
          
          // Chart Card
          const ShimmerWidget.rectangular(height: 250),
          const SizedBox(height: 16),
          
          // Info Box
          const ShimmerWidget.rectangular(height: 80),
        ],
      ),
    );
  }
}
