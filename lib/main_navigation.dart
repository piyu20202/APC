import 'package:flutter/material.dart';
import 'page/home_view/home.dart';
import 'page/cart_view/cart.dart';
import 'page/manuals/manuals_menu.dart';
import 'page/signin_view/signin.dart';
import 'page/profile_page/profile_view.dart';
import 'page/wishlist_view/wishlist.dart';
import 'page/search_view/search.dart';
import 'services/user_role_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isTrader = false;

  // List of screens for each tab
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _checkTraderStatus();
    _screens = [
      HomeScreen(onSearchTap: () => _onItemTapped(1)),
      const SearchScreen(),
      const WishlistScreen(),
      const CartPage(),
      const ManualsMenuPage(),
      const ProfileView(),
    ];
  }

  Future<void> _checkTraderStatus() async {
    final isTrader = await UserRoleService.isTraderUser();
    setState(() {
      _isTrader = isTrader;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trader status indicator
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Wishlist',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Wrapper widget to handle TabBar visibility based on route
class TabBarWrapper extends StatefulWidget {
  final Widget child;
  final bool showTabBar;

  const TabBarWrapper({super.key, required this.child, this.showTabBar = true});

  @override
  State<TabBarWrapper> createState() => _TabBarWrapperState();
}

class _TabBarWrapperState extends State<TabBarWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: widget.showTabBar ? _buildTabBar() : null,
    );
  }

  Widget _buildTabBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0, // Default to Home tab
      onTap: (index) {
        // Handle tab navigation
        switch (index) {
          case 0:
            // Home - already here
            break;
          case 1:
            // Search
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TabBarWrapper(
                  showTabBar: true,
                  child: SearchScreen(),
                ),
              ),
            );
            break;
          case 2:
            // Wishlist
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TabBarWrapper(
                  showTabBar: true,
                  child: WishlistScreen(),
                ),
              ),
            );
            break;
          case 3:
            // Cart
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const TabBarWrapper(showTabBar: true, child: CartPage()),
              ),
            );
            break;
          case 4:
            // Profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const TabBarWrapper(showTabBar: true, child: ProfileView()),
              ),
            );
            break;
        }
      },
      selectedItemColor: const Color(0xFF151D51),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          activeIcon: Icon(Icons.favorite),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

// Placeholder screens for tabs that don't have existing screens

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your account and settings',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to actual sign in page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SigninScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
