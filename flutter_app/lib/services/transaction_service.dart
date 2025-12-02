import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/api_config.dart';

class Transaction {
  final String id;
  final String from;
  final String to;
  final double amount;
  final double networkFee;
  final DateTime timestamp;
  final String status;
  final String? transactionHash;
  final bool isQueued;
  final int retryCount;

  Transaction({
    required this.id,
    required this.from,
    required this.to,
    required this.amount,
    required this.networkFee,
    required this.timestamp,
    required this.status,
    this.transactionHash,
    this.isQueued = false,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': from,
    'to': to,
    'amount': amount,
    'networkFee': networkFee,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'transactionHash': transactionHash,
    'isQueued': isQueued,
    'retryCount': retryCount,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      networkFee: _parseDouble(json['networkFee']),
      timestamp: _parseDateTime(json['timestamp']),
      status: json['status']?.toString() ?? 'unknown',
      transactionHash: json['transactionHash']?.toString(),
      isQueued: json['isQueued'] == true,
      retryCount: _parseInt(json['retryCount']),
    );
  }
  
  // Helper to parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  // Helper to parse int from various types
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  
  // Helper to parse DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

class TransactionService extends ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _transactionsKey = 'transactions';
  static const String _queueKey = 'transaction_queue';
  
  Timer? _retryTimer;
  bool _isSending = false;
  String? _lastError;
  
  bool get isSending => _isSending;
  String? get lastError => _lastError;
  
  TransactionService(this._prefs) {
    _startRetryTimer();
  }
  
  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
  
  void _startRetryTimer() {
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _processQueuedTransactions();
    });
  }
  
  List<Transaction> getTransactions() {
    try {
      final transactionsJson = _prefs.getStringList(_transactionsKey) ?? [];
      return transactionsJson
          .map((json) {
            try {
              return Transaction.fromJson(jsonDecode(json));
            } catch (e) {
              debugPrint('Error parsing transaction: $e');
              return null;
            }
          })
          .whereType<Transaction>()
          .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }
  
  List<Transaction> getQueuedTransactions() {
    try {
      final queueJson = _prefs.getStringList(_queueKey) ?? [];
      return queueJson
          .map((json) {
            try {
              return Transaction.fromJson(jsonDecode(json));
            } catch (e) {
              return null;
            }
          })
          .whereType<Transaction>()
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> addTransaction(Transaction transaction) async {
    final transactions = getTransactions();
    transactions.add(transaction);
    
    await _prefs.setStringList(
      _transactionsKey,
      transactions.map((t) => jsonEncode(t.toJson())).toList(),
    );
    
    notifyListeners();
  }
  
  Future<void> queueTransaction(Transaction transaction) async {
    final queued = getQueuedTransactions();
    queued.add(transaction);
    
    await _prefs.setStringList(
      _queueKey,
      queued.map((t) => jsonEncode(t.toJson())).toList(),
    );
    
    notifyListeners();
  }
  
  Future<void> _processQueuedTransactions() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;
    
    final queued = getQueuedTransactions();
    if (queued.isEmpty) return;
    
    for (final transaction in queued) {
      if (transaction.retryCount >= 3) continue; // Max 3 retries
      
      try {
        final success = await _sendTransactionToBackend(transaction);
        if (success) {
          await _removeFromQueue(transaction);
          await _updateTransactionStatus(transaction.id, 'completed');
        } else {
          await _incrementRetryCount(transaction);
        }
      } catch (e) {
        await _incrementRetryCount(transaction);
      }
    }
  }
  
  Future<bool> _sendTransactionToBackend(Transaction transaction) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from': transaction.from,
          'to': transaction.to,
          'amount': transaction.amount,
        }),
      ).timeout(ApiConfig.receiveTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending transaction: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> sendTransaction({
    required String from,
    required String to,
    required double amount,
  }) async {
    _isSending = true;
    _lastError = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from': from,
          'to': to,
          'amount': amount,
        }),
      ).timeout(ApiConfig.receiveTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Create and store the transaction
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          from: from,
          to: to,
          amount: amount,
          networkFee: 0.0,
          timestamp: DateTime.now(),
          status: 'completed',
          transactionHash: data['transactionId']?.toString(),
        );
        
        await addTransaction(transaction);
        
        _isSending = false;
        notifyListeners();
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        _lastError = errorData['error']?.toString() ?? 'Transaction failed';
        _isSending = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Send transaction error: $e');
      
      // Queue transaction for later if offline
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        from: from,
        to: to,
        amount: amount,
        networkFee: 0.0,
        timestamp: DateTime.now(),
        status: 'pending',
        isQueued: true,
      );
      
      await queueTransaction(transaction);
      await addTransaction(transaction);
      
      _isSending = false;
      notifyListeners();
      return {'queued': true, 'message': 'Transaction queued for later'};
    }
  }
  
  Future<void> _removeFromQueue(Transaction transaction) async {
    final queued = getQueuedTransactions();
    queued.removeWhere((t) => t.id == transaction.id);
    
    await _prefs.setStringList(
      _queueKey,
      queued.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }
  
  Future<void> _incrementRetryCount(Transaction transaction) async {
    final queued = getQueuedTransactions();
    final index = queued.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      queued[index] = Transaction(
        id: transaction.id,
        from: transaction.from,
        to: transaction.to,
        amount: transaction.amount,
        networkFee: transaction.networkFee,
        timestamp: transaction.timestamp,
        status: transaction.status,
        isQueued: transaction.isQueued,
        retryCount: transaction.retryCount + 1,
      );
      
      await _prefs.setStringList(
        _queueKey,
        queued.map((t) => jsonEncode(t.toJson())).toList(),
      );
    }
  }
  
  Future<void> _updateTransactionStatus(String transactionId, String status) async {
    final transactions = getTransactions();
    final index = transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      transactions[index] = Transaction(
        id: transactions[index].id,
        from: transactions[index].from,
        to: transactions[index].to,
        amount: transactions[index].amount,
        networkFee: transactions[index].networkFee,
        timestamp: transactions[index].timestamp,
        status: status,
        transactionHash: transactions[index].transactionHash,
        isQueued: false,
        retryCount: transactions[index].retryCount,
      );
      
      await _prefs.setStringList(
        _transactionsKey,
        transactions.map((t) => jsonEncode(t.toJson())).toList(),
      );
      
      notifyListeners();
    }
  }
  
  Future<bool> syncTransactions() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.historyEndpoint),
      ).timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Process and merge with local transactions if needed
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Sync transactions error: $e');
      return false;
    }
  }
  
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
  
  Future<void> clearAllTransactions() async {
    await _prefs.remove(_transactionsKey);
    await _prefs.remove(_queueKey);
    notifyListeners();
  }
}
