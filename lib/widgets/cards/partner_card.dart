import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../core/database/enums/database_enums.dart';
import '../../core/models/entities/partner.dart';
import '../../theme/app_colors.dart';

class PartnerCard extends StatelessWidget {
  final Partner partner;
  final VoidCallback? onTap;

  const PartnerCard({
    super.key,
    required this.partner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat('#,##0.00');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _buildAvatar(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            partner.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(context),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (partner.email != null) ...[
                      Text(
                        partner.email!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Capital: \u20B9${currencyFormat.format(partner.capital)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${partner.ownershipPercentage.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (partner.status) {
      case PartnerStatus.active:
        bgColor = AppColors.statusActive.withValues(alpha: 0.12);
        textColor = AppColors.statusActive;
        icon = Icons.check_circle_rounded;
        break;
      case PartnerStatus.inactive:
        bgColor = AppColors.statusInactive.withValues(alpha: 0.12);
        textColor = AppColors.statusInactive;
        icon = Icons.cancel_rounded;
        break;
      case PartnerStatus.pending:
        bgColor = AppColors.statusPending.withValues(alpha: 0.12);
        textColor = AppColors.statusPending;
        icon = Icons.pending_rounded;
        break;
      case PartnerStatus.suspended:
        bgColor = AppColors.statusSuspended.withValues(alpha: 0.12);
        textColor = AppColors.statusSuspended;
        icon = Icons.pause_circle_rounded;
        break;
      case PartnerStatus.withdrawn:
        bgColor = AppColors.adjustment.withValues(alpha: 0.12);
        textColor = AppColors.adjustment;
        icon = Icons.logout_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            partner.statusDisplay,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (partner.photo != null && partner.photo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: CachedNetworkImage(
            imageUrl: partner.photo!,
            fit: BoxFit.cover,
            placeholder: (_, __) => _placeholderAvatar(context),
            errorWidget: (_, __, ___) => _placeholderAvatar(context),
          ),
        ),
      );
    }

    return _placeholderAvatar(context);
  }

  Widget _placeholderAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initial = partner.name.isNotEmpty
        ? partner.name[0].toUpperCase()
        : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
