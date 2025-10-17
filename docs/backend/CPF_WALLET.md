# 🔐 Associação CPF ↔ Wallet (100% Off-Chain)

## 📋 Visão Geral

**A associação CPF ↔ endereço Ethereum acontece APENAS no backend (banco de dados off-chain).**

Nada de CPF vai para a blockchain. A blockchain só sabe que o endereço `0xABC...` tem uma identidade verificada (OnchainID), mas **não sabe qual CPF** está associado a ele.

---

## 🏗️ Arquitetura Off-Chain + On-Chain

```
┌─────────────────────────────────────────────────────────────────┐
│                        BACKEND (Off-Chain)                      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Base de Dados (PostgreSQL/MongoDB)          │  │
│  │                                                          │  │
│  │  users:                                                  │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │ id  │ cpf         │ wallet_address       │ status │ │  │
│  │  ├─────┼─────────────┼──────────────────────┼────────┤ │  │
│  │  │ 1   │12345678900  │0xABC...              │verified│ │  │
│  │  │ 2   │98765432100  │0xDEF...              │verified│ │  │
│  │  └─────┴─────────────┴──────────────────────┴────────┘ │  │
│  │                                                          │  │
│  │  kyc_documents:                                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │ user_id │ doc_type │ doc_url      │ verified     │ │  │
│  │  ├─────────┼──────────┼──────────────┼──────────────┤ │  │
│  │  │ 1       │ RG       │ ipfs://...   │ true         │ │  │
│  │  │ 1       │ CPF      │ ipfs://...   │ true         │ │  │
│  │  └─────────┴──────────┴──────────────┴──────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Apenas após KYC aprovado
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BLOCKCHAIN (On-Chain)                       │
│                                                                 │
│  IdentityRegistry:                                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ address          │ identity_contract │ verified         │  │
│  ├──────────────────┼───────────────────┼──────────────────┤  │
│  │ 0xABC...         │ 0x123...          │ true             │  │
│  │ 0xDEF...         │ 0x456...          │ true             │  │
│  └──────────────────┴───────────────────┴──────────────────┘  │
│                                                                 │
│  ⚠️  SEM CPF! Apenas "0xABC... está verificado"                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Fluxo Completo (Backend + Blockchain)

### **Fase 1: Registro Inicial (Off-Chain)**

```
┌──────────────┐
│   Usuário    │
└──────┬───────┘
       │
       │ 1. Acessa aplicação web/mobile
       ▼
┌──────────────────────────────────┐
│      Frontend (React/Next.js)    │
│                                  │
│  • Conecta MetaMask              │
│  • Obtém address (0xABC...)      │
│  • Usuário preenche CPF          │
│  • Faz upload de documentos      │
└──────────┬───────────────────────┘
           │
           │ 2. POST /api/kyc/register
           │    { cpf, address, documents }
           ▼
┌─────────────────────────────────────────┐
│       Backend API (Node.js/Python)      │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ 1. Valida CPF (regex, checksum)  │ │
│  │ 2. Verifica duplicação no DB     │ │
│  │ 3. Salva no banco:               │ │
│  │    INSERT INTO users             │ │
│  │    (cpf, wallet_address, status) │ │
│  │    VALUES                        │ │
│  │    ('12345678900',               │ │
│  │     '0xABC...',                  │ │
│  │     'pending')                   │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### **Fase 2: Validação KYC (Off-Chain)**

```
┌─────────────────────────────────────────┐
│    Operador/Cartório (Painel Admin)     │
│                                         │
│  1. Acessa painel de KYC pendentes      │
│  2. Visualiza documentos do usuário     │
│  3. Valida:                             │
│     • CPF na Receita Federal (API)      │
│     • Documentos (RG, comprovante)      │
│     • Biometria (opcional)              │
│                                         │
│  4. Aprovar ou Rejeitar                 │
└──────────────┬──────────────────────────┘
               │
               │ POST /api/kyc/approve
               │ { user_id, approved: true }
               ▼
┌─────────────────────────────────────────┐
│       Backend API                       │
│                                         │
│  UPDATE users                           │
│  SET status = 'approved'                │
│  WHERE id = user_id                     │
└─────────────────────────────────────────┘
```

