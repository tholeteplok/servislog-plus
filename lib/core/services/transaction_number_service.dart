import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TrxNumberService {
  final SharedPreferences _prefs;

  TrxNumberService(this._prefs);

  Future<String> generateTrxNumber() async {
    final now = DateTime.now();
    final today = DateFormat('yyyyMMdd').format(now);

    // Get last count for today
    final key = 'trx_count_$today';
    int count = (_prefs.getInt(key) ?? 0) + 1;

    // Save new count
    await _prefs.setInt(key, count);

    // Format: SL-20260401-001
    final formattedCount = count.toString().padLeft(3, '0');
    return 'SL-$today-$formattedCount';
  }
}
