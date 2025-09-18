import 'package:flutter/material.dart';
import '../detail_view/detail_view.dart';
import '../widget/product_card.dart';

class ProductListScreen extends StatefulWidget {
	const ProductListScreen({super.key});

	@override
	State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
	final List<Map<String, dynamic>> products = [
		{
			'name': '3m Double Ring Top Gates (2x1.5m)',
			'sku': 'APC-RCTG-001',
			'description': 'Classic Design Ring Top Gate, Satin Black Powdercoating, Robust 80x40 - 40x40 Steel + 19mm Pickets',
			'currentPrice': '\$825.00',
			'originalPrice': '\$999.00',
			'image': 'assets/images/2.png',
			'category': 'RING 3M',
			'onSale': true,
			'freightDelivery': true,
		},
		{
			'name': '4m Double Ring Top Gates (2x2m)',
			'sku': 'APC-RCTG-002',
			'description': 'Premium Ring Top Gate Design, Black Powdercoating, Heavy Duty Steel Construction',
			'currentPrice': '\$950.00',
			'originalPrice': '\$1,199.00',
			'image': 'assets/images/2.png',
			'category': 'RING 4M',
			'onSale': true,
			'freightDelivery': true,
		},
		{
			'name': '3m Single Ring Top Gate',
			'sku': 'APC-RCTG-003',
			'description': 'Elegant Single Ring Design, Weather Resistant Coating, Durable Steel Frame',
			'currentPrice': '\$650.00',
			'originalPrice': '\$750.00',
			'image': 'assets/images/2.png',
			'category': 'RING 3M',
			'onSale': false,
			'freightDelivery': true,
		},
		{
			'name': '5m Double Ring Top Gates (2.5x2m)',
			'description': 'Large Scale Ring Top Gate, Industrial Grade Steel, Professional Installation Ready',
			'currentPrice': '\$1,250.00',
			'originalPrice': '\$1,450.00',
			'image': 'assets/images/2.png',
			'category': 'RING 5M',
			'onSale': true,
			'freightDelivery': true,
		},
		{
			'name': '2m Ring Top Gate Kit',
			'description': 'Complete Gate Kit with Hardware, Easy Installation, Residential Grade',
			'currentPrice': '\$450.00',
			'originalPrice': '\$550.00',
			'image': 'assets/images/2.png',
			'category': 'RING 2M',
			'onSale': true,
			'freightDelivery': false,
		},
	];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.grey[50],
			appBar: AppBar(
				title: const Text(
					'Product List',
					style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
				),
				backgroundColor: const Color(0xFFF2F0EF),
				elevation: 0,
				iconTheme: const IconThemeData(color: Colors.black),
			),
			body: GridView.builder(
				padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
				gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
					crossAxisCount: 2,
					childAspectRatio: 0.45,
					crossAxisSpacing: 16,
					mainAxisSpacing: 16,
				),
				itemCount: products.length,
				itemBuilder: (context, index) {
					final product = products[index];
					return ProductCard(product: product);
				},
			),
		);
	}
}