### **Fase 3: Registro On-Chain (Blockchain)**

```
┌─────────────────────────────────────────┐
│       Backend Worker/Cron Job           │
│                                         │
│  A cada minuto/hora:                    │
│  1. SELECT * FROM users                 │
│     WHERE status='approved'             │
│     AND onchain_registered=false        │
│                                         │
│  2. Para cada usuário:                  │
└──────────┬──────────────────────────────┘
           │
           │ 3. Executa transações on-chain
           ▼
┌─────────────────────────────────────────┐
│        ethers.js / web3.py              │
│                                         │
│  const user = getUser(user_id);         │
│  const wallet = getAdminWallet();       │
│                                         │
│  // Deploy Identity                     │
│  const identity = await                 │
│    identityFactory.deploy(              │
│      user.wallet_address,               │
│      false                              │
│    );                                   │
│                                         │
│  // Registrar no IdentityRegistry       │
│  await identityRegistry.registerIdentity│
│    (user.wallet_address,                │
│     identity.address,                   │
│     76); // Brasil                      │
│                                         │
│  // Atualizar banco                     │
│  UPDATE users                           │
│  SET onchain_registered=true,           │
│      identity_contract=identity.address │
│  WHERE id=user_id                       │
└─────────────────────────────────────────┘
```

---

## 💻 Implementação Backend

### **1. Schema do Banco de Dados**

```sql
-- PostgreSQL
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    -- pending, approved, rejected, blocked
    
    -- On-chain data
    onchain_registered BOOLEAN DEFAULT FALSE,
    identity_contract VARCHAR(42),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_cpf ON users(cpf);
CREATE INDEX idx_wallet ON users(wallet_address);
CREATE INDEX idx_status ON users(status);

-- Documentos KYC
CREATE TABLE kyc_documents (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    doc_type VARCHAR(50), -- 'rg', 'cpf', 'comprovante', 'selfie'
    doc_url TEXT, -- IPFS ou S3
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Histórico de auditoria
CREATE TABLE kyc_audit (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(50), -- 'created', 'approved', 'rejected', 'onchain_registered'
    operator_id INTEGER, -- quem aprovou
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### **2. API Endpoints (Node.js + Express)**

```javascript
// server.js
const express = require('express');
const { ethers } = require('ethers');
const db = require('./db'); // PostgreSQL client

const app = express();
app.use(express.json());

// ==================== REGISTRO ====================
app.post('/api/kyc/register', async (req, res) => {
    const { cpf, walletAddress, documents } = req.body;
    
    try {
        // 1. Validar CPF
        if (!isValidCPF(cpf)) {
            return res.status(400).json({ error: 'CPF inválido' });
        }
        
        // 2. Verificar se CPF já existe
        const existing = await db.query(
            'SELECT * FROM users WHERE cpf = $1 OR wallet_address = $2',
            [cpf, walletAddress]
        );
        
        if (existing.rows.length > 0) {
            return res.status(409).json({ error: 'CPF ou endereço já registrado' });
        }
        
        // 3. Salvar usuário
        const result = await db.query(
            'INSERT INTO users (cpf, wallet_address, status) VALUES ($1, $2, $3) RETURNING id',
            [cpf, walletAddress, 'pending']
        );
        
        const userId = result.rows[0].id;
        
        // 4. Salvar documentos
        for (const doc of documents) {
            await db.query(
                'INSERT INTO kyc_documents (user_id, doc_type, doc_url) VALUES ($1, $2, $3)',
                [userId, doc.type, doc.url]
            );
        }
        
        // 5. Auditoria
        await db.query(
            'INSERT INTO kyc_audit (user_id, action, notes) VALUES ($1, $2, $3)',
            [userId, 'created', `Registro iniciado para ${walletAddress}`]
        );
        
        res.json({ 
            success: true, 
            userId,
            message: 'KYC iniciado. Aguarde aprovação.' 
        });
        
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Erro ao registrar' });
    }
});

