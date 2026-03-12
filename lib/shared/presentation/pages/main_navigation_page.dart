import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/deposits/presentation/pages/dashboard_page.dart';
import '../../../features/deposits/presentation/pages/db_inspector_page.dart';
import '../../../features/deposits/presentation/pages/lineage_page.dart';
import '../../../features/ocr/presentation/pages/ocr_capture_page.dart';
import '../../../features/analytics/presentation/pages/analytics_dashboard.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../features/deposits/presentation/widgets/deposit_search_delegate.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const AnalyticsDashboard(),
    const OcrCapturePage(),
    const LineagePage(),
    const DbInspectorPage(),
  ];

  final List<String> _pageTitles = [
    'Dashboard',
    'Analytics',
    'OCR Scan',
    'Lineage',
    'Database Inspector',
  ];

  final List<IconData> _pageIcons = [
    Icons.dashboard,
    Icons.analytics,
    Icons.camera_alt,
    Icons.account_tree,
    Icons.storage,
  ];

  String _getPageTitle() {
    return _pageTitles[_currentIndex];
  }

  IconData _getPageIcon() {
    return _pageIcons[_currentIndex];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              _getPageIcon(),
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _getPageTitle(),
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Masking toggle
          Consumer(
            builder: (context, ref, child) {
              final maskEnabled = ref.watch(settingsProvider).maskSensitiveData;
              return IconButton(
                icon: Icon(
                  maskEnabled ? Icons.visibility_off : Icons.visibility,
                  color: maskEnabled ? Colors.orange : null,
                ),
                onPressed: () => ref.read(settingsProvider.notifier).toggleMasking(),
                tooltip: maskEnabled ? 'Unhide sensitive data' : 'Hide sensitive data',
              );
            },
          ),
          // Search action
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DepositSearchDelegate(ref),
              );
            },
            tooltip: 'Search deposits',
          ),
          // Notifications action
          Badge(
            isLabelVisible: false, // TODO: Connect to actual notification count
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon')),
                );
              },
              tooltip: 'Notifications',
            ),
          ),
          // User menu
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile settings coming soon')),
                  );
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon')),
                  );
                  break;
                case 'logout':
                  await ref.read(authRepositoryProvider).signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ),
              ),
            ],
            child: authState.when(
              data: (user) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                  ],
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const Icon(Icons.person),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_outlined),
                activeIcon: Icon(Icons.camera_alt),
                label: 'OCR Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_tree_outlined),
                activeIcon: Icon(Icons.account_tree),
                label: 'Lineage',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.storage_outlined),
                activeIcon: Icon(Icons.storage),
                label: 'Database',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
