# Configuration Hyperledger Fabric 3.1.1 - Réseau Foncier Côte d'Ivoire

## ✅ VERSIONS ALIGNÉES

### Binaries locaux
- **peer**: v3.1.1 (Commit: 435a7f1, Go: 1.24.2)
- **orderer**: v3.1.1 (Commit: 435a7f1, Go: 1.24.2)
- **configtxgen**: v3.1.1 (Commit: 435a7f1, Go: 1.24.2)
- **cryptogen**: v3.1.1 (inclus dans les binaries)

### Images Docker
- **hyperledger/fabric-orderer:3.1.1** ✅
- **hyperledger/fabric-peer:3.1.1** ✅
- **hyperledger/fabric-tools:2.5** (latest disponible - pas de 3.x sur Docker Hub)
- **hyperledger/fabric-ca:1.5** ✅
- **couchdb:3.3.2** ✅

## 🏗️ ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────┐
│                  RÉSEAU FABRIC 3.1.1                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Orderer: orderer.foncier.ci (port 7050)                   │
│    └─ Mode: Raft Consensus                                  │
│    └─ Channel Participation API activée                     │
│                                                              │
│  Organisations (3):                                          │
│    1. AFOR (Agence Foncière Rurale)                        │
│       └─ peer0.afor.foncier.ci:7051                        │
│       └─ couchdb-afor:5984                                  │
│                                                              │
│    2. CVGFR (Comité Villageois Gestion Foncière)           │
│       └─ peer0.cvgfr.foncier.ci:8051                       │
│       └─ couchdb-cvgfr:6984                                 │
│                                                              │
│    3. PREFET (Préfecture)                                   │
│       └─ peer0.prefet.foncier.ci:9051                      │
│       └─ couchdb-prefet:7984                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 📁 STRUCTURE DU PROJET

```
my-blockchain/
├── api-java/              # API REST Spring Boot
├── chaincode-java/        # Smart contracts Java
├── deploy/                # Fichiers Docker Compose
│   ├── docker-compose.yaml
│   ├── docker-compose-minimal.yaml
│   └── docker-compose-ca.yaml (généré)
├── network/
│   ├── channel-artifacts/ # Blocs genesis et transactions
│   ├── config/            # Configuration supplémentaire
│   ├── organizations/     # PKI (certificates MSP)
│   ├── configtx.yaml      # Configuration des channels
│   └── crypto-config.yaml # Configuration cryptogen
├── scripts/               # Scripts de déploiement
│   ├── network.sh
│   ├── setup-ca.sh
│   └── create-channel.sh
└── docs/                  # Documentation
```

## 🔐 PKI & CERTIFICATS

### Génération avec cryptogen (Fabric 3.1.1)
```bash
cryptogen generate --config=crypto-config.yaml --output=organizations
```

### Structure MSP conforme NodeOUs
```
organizations/
├── ordererOrganizations/
│   └── foncier.ci/
│       ├── ca/
│       ├── msp/
│       │   ├── cacerts/
│       │   ├── tlscacerts/
│       │   └── config.yaml (NodeOUs enabled)
│       ├── orderers/
│       │   └── orderer.foncier.ci/
│       │       ├── msp/
│       │       │   ├── signcerts/
│       │       │   ├── keystore/
│       │       │   ├── cacerts/
│       │       │   ├── tlscacerts/
│       │       │   └── config.yaml
│       │       └── tls/
│       └── tlsca/
└── peerOrganizations/
    ├── afor.foncier.ci/
    ├── cvgfr.foncier.ci/
    └── prefet.foncier.ci/
```

## 🚀 COMMANDES DE DÉPLOIEMENT

### Démarrer le réseau
```bash
cd scripts
./network.sh up
```

### Arrêter le réseau
```bash
cd scripts
./network.sh down
```

### Nettoyer complètement
```bash
cd scripts
./network.sh clean
```

### Démarrer les CAs (optionnel)
```bash
cd scripts
./setup-ca.sh start
```

## 🔧 CONFIGURATION FABRIC 3.1.1

### Changements importants vs 2.x
1. **Plus de consortium** - Utilisation de Channel Participation API
2. **NodeOUs activé par défaut** - Meilleure gestion des rôles
3. **TLS obligatoire** - Sécurité renforcée
4. **Channel Participation API** - Nouvelle méthode de jonction aux channels
5. **Admin endpoint séparé** - Port 7053 pour l'administration

### Variables d'environnement critiques (Orderer)
```yaml
ORDERER_GENERAL_BOOTSTRAPMETHOD: none
ORDERER_CHANNELPARTICIPATION_ENABLED: true
ORDERER_ADMIN_TLS_ENABLED: true
ORDERER_ADMIN_LISTENADDRESS: 0.0.0.0:7053
```

### Variables d'environnement critiques (Peer)
```yaml
CORE_PEER_MSPCONFIGPATH: /etc/hyperledger/fabric/msp
CORE_LEDGER_STATE_STATEDATABASE: CouchDB
CORE_PEER_TLS_ENABLED: true
```

## 📝 TODO

- [ ] Résoudre le problème de démarrage de l'orderer
- [ ] Créer le channel genesis block
- [ ] Joindre les peers au channel avec Channel Participation API
- [ ] Compiler et déployer le chaincode Java
- [ ] Tester les transactions
- [ ] Déployer l'API REST

## 🐛 PROBLÈMES CONNUS

### 1. Orderer ne démarre pas
**Erreur**: `could not load a valid signer certificate from directory /var/hyperledger/orderer/msp/signcerts`
**Status**: EN INVESTIGATION
**Piste**: Les certificats existent mais l'orderer ne les trouve pas

### 2. Images tools 3.1.1 non disponibles
**Solution**: Utiliser fabric-tools:2.5 (compatible) ou binaries locaux

## 📚 RÉFÉRENCES

- [Hyperledger Fabric 3.1 Release Notes](https://github.com/hyperledger/fabric/releases/tag/v3.1.0)
- [Channel Participation API](https://hyperledger-fabric.readthedocs.io/en/release-3.1/whatsnew.html#channel-participation-api)
- [NodeOU Configuration](https://hyperledger-fabric.readthedocs.io/en/release-3.1/msp.html)