// ==================== CONSULTA ====================
app.get('/api/kyc/status/:walletAddress', async (req, res) => {
    const { walletAddress } = req.params;
    
    try {
        const result = await db.query(
            'SELECT id, status, onchain_registered, identity_contract FROM users WHERE wallet_address = $1',
            [walletAddress]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Usuário não encontrado' });
        }
        
        res.json(result.rows[0]);
        
    } catch (error) {
        res.status(500).json({ error: 'Erro ao consultar' });
    }
});

// ==================== APROVAÇÃO (Admin) ====================
app.post('/api/kyc/approve', async (req, res) => {
    const { userId, approved, operatorId, notes } = req.body;
    
    // TODO: Verificar auth do operador
    
    try {
        const status = approved ? 'approved' : 'rejected';
        
        await db.query(
            'UPDATE users SET status = $1, updated_at = NOW() WHERE id = $2',
            [status, userId]
        );
        
        await db.query(
            'INSERT INTO kyc_audit (user_id, action, operator_id, notes) VALUES ($1, $2, $3, $4)',
            [userId, status, operatorId, notes]
        );
        
        res.json({ success: true, message: `KYC ${status}` });
        
    } catch (error) {
        res.status(500).json({ error: 'Erro ao aprovar' });
    }
});

// ==================== OBTER CPF (Admin/Auditoria) ====================
app.get('/api/admin/user/:walletAddress/cpf', async (req, res) => {
    const { walletAddress } = req.params;
    
    // TODO: Verificar auth do admin + LGPD compliance
    
    try {
        const result = await db.query(
            'SELECT cpf FROM users WHERE wallet_address = $1',
            [walletAddress]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Usuário não encontrado' });
        }
        
        // Log de acesso LGPD
        await db.query(
            'INSERT INTO kyc_audit (user_id, action, operator_id, notes) VALUES ((SELECT id FROM users WHERE wallet_address = $1), $2, $3, $4)',
            [walletAddress, 'cpf_accessed', req.user.id, 'Acesso ao CPF via API']
        );
        
        res.json({ cpf: result.rows[0].cpf });
        
    } catch (error) {
        res.status(500).json({ error: 'Erro ao consultar' });
    }
});

app.listen(3000, () => console.log('API running on port 3000'));
```

### **3. Worker de Registro On-Chain (Cron Job)**

```javascript
// worker.js
const { ethers } = require('ethers');
const db = require('./db');

// Configuração
const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545');
const adminWallet = new ethers.Wallet('0xPRIVATE_KEY', provider);

const IDENTITY_REGISTRY_ADDRESS = '0x...';
const identityRegistry = new ethers.Contract(
    IDENTITY_REGISTRY_ADDRESS,
    ['function registerIdentity(address,address,uint16) external'],
    adminWallet
);

async function processApprovedUsers() {
    console.log('🔄 Processando usuários aprovados...');
    
    try {
        // 1. Buscar usuários aprovados ainda não registrados on-chain
        const result = await db.query(`
            SELECT id, wallet_address 
            FROM users 
            WHERE status = 'approved' 
            AND onchain_registered = FALSE
            LIMIT 10
        `);
        
        for (const user of result.rows) {
            console.log(`📝 Registrando ${user.wallet_address} on-chain...`);
            
            try {
                // 2. Deploy Identity contract
                const identityFactory = new ethers.ContractFactory(
                    IDENTITY_ABI,
                    IDENTITY_BYTECODE,
                    adminWallet
                );
                
                const identity = await identityFactory.deploy(
                    user.wallet_address,
                    false
                );
                await identity.waitForDeployment();
                const identityAddress = await identity.getAddress();
                
                console.log(`  ✓ Identity deployed: ${identityAddress}`);
                
                // 3. Registrar no IdentityRegistry
                const tx = await identityRegistry.registerIdentity(
                    user.wallet_address,
                    identityAddress,
                    76 // Brasil
                );
                await tx.wait();
                
                console.log(`  ✓ Registered in IdentityRegistry`);
                
                // 4. Atualizar banco de dados
                await db.query(
                    `UPDATE users 
                     SET onchain_registered = TRUE, 
                         identity_contract = $1,
                         updated_at = NOW()
                     WHERE id = $2`,
                    [identityAddress, user.id]
                );
                
                // 5. Auditoria
                await db.query(
                    `INSERT INTO kyc_audit (user_id, action, notes) 
                     VALUES ($1, $2, $3)`,
                    [user.id, 'onchain_registered', `Identity: ${identityAddress}`]
                );
                
                console.log(`  ✅ ${user.wallet_address} registrado com sucesso!\n`);
                
            } catch (error) {
                console.error(`  ❌ Erro ao registrar ${user.wallet_address}:`, error.message);
                
                // Log do erro
                await db.query(
                    `INSERT INTO kyc_audit (user_id, action, notes) 
                     VALUES ($1, $2, $3)`,
                    [user.id, 'onchain_error', error.message]
                );
            }
        }
        
    } catch (error) {
        console.error('❌ Erro geral:', error);
    }
}

