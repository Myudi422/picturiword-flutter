import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinProvider with ChangeNotifier {
  int _coins = 0;
  int get coins => _coins;

  CoinProvider() {
    loadCoins();
  }

  Future<void> loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt('coins') ?? 0;
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    _coins += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (_coins >= amount) {
      _coins -= amount;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coins', _coins);
      notifyListeners();
      return true;
    }
    return false;
  }
}
