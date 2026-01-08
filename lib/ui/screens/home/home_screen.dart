import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/ui/screens/dashboard/dashboard_screen.dart';
import 'package:crm_admin/ui/screens/user_management/user_registration_screen.dart';
import 'package:crm_admin/ui/screens/user_management/view_users_screen.dart';
import 'package:crm_admin/ui/screens/leads/add_lead_screen.dart';
import 'package:crm_admin/ui/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _checkUserRole() {
    final role = PrefManager.getRole() ?? 'ADMIN';
    setState(() {
      _isAdmin = role == 'ADMIN';
    });
  }

  List<Widget> get _screens {
    // Both admin and sub-admin can access all screens
    return [
      const DashboardScreen(),
      const UserRegistrationScreen(),
      const ViewUsersScreen(),
      const AddLeadScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    // Both admin and sub-admin see all tabs
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_add_outlined),
        activeIcon: Icon(Icons.person_add),
        label: 'Add Member',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.people_outline),
        activeIcon: Icon(Icons.people),
        label: 'Team',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        activeIcon: Icon(Icons.add_circle),
        label: 'Add Lead',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_circle_outlined),
        activeIcon: Icon(Icons.account_circle),
        label: 'Profile',
      ),
    ];
  }

  Future<bool> _onWillPop() async {
    // If not on dashboard, navigate to dashboard
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false; // Don't pop the route
    }

    // If on dashboard, show exit confirmation
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: _navItems,
          ),
        ),
      ),
    );
  }
}
