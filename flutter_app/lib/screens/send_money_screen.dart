import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../services/transaction_service.dart';
import '../generated/l10n.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isProcessing = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate()) return;

    final recipient = _recipientController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    
    final walletService = Provider.of<WalletService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final transactionService = Provider.of<TransactionService>(context, listen: false);
    
    if (amount > walletService.balance) {
      setState(() {
        _errorMessage = AppLocalizations.current.insufficientBalance;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      final fromAddress = await authService.getWalletAddress();
      if (fromAddress == null) {
        throw Exception('Wallet address not found');
      }

      final networkFee = walletService.calculateNetworkFee(amount);
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        from: fromAddress,
        to: recipient,
        amount: amount,
        networkFee: networkFee,
        timestamp: DateTime.now(),
        status: 'pending',
        isQueued: true,
      );

      // Add to transaction history
      await transactionService.addTransaction(transaction);
      
      // Queue for sending
      await transactionService.queueTransaction(transaction);
      
      // Update balance (optimistic update)
      await walletService.updateBalance(walletService.balance - amount - networkFee);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.current.transactionQueued),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.current.error;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showConfirmationDialog() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final recipient = _recipientController.text.trim();
    final walletService = Provider.of<WalletService>(context, listen: false);
    final networkFee = walletService.calculateNetworkFee(amount);
    final total = amount + networkFee;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.current.confirmTransaction),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${AppLocalizations.current.to}:'),
                Text(recipient, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('${AppLocalizations.current.amountSent}: ${amount.toStringAsFixed(2)} SMR'),
                Text('${AppLocalizations.current.networkFee}: ${networkFee.toStringAsFixed(2)} SMR'),
                const Divider(),
                Text(
                  '${AppLocalizations.current.total}: ${total.toStringAsFixed(2)} SMR',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.current.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendMoney();
              },
              child: Text(AppLocalizations.current.confirm),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.current.sendMoney),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.current.balance,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${walletService.balance.toStringAsFixed(2)} SMR',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Recipient Address
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.current.recipientAddress,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  helperText: 'Enter 81-character IOTA address',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.current.enterRecipient;
                  }
                  if (!walletService.isValidAddress(value.trim())) {
                    return AppLocalizations.current.invalidAddress;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.current.amount,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'SMR',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.current.enterAmount;
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return AppLocalizations.current.invalidAmount;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Network Fee Info
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Zero network fees - powered by IOTA Shimmer',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _showConfirmationDialog();
                          }
                        },
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : Text(AppLocalizations.current.send),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}