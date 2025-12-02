import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class WalletService extends ChangeNotifier {
  String? _walletAddress;
  double _balance = 0.0;
  bool _isLoading = false;
  String? _error;
  
  String? get walletAddress => _walletAddress;
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchWalletInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.walletInfoEndpoint),
      ).timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parse address
        _walletAddress = data['address']?.toString();
        
        // Parse balance - handle multiple formats robustly
        _balance = _parseBalance(data['balance']);
        
        _error = null;
      } else {
        _error = 'Failed to fetch wallet info (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Network error: Unable to connect to server';
      debugPrint('WalletService error: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Robust balance parsing that handles multiple formats
  double _parseBalance(dynamic balanceData) {
    if (balanceData == null) return 0.0;
    
    // If balance is a map with 'total' field
    if (balanceData is Map) {
      final total = balanceData['total'];
      return _parseBalanceValue(total);
    }
    
    // If balance is directly a value
    return _parseBalanceValue(balanceData);
  }
  
  double _parseBalanceValue(dynamic value) {
    if (value == null) return 0.0;
    
    // Handle hex string (e.g., "0x0", "0x1234")
    if (value is String && value.startsWith('0x')) {
      try {
        final hexValue = value.substring(2);
        if (hexValue.isEmpty) return 0.0;
        final intValue = int.parse(hexValue, radix: 16);
        return intValue / 1000000.0; // Convert from micro units
      } catch (e) {
        debugPrint('Error parsing hex balance: $e');
        return 0.0;
      }
    }
    
    // Handle regular string number
    if (value is String) {
      return (double.tryParse(value) ?? 0.0) / 1000000.0;
    }
    
    // Handle int
    if (value is int) {
      return value / 1000000.0;
    }
    
    // Handle double
    if (value is double) {
      return value / 1000000.0;
    }
    
    return 0.0;
  }
  
  Future<Map<String, dynamic>?> getNetworkInfo() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.networkInfoEndpoint),
      ).timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Network info error: $e');
      return null;
    }
  }
  
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.healthEndpoint),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> updateBalance(double newBalance) async {
    _balance = newBalance;
    notifyListeners();
  }
  
  Future<double> fetchBalance() async {
    await fetchWalletInfo();
    return _balance;
  }
  
  bool isValidAddress(String address) {
    if (address.isEmpty) return false;
    
    // Shimmer testnet addresses start with 'smr1' or 'rms1'
    if (address.startsWith('smr1') || address.startsWith('rms1')) {
      return address.length >= 60 && address.length <= 100;
    }
    
    // Legacy IOTA addresses (81 characters, uppercase + 9)
    if (address.length == 81) {
      return RegExp(r'^[A-Z9]+$').hasMatch(address);
    }
    
    return false;
  }
  
  double calculateNetworkFee(double amount) {
    // IOTA/Shimmer transactions are feeless
    return 0.0;
  }
  
  String formatBalance(double balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(2)}M SMR';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(2)}K SMR';
    }
    return '${balance.toStringAsFixed(2)} SMR';
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
