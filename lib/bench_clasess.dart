class Product {
  final String name;
  final String description;
  final double price;

  Product({
    required this.name,
    required this.description,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        name: json['name'] as String,
        description: json['description'] as String,
        price: json['price'] as double,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price,
      };
}

class BenchmarkData {
  final String name;
  final int id;
  final double price;
  final bool isActive;
  final List<String> colors;
  final Map<String, int> sizes;
  final DateTime createdAt;
  final Uri imageUrl;
  final List<Product> products;

  // Add more fields here as needed for your benchmark

  BenchmarkData({
    required this.name,
    required this.id,
    required this.price,
    required this.isActive,
    required this.colors,
    required this.sizes,
    required this.createdAt,
    required this.imageUrl,
    required this.products,
  });

  factory BenchmarkData.fromJson(Map<String, dynamic> json) => BenchmarkData(
        name: json['name'] as String,
        id: json['id'] as int,
        price: json['price'] as double,
        isActive: json['isActive'] as bool,
        colors: (json['colors'] as List<dynamic>).cast<String>(),
        sizes: (json['sizes'] as Map<String, dynamic>).cast<String, int>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        imageUrl: Uri.parse(json['imageUrl'] as String),
        products: (json['products'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((productJson) => Product.fromJson(productJson))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'id': id,
        'price': price,
        'isActive': isActive,
        'colors': colors,
        'sizes': sizes,
        'createdAt': createdAt.toIso8601String(),
        'imageUrl': imageUrl.toString(),
        'products': products.map((product) => product.toJson()).toList(),
      };
}

class BenchmarkDataList {
  final List<BenchmarkData> data;

  BenchmarkDataList({required this.data});

  factory BenchmarkDataList.fromJson(Map<String, dynamic> json) => BenchmarkDataList(
        data: (json['data'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((dataItem) => BenchmarkData.fromJson(dataItem))
            .toList(),
      );

  Map<String, dynamic> toJson() => {'data': data.map((d) => d.toJson()).toList()};
}
