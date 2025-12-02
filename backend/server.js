const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { Wallet, CoinType, initLogger } = require('@iota/sdk');
require('dotenv').config();

// Initialize logger
initLogger();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// In-memory transaction storage for demo purposes
const transactions = [];

// Wallet configuration
const SHIMMER_TESTNET_HRP = 'rms';
const SHIMMER_TESTNET_BECH32_HRP = 'rms';

// Initialize wallet with mnemonic from environment
let wallet;
let account;

async function initializeWallet() {
    try {
        const mnemonic = process.env.MNEMONIC;
        if (!mnemonic) {
            console.error('MNEMONIC not found in environment variables');
            process.exit(1);
        }

        // Create wallet
        wallet = new Wallet({
            storagePath: './wallet-db',
            coinType: CoinType.Shimmer,
            clientOptions: {
                nodes: ['https://api.testnet.shimmer.network'],
                localPow: true,
            },
            secretManager: {
                mnemonic,
            },
        });

        // Get or create account
        const accountName = 'remittance-account';
        try {
            account = await wallet.getAccount(accountName);
        } catch (error) {
            // Account doesn't exist, create it
            account = await wallet.createAccount({
                alias: accountName,
            });
        }

        console.log('Wallet initialized successfully');
        const addresses = await account.addresses();
        console.log('Account address:', addresses[0].address);
        
        // Try to sync account
        try {
            await account.sync();
            console.log('Account synced');
        } catch (syncError) {
            console.log('Account sync skipped (network may be unavailable)');
        }
        
    } catch (error) {
        console.error('Failed to initialize wallet:', error);
        process.exit(1);
    }
}

// API Endpoints

