# IOTA/Shimmer Remittance MVP for Lesotho

## Overview
This is a complete zero-cost remittance application built with Flutter (mobile app) and Node.js (backend API), leveraging the IOTA Shimmer network for feeless transactions. The application is designed for the Lesotho market with dual language support (English and Sesotho).

## Project Structure

```
iota-remittance-mvp/
├── backend/                  # Node.js Express API
│   ├── server.js            # Main API server
│   ├── generate-wallet.js   # Wallet generation script
│   ├── package.json         # Node.js dependencies
│   ├── .env                 # Environment variables (auto-generated)
│   └── wallet-db/           # IOTA wallet database
├── flutter_app/             # Flutter mobile application
│   ├── lib/
│   │   ├── screens/         # UI screens
│   │   ├── services/        # Business logic
│   │   └── l10n/            # Localization (English & Sesotho)
│   └── pubspec.yaml         # Flutter dependencies
└── replit.md                # This file
```

## Recent Changes (Import to Replit)

### Date: November 27, 2025
- **Migrated IOTA SDK**: Updated from `@iota/iota-sdk@1.4.0` to `@iota/sdk@1.1.5` for compatibility
- **Updated API calls**: Modified wallet initialization and account management to work with new SDK version
- **Added system dependencies**: Installed `systemd` package for `libudev` support required by IOTA SDK native bindings
- **Enhanced error handling**: Added graceful handling for network unavailability (common in Replit environment)
- **Created .env file**: Auto-generated wallet mnemonic and configuration
- **Configured deployment**: Set up VM deployment for persistent backend API
- **Added .gitignore**: Comprehensive ignore patterns for Node.js and Flutter

## Backend API

### Technology Stack
- **Runtime**: Node.js 20
- **Framework**: Express.js
- **Blockchain SDK**: @iota/sdk 1.1.5 (Shimmer testnet)
- **Port**: 5000

### Available Endpoints
- `GET /health` - Health check
- `GET /wallet-info` - Get wallet address and balance
- `POST /send` - Send IOTA transaction
- `GET /history` - Get transaction history
- `GET /network-info` - Get network status

### Environment Variables
The backend requires a `MNEMONIC` environment variable which is auto-generated during setup. The `.env` file contains:
- `MNEMONIC`: Wallet seed phrase (keep secure!)
- `PORT`: Server port (default: 3000)
- `IOTA_NETWORK`: Network type (testnet)
- `NODE_URL`: Shimmer testnet node URL

### Running the Backend
The backend workflow "Backend API Server" is configured to run automatically. It starts the API server on port 3000.

## Flutter Mobile App

### Technology Stack
- **Framework**: Flutter 3.0+
- **State Management**: Provider pattern
- **Storage**: SharedPreferences & Flutter Secure Storage
- **Localization**: Full support for English and Sesotho

### Key Features
- PIN-based authentication with biometric support
- Offline-first transaction queue
- Real-time balance display
- Transaction history
- Language switching (English/Sesotho)
- Optimized for low-end devices (1GB RAM)

### Building the Flutter App
The Flutter app is designed to run on mobile devices. See `flutter_app/SETUP_GUIDE.md` for detailed instructions.

**Quick Start:**
1. Install Flutter 3.0+ on your local machine
2. Clone this repository
3. Run `cd flutter_app && flutter pub get`
4. Configure API URL in `lib/config/api_config.dart`:
   - Set `isDevelopment = false` for production (Replit backend)
   - Set `isDevelopment = true` for local development
5. Connect an Android device or emulator
6. Run `flutter run`

**API Configuration:** The app automatically detects Android vs iOS and uses the correct development URL. For production, it uses your published Replit URL.

## Architecture

### Backend Architecture
- **RESTful API**: Clean endpoint structure with Express.js
- **IOTA SDK Integration**: Full wallet and transaction capabilities on Shimmer testnet
- **In-Memory Storage**: Transactions stored in memory (for demo purposes)
- **Error Handling**: Comprehensive error management with graceful network failure handling

### Flutter Architecture
- **Service Layer Pattern**: Separation of concerns (auth, transactions, wallet, language)
- **Provider State Management**: Efficient reactive state handling
- **Offline-First Design**: Transactions queue when offline and sync when connected
- **Secure Storage**: Sensitive data protected with Flutter Secure Storage

## Deployment

### Development
The backend API runs automatically via the "Backend API Server" workflow on port 5000.

### Production
- **Deployment Type**: Autoscale (scales based on traffic)
- **Start Command**: `npm start --prefix backend`
- **Environment**: Requires MNEMONIC secret to be set in production environment
- **Port**: 5000, exposed via Replit's proxy

### Important Notes for Production
1. **Wallet Security**: The current setup uses a single wallet mnemonic. In production, implement proper key management.
2. **Database**: Current implementation uses in-memory storage. For production, add a proper database.
3. **Network**: The Shimmer testnet may have connectivity issues. For production, consider mainnet or local node.

## User Preferences
None specified yet.

## Security Considerations

### Current Implementation
- ✅ PIN-based authentication in Flutter app
- ✅ Secure storage for sensitive data
- ✅ Mnemonic stored in .env (git-ignored)
- ✅ No private keys transmitted over network
- ⚠️  Wallet database stored locally (ensure secure backups)

### Production Recommendations
- Use Replit Secrets for MNEMONIC in production
- Implement rate limiting on API endpoints
- Add API authentication/authorization
- Use HTTPS for all communications
- Implement proper database with backups
- Add monitoring and logging

## Testing

### Backend API Testing
Test the API endpoints using curl:
```bash
curl http://localhost:5000/health
curl http://localhost:5000/wallet-info
```

### Flutter App Testing
The Flutter app requires a mobile device or emulator. Follow the Flutter setup instructions in the README.md.

## Troubleshooting

### Common Issues

1. **Backend won't start**
   - Check that the workflow "Backend API Server" is running
   - Verify .env file exists in backend/ directory
   - Check logs for wallet initialization errors

2. **Wallet sync fails**
   - This is expected in restricted network environments
   - The wallet still functions for address generation
   - Network operations may time out gracefully

3. **IOTA SDK errors**
   - Ensure systemd package is installed (provides libudev)
   - Verify @iota/sdk version 1.1.5 is installed
   - Check that wallet-db directory is writable

## Network Configuration

### IOTA Shimmer Testnet
- **Network**: Shimmer Testnet
- **Node URL**: https://api.testnet.shimmer.network
- **Address Format**: Bech32 with 'smr' prefix (e.g., smr1qz7huqv9s9r83...)
- **Transaction Fees**: Zero (feeless)

### Faucet
To get testnet tokens for testing:
1. Get your wallet address from `GET /wallet-info`
2. Visit: https://faucet.testnet.shimmer.network/
3. Request testnet tokens to your address

## Future Enhancements
- [ ] Persistent database for transactions
- [ ] User authentication system
- [ ] Multi-wallet support
- [ ] Web dashboard for transaction monitoring
- [ ] Integration with local payment systems
- [ ] KYC/AML compliance features
- [ ] Analytics and reporting

## Resources
- [IOTA Documentation](https://docs.iota.org/)
- [Shimmer Network](https://shimmer.network/)
- [Flutter Documentation](https://flutter.dev/)
- [Project README](README.md)
- [Project Summary](PROJECT_SUMMARY.md)
