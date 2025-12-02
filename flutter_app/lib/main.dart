import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/transaction_service.dart';
import 'services/wallet_service.dart';
import 'services/language_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/send_money_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/settings_screen.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(prefs)),
        ChangeNotifierProvider(create: (_) => TransactionService(prefs)),
        ChangeNotifierProvider(create: (_) => WalletService()),
        ChangeNotifierProvider(create: (_) => LanguageService(prefs)),
      ],
      child: const IotaRemittanceApp(),
    ),
  );
}

class IotaRemittanceApp extends StatelessWidget {
  const IotaRemittanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    
    return MaterialApp(
      title: 'IOTA Remittance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'OpenSans',
        useMaterial3: false,
      ),
      locale: languageService.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('st'),
      ],
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/send': (context) => const SendMoneyScreen(),
        '/history': (context) => const TransactionHistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return FutureBuilder<bool>(
      future: authService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.data == true) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}