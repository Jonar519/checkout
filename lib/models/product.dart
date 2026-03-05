class Product {
  final int? id;
  final String name;
  final double price;
  final String description;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? 'Producto sin nombre',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'] ?? 'Sin descripción',
    );
  }
}
