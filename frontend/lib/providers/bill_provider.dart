import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/bill.dart';
import '../services/api_service.dart';

class BillProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Bill> _bills = [];
  bool _isLoading = false;

  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;

  Future<void> fetchBills() async {
    _isLoading = true;
    notifyListeners();

    try {
      final box = await Hive.openBox<Bill>('bills');
      
      try {
        final response = await _apiService.client.get('/bills');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          final serverBills = data.map((json) => Bill.fromJson(json)).toList();
          
          await box.clear();
          await box.addAll(serverBills);
          
          _bills = [...serverBills];
        } else {
           throw Exception('Failed to load bills');
        }
      } catch (e) {
        throw Exception('API sync error: $e');
      }
    } finally {
      // Sort descending by date
      _bills.sort((a, b) => b.date.compareTo(a.date));
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBill(Bill bill) async {
    final box = await Hive.openBox<Bill>('bills');
    
    try {
      final response = await _apiService.client.post('/bills', data: bill.toJson());
      if (response.statusCode == 201) {
        bill.isSynced = true;
        bill.id = response.data['_id'] ?? bill.id;
        _bills.insert(0, bill);
        await box.add(bill);
      } else {
         throw Exception('Checkout rejected by server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
    notifyListeners();
  }
}