// Root route - API landing page
app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IOTA Remittance API</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
        }
        .container {
            max-width: 600px;
            padding: 40px;
            background: rgba(255,255,255,0.1);
            border-radius: 16px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        h1 { font-size: 2.5rem; margin-bottom: 10px; }
        .subtitle { color: #8892b0; margin-bottom: 30px; }
        .status {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(0,255,0,0.2);
            padding: 8px 16px;
            border-radius: 20px;
            margin-bottom: 30px;
        }
        .status-dot {
            width: 10px;
            height: 10px;
            background: #00ff00;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        h2 { font-size: 1.2rem; margin-bottom: 15px; color: #ccd6f6; }
        .endpoints { list-style: none; }
        .endpoints li {
            padding: 12px;
            margin-bottom: 8px;
            background: rgba(255,255,255,0.05);
            border-radius: 8px;
            display: flex;
            gap: 12px;
        }
        .method {
            background: #64ffda;
            color: #1a1a2e;
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: bold;
            font-size: 0.8rem;
        }
        .method.post { background: #ffa64d; }
        .path { color: #64ffda; }
        .desc { color: #8892b0; margin-left: auto; }
        .footer { margin-top: 30px; color: #8892b0; font-size: 0.9rem; }
        a { color: #64ffda; }
    </style>
</head>
<body>
    <div class="container">
        <h1>IOTA Remittance API</h1>
        <p class="subtitle">Zero-cost remittance for Lesotho on Shimmer Network</p>
        
        <div class="status">
            <div class="status-dot"></div>
            <span>API Running</span>
        </div>
        
        <h2>Available Endpoints</h2>
        <ul class="endpoints">
            <li>
                <span class="method">GET</span>
                <span class="path">/health</span>
                <span class="desc">Health check</span>
            </li>
            <li>
                <span class="method">GET</span>
                <span class="path">/wallet-info</span>
                <span class="desc">Wallet address & balance</span>
            </li>
            <li>
                <span class="method post">POST</span>
                <span class="path">/send</span>
                <span class="desc">Send transaction</span>
            </li>
            <li>
                <span class="method">GET</span>
                <span class="path">/history</span>
                <span class="desc">Transaction history</span>
            </li>
            <li>
                <span class="method">GET</span>
                <span class="path">/network-info</span>
                <span class="desc">Network status</span>
            </li>
        </ul>
        
        <p class="footer">
            Powered by <a href="https://shimmer.network" target="_blank">IOTA Shimmer</a> Testnet
        </p>
    </div>
</body>
</html>
    `);
});

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', message: 'IOTA Remittance API is running' });
});

// Get wallet info
app.get('/wallet-info', async (req, res) => {
    try {
        if (!account) {
            return res.status(500).json({ error: 'Wallet not initialized' });
        }

        const addresses = await account.addresses();
        const address = addresses[0];
        
        let balance = { baseCoin: { total: '0', available: '0' } };
        try {
            balance = await account.getBalance();
        } catch (balanceError) {
            console.log('Could not fetch balance:', balanceError);
        }
        
        res.json({
            address: address.address,
            balance: {
                total: balance.baseCoin.total,
                available: balance.baseCoin.available,
            },
        });
    } catch (error) {
        console.error('Error getting wallet info:', error);
        res.status(500).json({ error: error.message });
    }
});

// Send transaction
app.post('/send', async (req, res) => {
    try {
        const { from, to, amount } = req.body;
        
        if (!from || !to || !amount) {
            return res.status(400).json({ 
                error: 'Missing required fields: from, to, amount' 
            });
        }

        if (!account) {
            return res.status(500).json({ error: 'Wallet not initialized' });
        }

        // Convert amount to SMR (1 SMR = 1,000,000 tokens)
        const amountInTokens = BigInt(Math.floor(amount * 1000000));
        
        console.log(`Sending ${amountInTokens} tokens from ${from} to ${to}`);

        try {
            // Send the transaction
            const response = await account.send(
                amountInTokens,
                to,
                {
                    tag: '0x' + Buffer.from('REMITTANCE').toString('hex'),
                    metadata: '0x' + Buffer.from(JSON.stringify({
                        type: 'remittance',
                        timestamp: new Date().toISOString(),
                        from: from,
                    })).toString('hex'),
                }
            );

            const transactionId = response.transactionId;
            
            // Store transaction
            const transaction = {
                id: Date.now().toString(),
                transactionId: transactionId,
                from: from,
                to: to,
                amount: parseFloat(amount),
                networkFee: 0, // IOTA is feeless
                timestamp: new Date(),
                status: 'completed',
            };
            
            transactions.unshift(transaction);
            
            res.json({
                success: true,
                transactionId: transactionId,
                message: 'Transaction sent successfully',
            });
            
            console.log(`Transaction sent successfully: ${transactionId}`);
        } catch (sendError) {
            console.error('Error sending transaction:', sendError);
            
            // Store failed transaction for retry
            const failedTransaction = {
                id: Date.now().toString(),
                transactionId: null,
                from: from,
                to: to,
                amount: parseFloat(amount),
                networkFee: 0,
                timestamp: new Date(),
                status: 'failed',
                error: sendError.message || JSON.stringify(sendError),
            };
            
            transactions.unshift(failedTransaction);
            
            res.status(500).json({ 
                error: sendError.message || 'Failed to send transaction',
                transactionId: null,
            });
        }
        
    } catch (error) {
        console.error('Error processing transaction:', error);
        res.status(500).json({ 
            error: error.message,
            transactionId: null,
        });
    }
});

// Get transaction history
app.get('/history', (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 50;
        const offset = parseInt(req.query.offset) || 0;
        
        const paginatedTransactions = transactions.slice(offset, offset + limit);
        
        res.json({
            transactions: paginatedTransactions,
            total: transactions.length,
            hasMore: offset + limit < transactions.length,
        });
        
    } catch (error) {
        console.error('Error getting transaction history:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get network info
app.get('/network-info', async (req, res) => {
    try {
        if (!wallet) {
            return res.status(500).json({ error: 'Wallet not initialized' });
        }

        try {
            const client = wallet.getClient();
            const info = await client.getInfo();
            
            res.json({
                network: 'shimmer-testnet',
                nodeUrl: 'https://api.testnet.shimmer.network',
                health: info.nodeInfo.isHealthy,
                latestMilestone: info.nodeInfo.status.latestMilestone.index,
            });
        } catch (networkError) {
            // If network is unavailable, return basic info
            res.json({
                network: 'shimmer-testnet',
                nodeUrl: 'https://api.testnet.shimmer.network',
                health: false,
                error: 'Network unavailable',
            });
        }
        
    } catch (error) {
        console.error('Error getting network info:', error);
        res.status(500).json({ error: error.message });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
    console.log(`IOTA Remittance API running on http://localhost:${PORT}`);
    
    // Initialize wallet
    initializeWallet().then(() => {
        console.log('Server ready to handle requests');
    }).catch((error) => {
        console.error('Failed to start server:', error);
    });
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('Shutting down server...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('Shutting down server...');
    process.exit(0);
});
