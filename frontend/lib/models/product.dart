import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String code;

  @HiveField(2)
  String name;

  @HiveField(3)
  String unit;

  @HiveField(4)
  double price;

  @HiveField(5)
  int stock;

  @HiveField(6)
  String hsnCode;

  @HiveField(7)
  double taxRate;

  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.price,
    this.stock = 0,
    this.hsnCode = '',
    this.taxRate = 18.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: (json['stock'] ?? 0).toInt(),
      hsnCode: json['hsnCode'] ?? '',
      taxRate: (json['taxRate'] ?? 18.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'code': code,
      'name': name,
      'unit': unit,
      'price': price,
      'stock': stock,
      'hsnCode': hsnCode,
      'taxRate': taxRate,
    };
  }
}
