import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/widgets/auth_wrapper.dart';
import '../../../features/deposits/presentation/pages/dashboard_page.dart';
import '../../../features/deposits/presentation/pages/deposit_form_page.dart';
import '../../../features/deposits/presentation/pages/deposit_details_page.dart';
import '../../../features/deposits/presentation/pages/matured_deposit_page.dart';
import '../../../features/deposits/presentation/pages/db_inspector_page.dart';
import '../../../features/deposits/presentation/pages/chain_details_page.dart';
import '../../../features/ocr/presentation/pages/ocr_capture_page.dart';
import '../../../features/ocr/presentation/pages/ocr_review_page.dart';
import '../../../features/search/presentation/pages/search_page.dart';
import '../../../features/analytics/presentation/pages/analytics_dashboard.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const AuthWrapper(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsDashboard(),
      ),
      GoRoute(
        path: '/deposit/new',
        name: 'new-deposit',
        builder: (context, state) => const DepositFormPage(),
      ),
      GoRoute(
        path: '/deposit/edit/:id',
        name: 'edit-deposit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DepositFormPage(depositId: id);
        },
      ),
      GoRoute(
        path: '/deposit/:id',
        name: 'deposit-details',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DepositDetailsPage(depositId: id);
        },
      ),
      GoRoute(
        path: '/deposit/matured/:id',
        name: 'matured-deposit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaturedDepositPage(depositId: id);
        },
      ),
      GoRoute(
        path: '/chain/:id',
        name: 'chain-details',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChainDetailsPage(chainId: id);
        },
      ),
      GoRoute(
        path: '/ocr/capture',
        name: 'ocr-capture',
        builder: (context, state) => const OcrCapturePage(),
      ),
      GoRoute(
        path: '/ocr/review',
        name: 'ocr-review',
        builder: (context, state) {
          final imagePath = state.uri.queryParameters['imagePath']!;
          return OcrReviewPage(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/debug/db',
        name: 'db-inspector',
        builder: (context, state) => const DbInspectorPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
