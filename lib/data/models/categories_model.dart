/// Model for the full categories API response
class CategoriesResponse {
  final List<CategoryFull> categories;

  CategoriesResponse({required this.categories});

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    return CategoriesResponse(
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => CategoryFull.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Full category model with all nested data
class CategoryFull {
  final int id;
  final String name;
  final String slug;
  final String photo;
  final String image;
  final String pageOpen;
  final String? categorySlugUrl;
  final List<SubCategoryFull> subs;

  CategoryFull({
    required this.id,
    required this.name,
    required this.slug,
    required this.photo,
    required this.image,
    required this.pageOpen,
    this.categorySlugUrl,
    required this.subs,
  });

  factory CategoryFull.fromJson(Map<String, dynamic> json) {
    return CategoryFull(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      pageOpen: json['page_open']?.toString() ?? '',
      categorySlugUrl: json['category_slug_url']?.toString(),
      subs: (json['subs'] as List<dynamic>?)
              ?.map((item) => SubCategoryFull.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Subcategory model with children
class SubCategoryFull {
  final int id;
  final String name;
  final String? subImage;
  final String slug;
  final int status;
  final int categoryId;
  final List<ChildCategoryFull> childs;

  SubCategoryFull({
    required this.id,
    required this.name,
    this.subImage,
    required this.slug,
    required this.status,
    required this.categoryId,
    required this.childs,
  });

  factory SubCategoryFull.fromJson(Map<String, dynamic> json) {
    return SubCategoryFull(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      subImage: json['sub_image']?.toString(),
      slug: json['slug']?.toString() ?? '',
      status: json['status'] is int ? json['status'] : int.tryParse('${json['status']}') ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse('${json['category_id']}') ?? 0,
      childs: (json['childs'] as List<dynamic>?)
              ?.map((item) => ChildCategoryFull.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Child category model with childsubs
class ChildCategoryFull {
  final int id;
  final String name;
  final String? childImage;
  final String slug;
  final int status;
  final int subcategoryId;
  final List<ChildSubCategoryFull> childsubs;

  ChildCategoryFull({
    required this.id,
    required this.name,
    this.childImage,
    required this.slug,
    required this.status,
    required this.subcategoryId,
    required this.childsubs,
  });

  factory ChildCategoryFull.fromJson(Map<String, dynamic> json) {
    return ChildCategoryFull(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      childImage: json['child_image']?.toString(),
      slug: json['slug']?.toString() ?? '',
      status: json['status'] is int ? json['status'] : int.tryParse('${json['status']}') ?? 0,
      subcategoryId: json['subcategory_id'] is int ? json['subcategory_id'] : int.tryParse('${json['subcategory_id']}') ?? 0,
      childsubs: (json['childsubs'] as List<dynamic>?)
              ?.map((item) => ChildSubCategoryFull.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Child subcategory model (nested level)
class ChildSubCategoryFull {
  final int id;
  final String name;
  final String? childsubImage;
  final String slug;
  final int status;
  final int childcategoryId;

  ChildSubCategoryFull({
    required this.id,
    required this.name,
    this.childsubImage,
    required this.slug,
    required this.status,
    required this.childcategoryId,
  });

  factory ChildSubCategoryFull.fromJson(Map<String, dynamic> json) {
    return ChildSubCategoryFull(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      childsubImage: json['childsub_image']?.toString(),
      slug: json['slug']?.toString() ?? '',
      status: json['status'] is int ? json['status'] : int.tryParse('${json['status']}') ?? 0,
      childcategoryId: json['childcategory_id'] is int ? json['childcategory_id'] : int.tryParse('${json['childcategory_id']}') ?? 0,
    );
  }
}

