import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryTile extends StatelessWidget {
  final String name;
  final String? image;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.name,
    this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Expanded image section to fill most of the card
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: _buildCategoryImage(),
              ),
            ),
            // Category name at the bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF151D51),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage() {
    // Use dummy image from assets if no image provided or if it's a network URL
    if (image == null || image!.isEmpty) {
      return _buildDummyImage();
    }

    // If it's a network URL, use CachedNetworkImage
    if (image!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: image!,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: double.infinity,
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildDummyImage(),
      );
    }

    // If it's an asset path, use Image.asset
    return Image.asset(
      image!,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildDummyImage(),
    );
  }

  Widget _buildDummyImage() {
    // Use dummy images from assets folder
    final dummyImages = [
      'assets/images/product0.png',
      'assets/images/product1.png',
      'assets/images/product2.png',
      'assets/images/product3.png',
      'assets/images/product4.png',
    ];
    
    // Use hash of name to pick a consistent dummy image
    final index = name.hashCode.abs() % dummyImages.length;
    
    return Image.asset(
      dummyImages[index],
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.grey,
        ),
        child: const Center(
          child: Icon(
            Icons.category,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }
}


