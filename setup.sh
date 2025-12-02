#!/bin/bash

echo "🚀 IOTA Remittance MVP Setup Script"
echo "====================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_status "Node.js found: $NODE_VERSION"
else
    print_error "Node.js not found. Please install Node.js 16+"
    exit 1
fi

# Check Flutter
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -1)
    print_status "Flutter found: $FLUTTER_VERSION"
else
    print_error "Flutter not found. Please install Flutter 3.0+"
    exit 1
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_status "npm found: $NPM_VERSION"
else
    print_error "npm not found. Please install npm"
    exit 1
fi

echo ""
echo "📦 Setting up Backend..."
echo "======================="

# Setup backend
cd backend || exit 1

echo "Installing backend dependencies..."
npm install

if [ $? -eq 0 ]; then
    print_status "Backend dependencies installed successfully"
else
    print_error "Failed to install backend dependencies"
    exit 1
fi

echo "Generating wallet..."
npm run generate-wallet

if [ $? -eq 0 ]; then
    print_status "Wallet generated successfully"
    print_warning "Please copy the mnemonic to your .env file before starting the server"
else
    print_error "Failed to generate wallet"
    exit 1
fi

cd ..

echo ""
echo "📱 Setting up Flutter App..."
echo "============================"

# Setup Flutter app
cd flutter_app || exit 1

echo "Installing Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    print_status "Flutter dependencies installed successfully"
else
    print_error "Failed to install Flutter dependencies"
    exit 1
fi

echo "Generating localization files..."
flutter pub run intl_utils:generate

if [ $? -eq 0 ]; then
    print_status "Localization files generated successfully"
else
    print_warning "Localization generation may have issues. You can run 'flutter pub run intl_utils:generate' manually"
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Backend:"
echo "   cd backend"
echo "   cp .env.example .env"
echo "   # Edit .env with your mnemonic from wallet-info.json"
echo "   npm start"
echo ""
echo "2. Flutter App:"
echo "   cd flutter_app"
echo "   flutter run"
echo ""
echo "3. Build Release APK:"
echo "   cd flutter_app"
echo "   ./build.sh"
echo ""
print_status "IOTA Remittance MVP is ready to use!"
print_warning "Remember to secure your mnemonic - it's the key to your wallet!"