import 'package:shared_preferences/shared_preferences.dart';

class UserRoleService {
  static const String _isTraderKey = 'is_trader_user';
  static const String _traderActivationDateKey = 'trader_activation_date';
  
  // Check if user is a trader
  static Future<bool> isTraderUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isTraderKey) ?? false;
    } catch (e) {
      // Return false if there's any error
      return false;
    }
  }
  
  // Set user as trader
  static Future<void> setAsTrader() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isTraderKey, true);
      await prefs.setString(_traderActivationDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Handle error silently or throw if needed
      rethrow;
    }
  }
  
  // Remove trader status
  static Future<void> removeTraderStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isTraderKey);
    await prefs.remove(_traderActivationDateKey);
  }
  
  // Get trader activation date
  static Future<DateTime?> getTraderActivationDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_traderActivationDateKey);
    if (dateString != null) {
      return DateTime.tryParse(dateString);
    }
    return null;
  }
  
  // Get trader status info
  static Future<Map<String, dynamic>> getTraderStatusInfo() async {
    final isTrader = await isTraderUser();
    final activationDate = await getTraderActivationDate();
    
    return {
      'isTrader': isTrader,
      'activationDate': activationDate,
      'daysAsTrader': activationDate != null 
          ? DateTime.now().difference(activationDate).inDays 
          : 0,
    };
  }
}
