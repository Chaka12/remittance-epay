import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/wallet_service.dart';
import '../generated/l10n.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _showChangePinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.current.changePin),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _oldPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.current.enterPin,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.current.pinCode,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.current.confirmPin,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _oldPinController.clear();
                _newPinController.clear();
                _confirmPinController.clear();
              },
              child: Text(AppLocalizations.current.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final oldPin = _oldPinController.text.trim();
                final newPin = _newPinController.text.trim();
                final confirmPin = _confirmPinController.text.trim();
                
                if (newPin != confirmPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.current.pinsDontMatch)),
                  );
                  return;
                }
                
                if (newPin.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.current.pinRequired)),
                  );
                  return;
                }
                
                final authService = Provider.of<AuthService>(context, listen: false);
                final success = await authService.changePin(oldPin, newPin);
                
                Navigator.pop(context);
                _oldPinController.clear();
                _newPinController.clear();
                _confirmPinController.clear();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.current.pinChanged)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.current.invalidPin)),
                  );
                }
              },
              child: Text(AppLocalizations.current.confirm),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.current.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                leading: Radio<String>(
                  value: 'en',
                  groupValue: languageService.locale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      languageService.setLanguage(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Sesotho'),
                leading: Radio<String>(
                  value: 'st',
                  groupValue: languageService.locale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      languageService.setLanguage(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWalletInfo() {
    final walletService = Provider.of<WalletService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.current.walletAddress),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your IOTA Shimmer wallet address:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  walletService.walletAddress ?? 'Not available',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(
                  'Balance: ${walletService.balance.toStringAsFixed(2)} SMR',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (walletService.walletAddress != null) {
                  Clipboard.setData(ClipboardData(text: walletService.walletAddress!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.current.addressCopied)),
                  );
                }
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.current.copyAddress),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.current.close),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.current.settings),
      ),
      body: ListView(
        children: [
          // Profile Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.current.profile,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(AppLocalizations.current.walletAddress),
            subtitle: const Text('View wallet details'),
            onTap: _showWalletInfo,
          ),
          
          const Divider(),
          
          // Security Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.current.security,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(AppLocalizations.current.changePin),
            subtitle: const Text('Change your PIN code'),
            onTap: _showChangePinDialog,
          ),
          
          const Divider(),
          
          // Preferences Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.current.settings,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.current.language),
            subtitle: Text(languageService.getCurrentLanguageName()),
            onTap: _showLanguageDialog,
          ),
          
          const Divider(),
          
          // Support Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.current.help,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(AppLocalizations.current.faq),
            subtitle: const Text('Frequently asked questions'),
            onTap: () {
              // Show FAQ dialog or navigate to FAQ screen
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(AppLocalizations.current.faq),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.current.whatIsIota,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'IOTA is a distributed ledger technology designed for the Internet of Things. It uses a directed acyclic graph (DAG) instead of a blockchain.',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.current.howItWorks,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'This app uses IOTA Shimmer network to send feeless transactions. Your PIN secures your wallet locally on your device.',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.current.fees,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'There are zero network fees when using IOTA Shimmer. This makes it perfect for remittances and microtransactions.',
                          ),
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
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.current.about),
            subtitle: const Text('About IOTA Remittance'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppLocalizations.current.appTitle,
                applicationVersion: '1.0.0',
                applicationLegalese: 'Powered by IOTA Shimmer Network',
              );
            },
          ),
          
          const Divider(),
          
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              AppLocalizations.current.logout,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.current.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout();
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}