// Executar a cada 5 minutos
setInterval(processApprovedUsers, 5 * 60 * 1000);
processApprovedUsers(); // executa imediatamente
```

---

## 🔍 Consultas Backend

### **Obter endereço a partir de CPF (interno/admin)**

```javascript
// Apenas para admin/auditoria
app.get('/api/admin/lookup/cpf/:cpf', async (req, res) => {
    // Verificar auth + LGPD
    const result = await db.query(
        'SELECT wallet_address, status FROM users WHERE cpf = $1',
        [req.params.cpf]
    );
    res.json(result.rows[0]);
});
```

### **Obter CPF a partir de endereço (interno/admin)**

```javascript
app.get('/api/admin/lookup/wallet/:address', async (req, res) => {
    // Verificar auth + LGPD
    const result = await db.query(
        'SELECT cpf, status FROM users WHERE wallet_address = $1',
        [req.params.address]
    );
    res.json(result.rows[0]);
});
```

---

## 🔒 Segurança e LGPD

### **Boas Práticas**

1. **Encriptação de CPF no banco**
```javascript
const crypto = require('crypto');

function encrypt(text) {
    const cipher = crypto.createCipheriv('aes-256-gcm', SECRET_KEY, IV);
    return cipher.update(text, 'utf8', 'hex') + cipher.final('hex');
}

function decrypt(encrypted) {
    const decipher = crypto.createDecipheriv('aes-256-gcm', SECRET_KEY, IV);
    return decipher.update(encrypted, 'hex', 'utf8') + decipher.final('utf8');
}

// No registro:
const cpfEncrypted = encrypt(cpf);
await db.query('INSERT INTO users (cpf, ...) VALUES ($1, ...)', [cpfEncrypted]);
```

2. **Auditoria de acesso (LGPD)**
```javascript
// Toda vez que CPF é acessado:
await db.query(
    'INSERT INTO kyc_audit (user_id, action, operator_id, ip_address) VALUES ($1, $2, $3, $4)',
    [userId, 'cpf_accessed', operatorId, req.ip]
);
```

3. **Rate limiting**
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 min
    max: 100 // limite de requisições
});

app.use('/api/', limiter);
```

---

## 📊 Resumo

| Onde | O quê | Por quê |
|------|-------|---------|
| **Backend DB** | CPF ↔ endereço | Privacidade, LGPD, flexibilidade |
| **Blockchain** | Endereço verificado (sim/não) | Imutabilidade, compliance ERC-3643 |
| **Frontend** | Usuário fornece dados | UX |
| **Worker** | Sincroniza DB → Blockchain | Automação |

**CPF NUNCA vai para blockchain!** Apenas a confirmação de que `0xABC...` foi verificado (KYC aprovado).

---

## 🎯 Vantagens da Abordagem Off-Chain

✅ **Privacidade:** CPF fica no banco de dados privado  
✅ **LGPD:** Possível deletar dados conforme legislação  
✅ **Flexibilidade:** Fácil atualizar/corrigir dados  
✅ **Performance:** Consultas rápidas no DB  
✅ **Custo:** Não paga gas para cada associação  
✅ **Auditoria:** Log completo de acessos  

A blockchain apenas valida que a identidade foi verificada, sem expor dados pessoais! 🔐

