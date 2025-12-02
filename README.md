# IOTA/Shimmer Remittance MVP for Lesotho

A complete zero-cost remittance application built with Flutter and Node.js, leveraging the IOTA Shimmer network for feeless transactions.

## 🌟 Features

- **Zero Transaction Fees**: Powered by IOTA Shimmer network
- **Offline-First**: Transactions queue when offline and sync when connected
- **Dual Language**: English and Sesotho (Lesotho native language)
- **Secure**: PIN-based authentication with biometric support
- **Low-End Optimized**: Designed for 1GB RAM Android devices
- **Complete Localization**: Full app localization with ARB files

## 📁 Project Structure

```
iota-remittance-mvp/
├── flutter_app/                 # Flutter frontend
│   ├── lib/
│   │   ├── screens/            # UI screens
│   │   ├── services/           # Business logic
│   │   ├── models/             # Data models
│   │   ├── widgets/            # Reusable widgets
│   │   ├── utils/              # Utility functions
│   │   └── l10n/               # Localization files
│   │       ├── app_en.arb      # English strings
│   │       └── app_st.arb      # Sesotho strings
│   ├── android/                # Android-specific code
│   └── pubspec.yaml            # Flutter dependencies
├── backend/                     # Node.js backend
│   ├── server.js               # Express server
│   ├── generate-wallet.js      # Wallet generation script
│   ├── package.json            # Node.js dependencies
│   └── .env.example            # Environment template
└── scripts/                     # Utility scripts
```

## 🚀 Quick Start

### Prerequisites

- Node.js 16+ and npm
- Flutter 3.0+
- Android Studio (for Android development)
- Git

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Generate wallet**:
   ```bash
   npm run generate-wallet
   ```

4. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your generated mnemonic
   ```

5. **Start backend server**:
   ```bash
   npm start
   ```

### Flutter App Setup

1. **Navigate to flutter app**:
   ```bash
   cd flutter_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate localization files**:
   ```bash
   flutter pub run intl_utils:generate
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## 🛠️ Development

### Backend API Endpoints

- `GET /health` - Health check
- `GET /wallet-info` - Get wallet information
- `POST /send` - Send transaction
- `GET /history` - Get transaction history
- `GET /network-info` - Get network information

### Transaction Flow

1. User enters recipient address and amount
2. App validates inputs and checks balance
3. Transaction is queued if offline, sent immediately if online
4. Failed transactions retry automatically (max 3 attempts)
5. All transactions stored locally with sync capability

### Security Features

- PIN-based authentication
- Secure storage for sensitive data
- Biometric authentication support
- Local wallet generation
- No server-side storage of private keys

## 🌍 Localization

The app supports two languages:

- **English** (`app_en.arb`)
- **Sesotho** (`app_st.arb`) - Lesotho native language

To add more languages:
1. Create new ARB file in `lib/l10n/`
2. Add language code to `pubspec.yaml`
3. Run `flutter pub run intl_utils:generate`

## 📱 Optimizations for Low-End Devices

- **Memory Efficient**: Minimal memory footprint
- **Offline-First**: Works without internet connection
- **Lightweight UI**: Simple, clean interface
- **Background Sync**: Efficient data synchronization
- **Compressed Assets**: Optimized images and fonts

## 🔧 Configuration

### Backend Configuration

Edit `.env` file:
```env
MNEMONIC=your_wallet_mnemonic_here
PORT=3000
IOTA_NETWORK=testnet
NODE_URL=https://api.testnet.shimmer.network
```

### Flutter Configuration

Edit `pubspec.yaml` for:
- App name and version
- Dependencies
- Fonts and assets
- Localization settings

## 🧪 Testing

### Backend Testing
```bash
cd backend
npm test
```

### Flutter Testing
```bash
cd flutter_app
flutter test
```

## 🚀 Deployment

### Backend Deployment
1. Set up production environment variables
2. Use process manager (PM2) for Node.js
3. Configure reverse proxy (Nginx)
4. Set up SSL certificate

### Flutter Deployment
1. Build release APK:
   ```bash
   flutter build apk --release
   ```
2. Sign the APK for Play Store
3. Upload to Google Play Console

## 📚 IOTA Integration

### Wallet Generation
The app uses IOTA SDK for:
- Wallet creation from mnemonic
- Address generation
- Transaction signing and sending
- Network synchronization

### Transaction Features
- Feeless transfers on Shimmer network
- Tag and metadata support
- Transaction confirmation tracking
- Balance synchronization

## 🆘 Troubleshooting

### Common Issues

1. **Wallet Generation Fails**:
   - Check Node.js version (16+)
   - Verify network connectivity
   - Check mnemonic format

2. **Flutter Build Fails**:
   - Run `flutter clean`
   - Update dependencies: `flutter pub upgrade`
   - Check Flutter doctor: `flutter doctor`

3. **Transaction Failures**:
   - Verify backend is running
   - Check network connectivity
   - Validate addresses (81 characters)

### Debug Mode

Enable debug logging:
```bash
# Backend
DEBUG=true npm start

# Flutter
flutter run --debug
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- IOTA Foundation for the SDK
- Lesotho community for language support
- Open source contributors

## 📞 Support

For issues and questions:
- Create GitHub issue
- Check FAQ in app settings
- Review troubleshooting section

---

**Built with ❤️ for Lesotho**