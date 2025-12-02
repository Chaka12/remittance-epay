const { Wallet, CoinType, initLogger, Utils } = require('@iota/sdk');
const fs = require('fs');
const path = require('path');

// Initialize logger
initLogger();

// Configuration
const SHIMMER_TESTNET_BECH32_HRP = 'rms';

async function generateWallet() {
    console.log('🚀 Generating new IOTA Shimmer wallet...\n');
    
    let wallet;
    try {
        // Generate mnemonic first
        console.log('📋 Generating mnemonic...');
        const mnemonic = Utils.generateMnemonic();
        
        // Create wallet instance with mnemonic
        wallet = new Wallet({
            storagePath: './temp-wallet-db',
            coinType: CoinType.Shimmer,
            clientOptions: {
                nodes: ['https://api.testnet.shimmer.network'],
                localPow: true,
            },
            secretManager: {
                mnemonic: mnemonic,
            },
        });
        
        // Create a new account
        console.log('💳 Creating account...');
        const account = await wallet.createAccount({
            alias: 'remittance-wallet',
        });

        // Get the first address
        const addresses = await account.addresses();
        const address = addresses[0];
        
        let balance = { baseCoin: { total: '0' } };
        
        // Try to sync account to get initial balance
        try {
            console.log('🔄 Syncing account...');
            await account.sync();
            balance = await account.getBalance();
        } catch (syncError) {
            console.log('⚠️  Network sync skipped (this is normal in restricted environments)');
        }

        // Display wallet information
        console.log('\n✅ Wallet generated successfully!\n');
        console.log('🔐 Mnemonic (SAVE THIS SECURELY!):');
        console.log(`   ${mnemonic}\n`);
        console.log('📍 Address:', address.address);
        console.log('💰 Balance:', balance.baseCoin.total, 'tokens');
        console.log('🌐 Network: Shimmer Testnet');
        console.log('⚠️  This is a TESTNET wallet - use only for testing!\n');

        // Save wallet details to file
        const walletInfo = {
            mnemonic: mnemonic,
            address: address.address,
            network: 'shimmer-testnet',
            generatedAt: new Date().toISOString(),
            warning: 'This is a testnet wallet. Keep the mnemonic secure and never share it!'
        };

        const walletFile = path.join(__dirname, 'wallet-info.json');
        fs.writeFileSync(walletFile, JSON.stringify(walletInfo, null, 2));
        console.log(`💾 Wallet info saved to: ${walletFile}`);

        // Create .env file
        const envTemplate = `# IOTA Remittance Backend Configuration
# Generated on: ${new Date().toISOString()}

# Your wallet mnemonic - KEEP THIS SECURE!
MNEMONIC="${mnemonic}"

# Server configuration
PORT=3000

# IOTA Network (testnet)
IOTA_NETWORK=testnet
NODE_URL=https://api.testnet.shimmer.network
`;

        const envFile = path.join(__dirname, '.env');
        fs.writeFileSync(envFile, envTemplate);
        console.log(`📝 Environment file saved to: ${envFile}`);
        console.log('\n🎉 Setup complete! The .env file has been created and the server is ready to start.');

        // Clean up temporary wallet database
        if (fs.existsSync('./temp-wallet-db')) {
            fs.rmSync('./temp-wallet-db', { recursive: true, force: true });
            console.log('🧹 Temporary wallet database cleaned up.');
        }

    } catch (error) {
        console.error('❌ Error generating wallet:', error);
        
        // Clean up temporary wallet database on error too
        if (fs.existsSync('./temp-wallet-db')) {
            fs.rmSync('./temp-wallet-db', { recursive: true, force: true });
        }
        
        process.exit(1);
    }
}

// Check if this is being run directly
if (require.main === module) {
    generateWallet().catch((error) => {
        console.error('❌ Fatal error:', error);
        process.exit(1);
    });
}

module.exports = { generateWallet };
