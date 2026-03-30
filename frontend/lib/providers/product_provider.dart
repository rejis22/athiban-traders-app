import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final box = await Hive.openBox<Product>('products');
      
      // Try fetching from API
      try {
        final response = await _apiService.client.get('/products');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          _products = data.map((json) => Product.fromJson(json)).toList();
          
          await box.clear();
          await box.addAll(_products);
        }
      } catch (e) {
        throw Exception('Failed to fetch products: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    final box = await Hive.openBox<Product>('products');
    
      try {
      final response = await _apiService.client.post('/products', data: product.toJson());
      if (response.statusCode == 201) {
        final newProduct = Product.fromJson(response.data);
        _products.add(newProduct);
        await box.add(newProduct);
      } else {
        throw Exception('Failed to add product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
    notifyListeners();
  }

  Future<void> updateProduct(Product updatedProduct) async {
    final box = await Hive.openBox<Product>('products');
    
    try {
      if (updatedProduct.id.isNotEmpty) {
        final response = await _apiService.client.put('/products/${updatedProduct.id}', data: updatedProduct.toJson());
        if (response.statusCode == 200) {
          final index = _products.indexWhere((p) => p.id == updatedProduct.id);
          if (index != -1) {
            _products[index] = Product.fromJson(response.data);
            await box.putAt(index, _products[index]);
            notifyListeners();
          }
        } else {
           throw Exception('Failed to update product');
        }
      }
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }
}
