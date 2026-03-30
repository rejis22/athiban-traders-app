import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

class CustomerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Customer> _customers = [];
  bool _isLoading = false;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final box = await Hive.openBox<Customer>('customers');
      
      try {
        final response = await _apiService.client.get('/customers');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          _customers = data.map((json) => Customer.fromJson(json)).toList();
          
          await box.clear();
          await box.addAll(_customers);
        } else {
           throw Exception('Failed to load customers');
        }
      } catch (e) {
        throw Exception('API Error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    final box = await Hive.openBox<Customer>('customers');
    
    try {
      final response = await _apiService.client.post('/customers', data: customer.toJson());
      if (response.statusCode == 201) {
        final newCustomer = Customer.fromJson(response.data);
        _customers.add(newCustomer);
        await box.add(newCustomer);
      } else {
         throw Exception('Failed to add customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
    notifyListeners();
  }
}
