import 'package:hive/hive.dart';
import '../models/bill.dart';
import 'api_service.dart';

class SyncManager {
  final ApiService _apiService = ApiService();

  Future<void> syncUnsyncedBills() async {
    final box = await Hive.openBox<Bill>('bills');
    final unsynced = box.values.where((b) => !b.isSynced).toList();

    for (var bill in unsynced) {
      try {
        final response = await _apiService.client.post('/bills', data: bill.toJson());
        if (response.statusCode == 201) {
          bill.isSynced = true;
          bill.save(); // Save the updated status back to Hive
        }
      } catch (e) {
        print('Failed to sync bill ${bill.billNumber}: $e');
        // Will retry next time
      }
    }
  }
}
