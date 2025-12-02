import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../generated/l10n.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _isSettingUp = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final pin = _pinController.text.trim();
    
    if (pin.length < 4) {
      setState(() {
        _errorMessage = AppLocalizations.current.pinRequired;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final walletService = Provider.of<WalletService>(context, listen: false);
      
      final success = await authService.login(pin);
      
      if (success) {
        // Generate wallet address if not exists
        final existingAddress = await authService.getWalletAddress();
        if (existingAddress == null) {
          await walletService.generateWalletAddress(pin);
          if (walletService.walletAddress != null) {
            await authService.setWalletAddress(walletService.walletAddress!);
          }
        } else {
          walletService.generateWalletAddress(pin);
        }
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _errorMessage = AppLocalizations.current.invalidPin;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.current.error;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSetup() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    
    if (pin.length < 4) {
      setState(() {
        _errorMessage = AppLocalizations.current.pinRequired;
      });
      return;
    }
    
    if (pin != confirmPin) {
      setState(() {
        _errorMessage = AppLocalizations.current.pinsDontMatch;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final walletService = Provider.of<WalletService>(context, listen: false);
      
      final success = await authService.login(pin);
      
      if (success) {
        // Generate wallet address
        await walletService.generateWalletAddress(pin);
        if (walletService.walletAddress != null) {
          await authService.setWalletAddress(walletService.walletAddress!);
        }
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.current.error;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                AppLocalizations.current.appTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.current.welcome,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              
              // PIN Input
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: AppLocalizations.current.enterPin,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              
              // Confirm PIN for first time setup
              FutureBuilder<bool>(
                future: authService.hasPin(),
                builder: (context, snapshot) {
                  if (snapshot.data == false) {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.current.confirmPin,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
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
                  onPressed: _isLoading ? null : () async {
                    final hasPin = await authService.hasPin();
                    if (hasPin) {
                      await _handleLogin();
                    } else {
                      await _handleSetup();
                    }
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(AppLocalizations.current.login),
                ),
              ),
              
              const SizedBox(height: 20),
              Text(
                'Powered by IOTA Shimmer',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}