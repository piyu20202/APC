import 'package:flutter/material.dart';
import '../productlist_view/productlist.dart';
import '../../main_navigation.dart';

class CategoriesGridScreen extends StatefulWidget {
  const CategoriesGridScreen({super.key});

  @override
  State<CategoriesGridScreen> createState() => _CategoriesGridScreenState();
}

class _CategoriesGridScreenState extends State<CategoriesGridScreen> {
  final List<Map<String, dynamic>> allCategories = [
    {
      'name': 'Gas Automation Kits',
      'icon': 'assets/images/product1.png',
      'isImage': true,
    },
    {
      'name': 'Gate & Fencing Hardware',
      'icon': 'assets/images/product2.png',
      'isImage': true,
    },
    {
      'name': 'Brushless Electric Gate Kits',
      'icon': 'assets/images/product3.png',
      'isImage': true,
    },
    {
      'name': 'Brushless Electric Gate Kits',
      'icon': 'assets/images/product4.png',
      'isImage': true,
    },
    {
      'name': 'Premium Hardware for Cantilever, Sliding & Swing Gates',
      'icon': 'assets/images/product5.png',
      'isImage': true,
    },
    {
      'name': 'Gate, Automation & Hardware Combos',
      'icon': 'assets/images/product6.png',
      'isImage': true,
    },
    {
      'name': 'Gates & Gate Frames',
      'icon': 'assets/images/product7.png',
      'isImage': true,
    },
    {
      'name': 'Custom Made Gates',
      'icon': 'assets/images/product8.png',
      'isImage': true,
    },
    {
      'name': 'Boom Gates',
      'icon': 'assets/images/product9.png',
      'isImage': true,
    },
    {
      'name': 'Video Intercoms and Surveillance Systems',
      'icon': 'assets/images/product10.png',
      'isImage': true,
    },
    {'name': 'Remotes', 'icon': 'assets/images/product11.png', 'isImage': true},
    {
      'name': 'Access Control & Accessories',
      'icon': 'assets/images/product12.png',
      'isImage': true,
    },
    {
      'name': 'Replacement Parts, Power Supplies & Cables',
      'icon': 'assets/images/product12.png',
      'isImage': true,
    },
    {
      'name': 'Solar Equipment',
      'icon': 'assets/images/product13.png',
      'isImage': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Categories',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF2F0EF),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: allCategories.length,
              itemBuilder: (context, index) {
                final category = allCategories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TabBarWrapper(
                          showTabBar: true,
                          child: ProductListScreen(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              category['icon'] as String,
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            category['name'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF151D51),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
