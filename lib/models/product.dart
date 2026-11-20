class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.categoryName,
    required this.sellerName,
    required this.imageUrl,
  });

  final int id;
  final String title;
  final String description;
  final int price;
  final String condition;
  final String categoryName;
  final String sellerName;
  final String? imageUrl;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        title: json['title'] as String? ?? 'Untitled product',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toInt() ?? 0,
        condition: json['condition'] as String? ?? 'good',
        categoryName: json['category_name'] as String? ?? 'Uncategorized',
        sellerName: json['seller_name'] as String? ?? 'GAIA seller',
        imageUrl: json['image_url'] as String?,
      );
}
