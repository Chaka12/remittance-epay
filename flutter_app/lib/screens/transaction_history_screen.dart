import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/transaction_service.dart';
import '../services/transaction_service.dart' as ts;
import '../generated/l10n.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshHistory() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final transactionService = Provider.of<TransactionService>(context, listen: false);
      await transactionService.syncTransactions();
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
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
                _buildDetailRow(AppLocalizations.current.transactionId, transaction.id),
                _buildDetailRow(AppLocalizations.current.from, transaction.from),
                _buildDetailRow(AppLocalizations.current.to, transaction.to),
                _buildDetailRow(AppLocalizations.current.amount, '${transaction.amount.toStringAsFixed(2)} SMR'),
                _buildDetailRow(AppLocalizations.current.networkFee, '${transaction.networkFee.toStringAsFixed(2)} SMR'),
                _buildDetailRow(AppLocalizations.current.date, transaction.timestamp.toString()),
                _buildDetailRow(AppLocalizations.current.status, transaction.status.toUpperCase()),
                if (transaction.transactionHash != null)
                  _buildDetailRow('Hash', transaction.transactionHash!),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionService = Provider.of<TransactionService>(context);
    final transactions = transactionService.getTransactions();
    final queuedTransactions = transactionService.getQueuedTransactions();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.current.transactionHistory),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: CustomScrollView(
          slivers: [
            if (queuedTransactions.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Queued Transactions',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...queuedTransactions.map((transaction) {
                        return Card(
                          color: Colors.orange[50],
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.pending, color: Colors.white),
                            ),
                            title: Text(
                              '${transaction.amount.toStringAsFixed(2)} SMR',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Retry: ${transaction.retryCount}/3',
                            ),
                            trailing: const Icon(Icons.sync),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            if (transactions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.current.noTransactions,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
n              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = transactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12.0),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(transaction.status),
                          child: Icon(
                            _getStatusIcon(transaction.status),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${transaction.amount.toStringAsFixed(2)} SMR',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.current.to}: ${transaction.to.substring(0, 15)}...',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year} ${transaction.timestamp.hour}:${transaction.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(transaction.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AppLocalizations.current.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getStatusColor(transaction.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (transaction.isQueued)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Icon(Icons.sync, size: 16, color: Colors.orange),
                              ),
                          ],
                        ),
                        onTap: () => _showTransactionDetails(transaction),
                      ),
                    );
                  },
                  childCount: transactions.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}