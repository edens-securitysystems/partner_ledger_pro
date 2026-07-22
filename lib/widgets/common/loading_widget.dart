import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum LoadingVariant { circular, shimmerList, shimmerCard, shimmerChart, fullPage }

class LoadingWidget extends StatelessWidget {
  final LoadingVariant variant;
  final String? message;
  final double size;

  const LoadingWidget({
    super.key,
    this.variant = LoadingVariant.circular,
    this.message,
    this.size = 48,
  });

  const LoadingWidget.circular({super.key, this.message, this.size = 48})
      : variant = LoadingVariant.circular;

  const LoadingWidget.shimmerList({super.key, this.message})
      : variant = LoadingVariant.shimmerList,
        size = 48;

  const LoadingWidget.shimmerCard({super.key, this.message})
      : variant = LoadingVariant.shimmerCard,
        size = 48;

  const LoadingWidget.shimmerChart({super.key, this.message})
      : variant = LoadingVariant.shimmerChart,
        size = 48;

  const LoadingWidget.fullPage({super.key, this.message})
      : variant = LoadingVariant.fullPage,
        size = 48;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case LoadingVariant.circular:
        return _buildCircular(context);
      case LoadingVariant.shimmerList:
        return _buildShimmerList(context);
      case LoadingVariant.shimmerCard:
        return _buildShimmerCard(context);
      case LoadingVariant.shimmerChart:
        return _buildShimmerChart(context);
      case LoadingVariant.fullPage:
        return _buildFullPage(context);
    }
  }

  Widget _buildCircular(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerList(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.light
          ? Colors.grey.shade200
          : Colors.grey.shade800,
      highlightColor: theme.brightness == Brightness.light
          ? Colors.grey.shade50
          : Colors.grey.shade700,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 140,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.light
          ? Colors.grey.shade200
          : Colors.grey.shade800,
      highlightColor: theme.brightness == Brightness.light
          ? Colors.grey.shade50
          : Colors.grey.shade700,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerChart(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.light
          ? Colors.grey.shade200
          : Colors.grey.shade800,
      highlightColor: theme.brightness == Brightness.light
          ? Colors.grey.shade50
          : Colors.grey.shade700,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (_) => Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message ?? 'Loading...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
