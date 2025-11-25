import 'package:flutter/material.dart';
import 'ui/screens/home_view/home.dart';
import 'ui/screens/cart_view/cart.dart';
import 'ui/screens/profile_page/profile_view.dart';
import 'ui/screens/wishlist_view/wishlist.dart';
import 'ui/screens/search_view/search.dart';
import 'services/user_role_service.dart';
import 'services/navigation_service.dart';
import 'services/storage_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isTrader = false;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3) {
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          return true;
        }
        return _maybeExitApp();
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _buildScreens()),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isTrader)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.orange.shade600,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Trade Account Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
                const BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.favorite),
                  label: 'Wishlist',
                ),
                BottomNavigationBarItem(
                  icon: _buildCartNavIcon(false),
                  activeIcon: _buildCartNavIcon(true),
                  label: 'Cart',
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
      ),
      const SearchScreen(),
      const WishlistScreen(),
      const CartPage(),
      const ProfileView(),
    ];
  }

  Widget _buildCartNavIcon(bool active) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          active ? Icons.shopping_cart : Icons.shopping_cart_outlined,
        ),
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
