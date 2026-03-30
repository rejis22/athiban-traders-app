import 'package:hive/hive.dart';
import 'customer.dart';
import 'product.dart';

part 'bill.g.dart';

@HiveType(typeId: 2)
class BillItem extends HiveObject {
  @HiveField(0)
  Product? product; // Null if manual entry or offline without sync

  @HiveField(1)
  String productName;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  double price;

  @HiveField(4)
  double discount;

  @HiveField(5)
  double total;

  @HiveField(6)
  String hsnCode;

  @HiveField(7)
  double taxRate;

  @HiveField(8)
  double discountPercentage;

  @HiveField(9)
  double cgst;

  @HiveField(10)
  double sgst;

  @HiveField(11)
  double igst;

  BillItem({
    this.product,
    required this.productName,
    required this.quantity,
    required this.price,
    this.discount = 0.0,
    required this.total,
    this.hsnCode = '',
    this.taxRate = 18.0,
    this.discountPercentage = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      productName: json['productName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      hsnCode: json['hsnCode'] ?? '',
      taxRate: (json['taxRate'] ?? 18.0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      cgst: (json['cgst'] ?? 0).toDouble(),
      sgst: (json['sgst'] ?? 0).toDouble(),
      igst: (json['igst'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (product != null) 'product': product!.id,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'total': total,
      'hsnCode': hsnCode,
      'taxRate': taxRate,
      'discountPercentage': discountPercentage,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
    };
  }
}

@HiveType(typeId: 3)
class Bill extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String billNumber;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  Customer? customer;

  @HiveField(12)
  String? customerName;

  @HiveField(13)
  String? customerPhone;

  @HiveField(14)
  String? customerAddress;

  @HiveField(4)
  List<BillItem> items;

  @HiveField(5)
  double subTotal;

  @HiveField(6)
  double taxRate;

  @HiveField(7)
  double taxAmount;

  @HiveField(8)
  double discount;

  @HiveField(9)
  double roundOff;

  @HiveField(10)
  double grandTotal;

  @HiveField(11)
  bool isSynced;

  @HiveField(15)
  double cgst;

  @HiveField(16)
  double sgst;

  @HiveField(17)
  double igst;

  Bill({
    required this.id,
    required this.billNumber,
    required this.date,
    this.customer,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.subTotal,
    this.taxRate = 0.0,
    required this.taxAmount,
    this.discount = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    this.isSynced = true,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] ?? '',
      billNumber: json['billNumber'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      customer: json['customer'] != null && json['customer'] is Map ? Customer.fromJson(json['customer']) : null,
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerAddress: json['customerAddress'],
      items: (json['items'] as List?)?.map((item) => BillItem.fromJson(item)).toList() ?? [],
      subTotal: (json['subTotal'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      roundOff: (json['roundOff'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      isSynced: true,
      cgst: (json['cgst'] ?? 0).toDouble(),
      sgst: (json['sgst'] ?? 0).toDouble(),
      igst: (json['igst'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'billNumber': billNumber,
      'date': date.toIso8601String(),
      if (customer != null) 'customer': customer!.id,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerAddress != null) 'customerAddress': customerAddress,
      'items': items.map((i) => i.toJson()).toList(),
      'subTotal': subTotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'discount': discount,
      'roundOff': roundOff,
      'grandTotal': grandTotal,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
    };
  }
}
