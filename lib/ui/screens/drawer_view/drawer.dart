import 'package:flutter/material.dart';
import '../categories_view/categories_grid.dart';
import '../productlist_view/sale_products.dart';
import '../../../main_navigation.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _selectedTitle;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFF8F8F8),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 96,
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(color: Color(0xFFF8F8F8)),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      color: Color(0xFF101010),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            _buildItem(
              icon: Icons.local_fire_department,
              title: 'Sale',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TabBarWrapper(
                      showTabBar: true,
                      child: SaleProductsScreen(),
                    ),
                  ),
                );
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.settings_input_component,
              title: 'Gate Automation Kits',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.home_repair_service,
              title: 'Gate & Fencing Hardware',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.electric_bolt,
              title: 'Brushless Electric Gate Kits',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.handyman,
              title: 'Premium Hardware for Cantilever, Sliding & Swing Gates',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.auto_awesome_mosaic,
              title: 'Gate, Automation & Hardware Combos',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.door_sliding,
              title: 'Gates & Gate Frames',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.build_circle,
              title: 'Custom Made Gates',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.traffic,
              title: 'Boom Gates',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.videocam,
              title: 'Video Intercoms and Surveillance Systems',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.settings_remote,
              title: 'Remotes',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.security,
              title: 'Access Control & Accessories',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.power,
              title: 'Replacement Parts, Power Supplies & Cables',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.solar_power,
              title: 'Solar Equipment',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.add_circle_outline,
              title: '+ see all categories',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TabBarWrapper(
                      showTabBar: true,
                      child: CategoriesGridScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedTitle == title;
    return Container(
      color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.black : Color(0xFF101010),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Color(0xFF101010),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isSelected ? Colors.black54 : Color(0xFF101010),
        ),
        onTap: () {
          setState(() {
            _selectedTitle = title;
          });
          onTap();
        },
      ),
    );
  }

  Widget _buildSeparator() {
    return const Divider(color: Color(0xFF101010), height: 1);
  }
}
