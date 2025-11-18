import 'package:flutter/material.dart';

class CartItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onQuantityDecrease;
  final VoidCallback onQuantityIncrease;
  final VoidCallback onDelete;

  const CartItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onQuantityDecrease,
    required this.onQuantityIncrease,
    required this.onDelete,
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitPrice = (widget.item['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (widget.item['quantity'] as num?)?.toInt() ?? 1;
    final subtotal = unitPrice * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top-right delete button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: widget.onDelete,
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[400],
                size: 20,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _buildProductImage(),
                ),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        right: 35,
                      ), // Space for delete button
                      child: Text(
                        widget.item['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.3, // Line height for better spacing
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if ((widget.item['sku'] as String?) != null &&
                        (widget.item['sku'] as String).isNotEmpty)
                      Text(
                        '(SKU: ${widget.item['sku']})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),

                    // Kit Includes section - Expandable
                    if (widget.item['type'] == 'kit' &&
                        widget.item['kitItems'] != null &&
                        (widget.item['kitItems'] as List).isNotEmpty) ...[
                      GestureDetector(
                        onTap: _toggleExpansion,
                        child: Row(
                          children: [
                            Text(
                              _isExpanded
                                  ? 'Hide Kit Includes ▲'
                                  : 'View Kit Includes ▼',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF151D51),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizeTransition(
                        sizeFactor: _expandAnimation,
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            ...List<Widget>.from(
                              ((widget.item['kitItems'] as List<dynamic>?) ??
                                      [])
                                  .map((kit) {
                                    final String numStr =
                                        (kit['num']?.toString() ?? '').padLeft(
                                          2,
                                          '0',
                                        );
                                    final String nameStr =
                                        (kit['name']?.toString() ?? '');
                                    final String skuStr =
                                        (kit['sku']?.toString() ?? '');
                                    final int qty = (kit['qty'] as int?) ?? 1;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              color: Colors.orange,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                numStr,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nameStr,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF151D51),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (skuStr.isNotEmpty)
                                                  Text(
                                                    'SKU: $skuStr',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(QTY: $qty)',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF151D51),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],

                    // Price section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unit Price (GST Incl.)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Sub Total (GST Incl.)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF151D51),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quantity Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: widget.onQuantityDecrease,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              quantity.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.onQuantityIncrease,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    final imagePath = widget.item['image'] as String?;
    final fallbackImage = widget.item['defaultImage'] as String?;

    Widget buildNetworkImage(String url, {String? fallbackUrl}) {
      return Image.network(
        url,
        width: double.infinity,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (fallbackUrl != null &&
              fallbackUrl.isNotEmpty &&
              fallbackUrl != url) {
            return Image.network(
              fallbackUrl,
              width: double.infinity,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error2, stackTrace2) {
                return _buildPlaceholderImage();
              },
            );
          }
          return _buildPlaceholderImage();
        },
      );
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http')) {
        return buildNetworkImage(imagePath, fallbackUrl: fallbackImage);
      } else if (imagePath.startsWith('assets/')) {
        return Image.asset(
          imagePath,
          width: double.infinity,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      }
    }

    if (fallbackImage != null && fallbackImage.isNotEmpty) {
      return buildNetworkImage(fallbackImage);
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, color: Colors.grey[400], size: 40),
      ),
    );
  }
}
