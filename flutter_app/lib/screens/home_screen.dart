import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../services/transaction_service.dart';
import '../generated/l10n.dart';
import '../services/transaction_service.dart' as ts;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final walletService = Provider.of<WalletService>(context, listen: false);
    await walletService.fetchBalance();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final transactionService = Provider.of<TransactionService>(context, listen: false);
      final walletService = Provider.of<WalletService>(context, listen: false);
      
      await Future.wait([
        transactionService.syncTransactions(),
        walletService.fetchBalance(),
      ]);
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _copyAddress() {
    final walletService = Provider.of<WalletService>(context, listen: false);
    if (walletService.walletAddress != null) {
      Clipboard.setData(ClipboardData(text: walletService.walletAddress!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.current.addressCopied)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final walletService = Provider.of<WalletService>(context);
    final transactionService = Provider.of<TransactionService>(context);
    
    final recentTransactions = transactionService.getTransactions().take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.current.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.current.balance,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${walletService.balance.toStringAsFixed(2)} SMR',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              walletService.walletAddress ?? 'Generating...',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_copy, size: 16),
                            onPressed: _copyAddress,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              Text(
                AppLocalizations.current.sendMoney,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text(AppLocalizations.current.sendMoney),
                      onPressed: () {
                        Navigator.pushNamed(context, '/send');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.history),
                      label: Text(AppLocalizations.current.transactionHistory),
                      onPressed: () {
                        Navigator.pushNamed(context, '/history');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent Transactions
              Text(
                AppLocalizations.current.transactionHistory,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (recentTransactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      AppLocalizations.current.noTransactions,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Column(
                  children: recentTransactions.map((transaction) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: transaction.status == 'completed'
                              ? Colors.green
                              : transaction.status == 'pending'
                                  ? Colors.orange
                                  : Colors.red,
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                        title: Text(
                          '${transaction.amount.toStringAsFixed(2)} SMR',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${AppLocalizations.current.to}: ${transaction.to.substring(0, 10)}...',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              transaction.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: transaction.status == 'completed'
                                    ? Colors.green
                                    : transaction.status == 'pending'
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showTransactionDetails(transaction);
                        },
                      ),
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 20),
              
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/history');
                  },
                  child: Text(AppLocalizations.current.viewAll),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(ts.Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.current.transactionDetails),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${AppLocalizations.current.transactionId}: ${transaction.id}'),
                const SizedBox(height: 8),
                Text('${AppLocalizations.current.from}: ${transaction.from.substring(0, 20)}...'),
                const SizedBox(height: 8),
                Text('${AppLocalizations.current.to}: ${transaction.to.substring(0, 20)}...'),
                const SizedBox(height: 8),
                Text('${AppLocalizations.current.amount}: ${transaction.amount.toStringAsFixed(2)} SMR'),
                const SizedBox(height: 8),
                Text('${AppLocalizations.current.networkFee}: ${transaction.networkFee.toStringAsFixed(2)} SMR'),
                const SizedBox(height: 8),
                Text('${AppLocalizations.current.date}: ${transaction.timestamp.toString()}'),
                const SizedBox(height: 8),
                Text('${AppLocalizations.current.status}: ${transaction.status.toUpperCase()}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.current.close),
            ),
          ],
        );
      },
    );
  }
}