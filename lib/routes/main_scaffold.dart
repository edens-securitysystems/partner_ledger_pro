import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../features/auth/providers/auth_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _sidebarController;
  late Animation<double> _sidebarWidth;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sidebarWidth = Tween<double>(begin: 260, end: 72).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOutCubic),
    );
    _sidebarController.value = 0.0;
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
    if (_isSidebarExpanded) {
      _sidebarController.reverse();
    } else {
      _sidebarController.forward();
    }
  }

  int _currentIndex(String location) {
    if (location.startsWith('/dashboard') || location == '/') return 0;
    if (location.startsWith('/partner')) return 1;
    if (location.startsWith('/transaction')) return 2;
    if (location.startsWith('/report')) return 3;
    return 4;
  }

  void _onNavTap(int index, String location) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/partners');
        break;
      case 2:
        context.go('/transactions');
        break;
      case 3:
        context.go('/reports');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'Add Transaction',
                        color: AppColors.lightPrimary,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/transactions/add');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.person_add_rounded,
                        label: 'Add Partner',
                        color: AppColors.lightTertiary,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/partners/add');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.business_rounded,
                        label: 'Add Business',
                        color: AppColors.investment,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/businesses/add');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    if (isDesktop) {
      return _buildDesktopLayout(location);
    }
    return _buildMobileLayout(location);
  }

  Widget _buildDesktopLayout(String location) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Row(
        children: [
          AnimatedBuilder(
            animation: _sidebarWidth,
            builder: (context, child) {
              return SizedBox(
                width: _sidebarWidth.value,
                child: child,
              );
            },
            child: Container(
              height: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  right: BorderSide(color: colorScheme.outlineVariant, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _SidebarHeader(
                    isExpanded: _isSidebarExpanded,
                    onToggle: _toggleSidebar,
                  ),
                  const SizedBox(height: 8),
                  Divider(color: colorScheme.outlineVariant, height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          _SidebarNavItem(
                            icon: Icons.dashboard_rounded,
                            label: 'Dashboard',
                            isSelected: location.startsWith('/dashboard'),
                            isExpanded: _isSidebarExpanded,
                            onTap: () => context.go('/dashboard'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarNavItem(
                            icon: Icons.people_rounded,
                            label: 'Partners',
                            isSelected: location.startsWith('/partner'),
                            isExpanded: _isSidebarExpanded,
                            onTap: () => context.go('/partners'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarNavItem(
                            icon: Icons.receipt_long_rounded,
                            label: 'Transactions',
                            isSelected: location.startsWith('/transaction'),
                            isExpanded: _isSidebarExpanded,
                            onTap: () => context.go('/transactions'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarNavItem(
                            icon: Icons.assessment_rounded,
                            label: 'Reports',
                            isSelected: location.startsWith('/report'),
                            isExpanded: _isSidebarExpanded,
                            onTap: () => context.go('/reports'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarNavItem(
                            icon: Icons.business_rounded,
                            label: 'Businesses',
                            isSelected: location.startsWith('/business'),
                            isExpanded: _isSidebarExpanded,
                            onTap: () => context.go('/businesses'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarNavItem(
                            icon: Icons.settings_rounded,
                            label: 'Settings',
                            isSelected: location.startsWith('/settings'),
                            isExpanded: _isSidebarExpanded,
                            onTap: () => context.go('/settings'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarNavItem(
                            icon: Icons.notifications_rounded,
                            label: 'Notifications',
                            isSelected: location.startsWith('/notification'),
                            isExpanded: _isSidebarExpanded,
                            badgeCount: 3,
                            onTap: () => context.go('/notifications'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarNavItem(
                            icon: Icons.how_to_vote_outlined,
                            label: 'Approvals',
                            isSelected: location.startsWith('/pending-approval'),
                            isExpanded: _isSidebarExpanded,
                            onTap: () => context.go('/pending-approvals'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarNavItem(
                            icon: Icons.search_rounded,
                            label: 'Search',
                            isSelected: location.startsWith('/search'),
                            isExpanded: _isSidebarExpanded,
                            onTap: () => context.go('/search'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(color: colorScheme.outlineVariant, height: 1),
                  _SidebarProfile(
                    isExpanded: _isSidebarExpanded,
                    userName: user?.name ?? 'John Doe',
                    userEmail: user?.email ?? 'john@example.com',
                    onTap: () => context.go('/settings/profile'),
                    onLogout: () => ref.read(authProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildMobileLayout(String location) {
    final index = _currentIndex(location);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => _onNavTap(i, location),
          height: 72 + bottomPadding,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outlined),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Partners',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment_rounded),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              selectedIcon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

}

class _SidebarHeader extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SidebarHeader({required this.isExpanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: GestureDetector(
        onTap: isExpanded ? null : onToggle,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 22),
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Partner Ledger',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Pro',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: onToggle,
                tooltip: 'Collapse sidebar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final int? badgeCount;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: isExpanded ? '' : label,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    if (badgeCount != null && badgeCount! > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              badgeCount! > 9 ? '9+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarProfile extends StatelessWidget {
  final bool isExpanded;
  final String userName;
  final String userEmail;
  final VoidCallback onTap;
  final VoidCallback onLogout;

  const _SidebarProfile({
    required this.isExpanded,
    required this.userName,
    required this.userEmail,
    required this.onTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isExpanded ? 12 : 8),
      child: isExpanded
          ? Row(
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userEmail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.logout_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                  onPressed: onLogout,
                  tooltip: 'Logout',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: Icon(Icons.logout_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                  onPressed: onLogout,
                  tooltip: 'Logout',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
