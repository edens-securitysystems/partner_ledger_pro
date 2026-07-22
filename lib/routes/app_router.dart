import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/pin_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/partners/screens/partners_list_screen.dart';
import '../features/partners/screens/partner_detail_screen.dart';
import '../features/partners/screens/partner_ledger_screen.dart';
import '../features/partners/screens/add_edit_partner_screen.dart';
import '../features/partners/screens/pending_approvals_screen.dart';
import '../features/transactions/screens/transactions_list_screen.dart';
import '../features/transactions/screens/add_edit_transaction_screen.dart';
import '../features/transactions/screens/transaction_detail_screen.dart';
import '../features/transactions/screens/filter_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/reports/screens/monthly_report_screen.dart';
import '../features/reports/screens/yearly_report_screen.dart';
import '../features/reports/screens/partner_report_screen.dart';
import '../features/reports/screens/cash_flow_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/profile_screen.dart';
import '../features/settings/screens/theme_screen.dart';
import '../features/settings/screens/backup_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/businesses/screens/businesses_screen.dart';
import '../features/businesses/screens/add_edit_business_screen.dart';
import 'main_scaffold.dart';

class RouteNames {
  RouteNames._();

  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const forgotPassword = 'forgot-password';
  static const pin = 'pin';
  static const dashboard = 'dashboard';
  static const partners = 'partners';
  static const partnerDetail = 'partner-detail';
  static const partnerLedger = 'partner-ledger';
  static const addPartner = 'add-partner';
  static const editPartner = 'edit-partner';
  static const transactions = 'transactions';
  static const addTransaction = 'add-transaction';
  static const editTransaction = 'edit-transaction';
  static const transactionDetail = 'transaction-detail';
  static const transactionFilter = 'transaction-filter';
  static const reports = 'reports';
  static const monthlyReport = 'monthly-report';
  static const yearlyReport = 'yearly-report';
  static const partnerReport = 'partner-report';
  static const cashFlowReport = 'cash-flow-report';
  static const settings = 'settings';
  static const profileSettings = 'profile-settings';
  static const themeSettings = 'theme-settings';
  static const backupSettings = 'backup-settings';
  static const notifications = 'notifications';
  static const search = 'search';
  static const businesses = 'businesses';
  static const addBusiness = 'add-business';
  static const editBusiness = 'edit-business';
  static const pendingApprovals = 'pending-approvals';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class _AuthRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _authRefreshProvider = Provider<_AuthRefreshNotifier>((ref) {
  final notifier = _AuthRefreshNotifier();
  ref.listen(authProvider, (_, __) => notifier.notify());
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authProvider);
  final refreshNotifier = ref.watch(_authRefreshProvider);
  final authState = ref.watch(authProvider);
  final isAuthenticated = authState.status == AuthStatus.authenticated;
  final isChecking = authState.status == AuthStatus.initial;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: AppConfig.instance.isDebugMode,
    refreshListenable: refreshNotifier,

    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/pin' ||
          location == '/splash';

      if (location == '/splash') return null;
      if (isChecking) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/login',
        name: RouteNames.login,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildAuthPage(const LoginScreen(), state),
      ),

      GoRoute(
        path: '/register',
        name: RouteNames.register,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildAuthPage(const RegisterScreen(), state),
      ),

      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildAuthPage(const ForgotPasswordScreen(), state),
      ),

      GoRoute(
        path: '/pin',
        name: RouteNames.pin,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildAuthPage(const PinScreen(), state),
      ),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),

          GoRoute(
            path: '/partners',
            name: RouteNames.partners,
            builder: (context, state) => const PartnersListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: RouteNames.addPartner,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AddEditPartnerScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                name: RouteNames.editPartner,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => AddEditPartnerScreen(
                  partnerId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: ':id',
                name: RouteNames.partnerDetail,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => PartnerDetailScreen(
                  partnerId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'ledger',
                    name: RouteNames.partnerLedger,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => PartnerLedgerScreen(
                      partnerId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          GoRoute(
            path: '/transactions',
            name: RouteNames.transactions,
            builder: (context, state) => const TransactionsListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: RouteNames.addTransaction,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AddEditTransactionScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                name: RouteNames.editTransaction,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => AddEditTransactionScreen(
                  transaction: state.extra as dynamic,
                ),
              ),
              GoRoute(
                path: 'filter',
                name: RouteNames.transactionFilter,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => FilterScreen(
                  currentFilter: state.extra as dynamic,
                ),
              ),
              GoRoute(
                path: ':id',
                name: RouteNames.transactionDetail,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => TransactionDetailScreen(
                  transactionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          GoRoute(
            path: '/reports',
            name: RouteNames.reports,
            builder: (context, state) => const ReportsScreen(),
            routes: [
              GoRoute(
                path: 'monthly',
                name: RouteNames.monthlyReport,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const MonthlyReportScreen(),
              ),
              GoRoute(
                path: 'yearly',
                name: RouteNames.yearlyReport,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const YearlyReportScreen(),
              ),
              GoRoute(
                path: 'partner',
                name: RouteNames.partnerReport,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const PartnerReportScreen(),
              ),
              GoRoute(
                path: 'cash-flow',
                name: RouteNames.cashFlowReport,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CashFlowScreen(),
              ),
            ],
          ),

          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: RouteNames.profileSettings,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'theme',
                name: RouteNames.themeSettings,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ThemeScreen(),
              ),
              GoRoute(
                path: 'backup',
                name: RouteNames.backupSettings,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const BackupScreen(),
              ),
            ],
          ),

          GoRoute(
            path: '/notifications',
            name: RouteNames.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),

          GoRoute(
            path: '/pending-approvals',
            name: RouteNames.pendingApprovals,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const PendingApprovalsScreen(),
          ),

          GoRoute(
            path: '/search',
            name: RouteNames.search,
            builder: (context, state) => const _PlaceholderScreen(
              icon: Icons.search_rounded,
              title: 'Search',
            ),
          ),

          GoRoute(
            path: '/businesses',
            name: RouteNames.businesses,
            builder: (context, state) => const BusinessesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: RouteNames.addBusiness,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AddEditBusinessScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                name: RouteNames.editBusiness,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => AddEditBusinessScreen(
                  businessId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
    ],

    errorPageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: const NotFoundScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
});

Page<void> _buildAuthPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeIn)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
              ),
              const SizedBox(height: 24),
              Text(
                'Page Not Found',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'The page you are looking for does not exist.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;

  const _PlaceholderScreen({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
