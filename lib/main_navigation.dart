import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'ui/screens/home_view/home.dart';
import 'ui/screens/cart_view/cart.dart';
import 'ui/screens/profile_page/profile_view.dart';
import 'ui/screens/search_view/search.dart';
import 'ui/screens/manuals/manuals_menu.dart';
import 'services/user_role_service.dart';
import 'services/navigation_service.dart';
import 'services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainNavigationScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;
  bool _isTrader = false;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 5);
    NavigationService.instance.registerTabController(_onItemTapped);
    NavigationService.instance.registerCartCountRefresher(_loadCartCount);
    _checkTraderStatus();
    _loadCartCount();
  }

  Future<void> _checkTraderStatus() async {
    final isTrader = await UserRoleService.isTraderUser();
    setState(() {
      _isTrader = isTrader;
    });
  }

  Future<void> _loadCartCount() async {
    final cartData = await StorageService.getCartData();
    int count = 0;
    if (cartData != null) {
      if (cartData['cart'] is Map<String, dynamic>) {
        final cartMap = cartData['cart'] as Map<String, dynamic>;
        count = cartMap.values.fold(0, (sum, entry) {
          if (entry is Map<String, dynamic>) {
            final qty = entry['qty'];
            if (qty is num) return sum + qty.round();
            if (qty is String) return sum + (int.tryParse(qty) ?? 0);
          }
          return sum;
        });
      } else {
        count = (cartData['totalQty'] as num?)?.toInt() ?? 0;
      }
    }
    setState(() {
      _cartCount = count;
    });
  }

  Future<void> _makePhoneCall() async {
    final settings = await StorageService.getSettings();
    final phoneNumber = settings?.pageSettings.phone;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final formattedPhone = phoneNumber.replaceAll(' ', '');
      final uri = Uri.parse('tel:$formattedPhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available or cannot be dialed')),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      _makePhoneCall();
      return;
    }
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        _loadCartCount();
      }
    });
  }

  Future<bool> _maybeExitApp() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit app?'),
        content: const Text('Do you want to close the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  Future<void> _handleSystemBack() async {
    final shouldExit = await _maybeExitApp();
    if (!mounted) return;
    if (shouldExit) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return PopScope(
      canPop: navigator.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // We're at the root route: show exit confirmation.
        unawaited(_handleSystemBack());
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _buildScreens()),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: const Color(0xFF151D51),
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              elevation: 8,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: _buildCartNavIcon(false),
                  activeIcon: _buildCartNavIcon(true),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.help_outline),
                  activeIcon: Icon(Icons.help),
                  label: 'Manuals',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.phone_outlined),
                  activeIcon: Icon(Icons.phone),
                  label: 'Call Us',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        onSearchTap: () => _onItemTapped(1),
        cartCount: _cartCount,
        isActive: _selectedIndex == 0,
      ),
      const SearchScreen(),
      const CartPage(),
      const ManualsMenuPage(),
      const SizedBox.shrink(),
      const ProfileView(),
    ];
  }

  Widget _buildCartNavIcon(bool active) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(active ? Icons.shopping_cart : Icons.shopping_cart_outlined),
        if (_cartCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_cartCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
