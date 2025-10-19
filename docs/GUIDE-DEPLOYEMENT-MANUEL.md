# 🚀 Guide de Déploiement Manuel - Fabric 3.1.1

Guide complet pour déployer le réseau blockchain foncier de Côte d'Ivoire **étape par étape**.

## ✅ Prérequis

Avant de commencer, vérifiez que vous avez :

```bash
# 1. Docker et Docker Compose
docker --version
docker-compose --version

# 2. Binaires Fabric 3.1.1 dans le PATH
peer version
orderer version
configtxgen --version

# 3. fabric-ca-client
fabric-ca-client version
```

Si les binaires ne sont pas dans le PATH :
```bash
export PATH=$PATH:/home/absolue/fabric-samples/bin
export FABRIC_CFG_PATH=/home/absolue/my-blockchain/network
```

---

## 🧹 ÉTAPE 1 : Nettoyage Complet

Commencez toujours par un environnement propre :

```bash
cd /home/absolue/my-blockchain

# Arrêter tous les conteneurs
cd deploy
docker-compose -f docker-compose.yaml down -v
docker-compose -f docker-compose-ca.yaml down -v

# Supprimer les conteneurs orphelins
docker rm -f $(docker ps -aq --filter "label=service=hyperledger-fabric") 2>/dev/null || true

# Nettoyer les volumes
docker volume prune -f

# Supprimer les certificats et artefacts existants
cd ../network
sudo rm -rf organizations/ordererOrganizations organizations/peerOrganizations
sudo rm -rf channel-artifacts/*
sudo rm -rf fabric-ca-server-home
```

✅ **Vérification** : `ls network/organizations/` doit être vide

---

## 🏢 ÉTAPE 2 : Démarrage des Certificate Authorities

Les CAs sont nécessaires pour générer tous les certificats du réseau.

```bash
cd /home/absolue/my-blockchain/deploy

# Démarrer les 4 CAs
docker-compose -f docker-compose-ca.yaml up -d

# Attendre 30 secondes que les CAs soient prêtes
sleep 30

# Vérifier que les 4 CAs sont actives
docker ps --filter "name=ca-"
```

✅ **Vérification** : Vous devez voir 4 conteneurs :
- `ca-afor`
- `ca-cvgfr`
- `ca-prefet`
- `ca-orderer`

---

## 🔐 ÉTAPE 3 : Enrollment des Identités

Utilisez fabric-ca-client pour enroller toutes les identités.

```bash
cd /home/absolue/my-blockchain

# Rendre le script exécutable
chmod +x scripts/setup-ca.sh

# Lancer l'enrollment (les CAs doivent déjà tourner)
./scripts/setup-ca.sh enroll
```

Ce script va :
1. Enroller l'admin de chaque organisation
2. Enroller les peers
3. Enroller l'orderer
4. Générer les certificats TLS
5. Créer les fichiers `config.yaml` avec NodeOUs

✅ **Vérification** :
```bash
# Vérifier que les certificats existent
ls network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/signcerts/
ls network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/msp/signcerts/
```

Vous devez voir des fichiers `cert.pem`

---

## 📜 ÉTAPE 4 : Génération des Artefacts du Channel

Générez le genesis block pour le channel.

```bash
cd /home/absolue/my-blockchain/network

# Définir le chemin de config
export FABRIC_CFG_PATH=$(pwd)

# Créer le dossier si nécessaire
mkdir -p channel-artifacts

# Générer le genesis block
configtxgen -profile ThreeOrgsApplicationGenesis \
    -outputBlock ./channel-artifacts/contrats-fonciers.block \
    -channelID contrats-fonciers
```

✅ **Vérification** :
```bash
ls -lh channel-artifacts/contrats-fonciers.block
```

Le fichier doit exister et faire environ 10-20 KB.

---

## 🚀 ÉTAPE 5 : Démarrage du Réseau

Démarrez l'orderer, les peers et les bases CouchDB.

```bash
cd /home/absolue/my-blockchain/deploy

# Démarrer tous les services
docker-compose -f docker-compose.yaml up -d

# Attendre que tout démarre (30 secondes)
sleep 30

# Vérifier que tout tourne
docker ps --filter "label=service=hyperledger-fabric"
```

✅ **Vérification** : Vous devez voir **8 conteneurs** actifs :
- `orderer.foncier.ci`
- `peer0.afor.foncier.ci`
- `peer0.cvgfr.foncier.ci`
- `peer0.prefet.foncier.ci`
- `couchdb-afor`
- `couchdb-cvgfr`
- `couchdb-prefet`
- `cli`

**Vérifier les logs de l'orderer** :
```bash
docker logs orderer.foncier.ci 2>&1 | grep "Beginning to serve"
```

Vous devez voir : `Beginning to serve requests`

---

## 📡 ÉTAPE 6 : Création du Channel

Utilisez la **Channel Participation API** (moderne Fabric 3.x).

```bash
cd /home/absolue/my-blockchain

# Définir les variables pour osnadmin
export ORDERER_CA="network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem"
export ORDERER_ADMIN_TLS_SIGN_CERT="network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.crt"
export ORDERER_ADMIN_TLS_PRIVATE_KEY="network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.key"

# Joindre l'orderer au channel
osnadmin channel join \
    --channelID contrats-fonciers \
    --config-block network/channel-artifacts/contrats-fonciers.block \
    -o localhost:7053 \
    --ca-file "$ORDERER_CA" \
    --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" \
    --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
```

✅ **Vérification** :
```bash
# Lister les channels de l'orderer
osnadmin channel list \
    -o localhost:7053 \
    --ca-file "$ORDERER_CA" \
    --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" \
    --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
```

Vous devez voir `contrats-fonciers` dans la liste.

---

## 🔗 ÉTAPE 7 : Jonction des Peers au Channel

Chaque peer doit rejoindre le channel.

```bash
cd /home/absolue/my-blockchain

export FABRIC_CFG_PATH=$(pwd)/network
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA="network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem"

# ===== PEER0.AFOR =====
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_TLS_ROOTCERT_FILE="network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp"
export CORE_PEER_ADDRESS=localhost:7051

peer channel join -b network/channel-artifacts/contrats-fonciers.block

# ===== PEER0.CVGFR =====
export CORE_PEER_LOCALMSPID="CVGFROrg"
export CORE_PEER_TLS_ROOTCERT_FILE="network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp"
export CORE_PEER_ADDRESS=localhost:8051

peer channel join -b network/channel-artifacts/contrats-fonciers.block

# ===== PEER0.PREFET =====
export CORE_PEER_LOCALMSPID="PREFETOrg"
export CORE_PEER_TLS_ROOTCERT_FILE="network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="network/organizations/peerOrganizations/prefet.foncier.ci/users/Admin@prefet.foncier.ci/msp"
export CORE_PEER_ADDRESS=localhost:9051

peer channel join -b network/channel-artifacts/contrats-fonciers.block
```

✅ **Vérification** :
```bash
# Vérifier pour chaque peer
export CORE_PEER_ADDRESS=localhost:7051
peer channel list

export CORE_PEER_ADDRESS=localhost:8051
peer channel list

export CORE_PEER_ADDRESS=localhost:9051
peer channel list
```

Chaque peer doit lister `contrats-fonciers`.

---

## 📦 ÉTAPE 8 : Déploiement du Chaincode Java

### 8.1 Compilation du Chaincode

```bash
cd /home/absolue/my-blockchain/chaincode-java

# Build avec Gradle
./gradlew clean build

# Vérifier que le JAR a été créé
ls -lh build/libs/
```

### 8.2 Package du Chaincode

```bash
cd /home/absolue/my-blockchain

export FABRIC_CFG_PATH=$(pwd)/network

# Packager le chaincode
peer lifecycle chaincode package contrats-fonciers.tar.gz \
    --path chaincode-java \
    --lang java \
    --label contrats-fonciers_1.0
```

### 8.3 Installation sur les Peers

```bash
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA="network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem"

# ===== INSTALLER SUR PEER0.AFOR =====
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_TLS_ROOTCERT_FILE="network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp"
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode install contrats-fonciers.tar.gz

# ===== INSTALLER SUR PEER0.CVGFR =====
export CORE_PEER_LOCALMSPID="CVGFROrg"
export CORE_PEER_TLS_ROOTCERT_FILE="network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp"
export CORE_PEER_ADDRESS=localhost:8051

peer lifecycle chaincode install contrats-fonciers.tar.gz

# ===== INSTALLER SUR PEER0.PREFET =====
export CORE_PEER_LOCALMSPID="PREFETOrg"
export CORE_PEER_TLS_ROOTCERT_FILE="network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="network/organizations/peerOrganizations/prefet.foncier.ci/users/Admin@prefet.foncier.ci/msp"
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode install contrats-fonciers.tar.gz
```

✅ **Vérification** :
```bash
# Récupérer le Package ID
peer lifecycle chaincode queryinstalled
```

Notez le `Package ID` (ex: `contrats-fonciers_1.0:abc123...`)

---

## 🎯 ÉTAPE 9 : Approbation et Commit

### 9.1 Approuver pour chaque organisation

```bash
# Remplacer CC_PACKAGE_ID par votre Package ID réel
export CC_PACKAGE_ID="contrats-fonciers_1.0:YOUR_PACKAGE_ID_HERE"

# ===== APPROUVER POUR AFOR =====
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_MSPCONFIGPATH="network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt"
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --channelID contrats-fonciers \
    --name contrats-fonciers \
    --version 1.0 \
    --package-id $CC_PACKAGE_ID \
    --sequence 1 \
    --tls \
    --cafile "$ORDERER_CA"

# ===== APPROUVER POUR CVGFR =====
export CORE_PEER_LOCALMSPID="CVGFROrg"
export CORE_PEER_MSPCONFIGPATH="network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt"
export CORE_PEER_ADDRESS=localhost:8051

peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --channelID contrats-fonciers \
    --name contrats-fonciers \
    --version 1.0 \
    --package-id $CC_PACKAGE_ID \
    --sequence 1 \
    --tls \
    --cafile "$ORDERER_CA"

# ===== APPROUVER POUR PREFET =====
export CORE_PEER_LOCALMSPID="PREFETOrg"
export CORE_PEER_MSPCONFIGPATH="network/organizations/peerOrganizations/prefet.foncier.ci/users/Admin@prefet.foncier.ci/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/ca.crt"
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --channelID contrats-fonciers \
    --name contrats-fonciers \
    --version 1.0 \
    --package-id $CC_PACKAGE_ID \
    --sequence 1 \
    --tls \
    --cafile "$ORDERER_CA"
```

### 9.2 Vérifier la préparation

```bash
peer lifecycle chaincode checkcommitreadiness \
    --channelID contrats-fonciers \
    --name contrats-fonciers \
    --version 1.0 \
    --sequence 1 \
    --tls \
    --cafile "$ORDERER_CA" \
    --output json
```

Vous devez voir `"Approved": true` pour les 3 organisations.

### 9.3 Commit du Chaincode

```bash
peer lifecycle chaincode commit \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --channelID contrats-fonciers \
    --name contrats-fonciers \
    --version 1.0 \
    --sequence 1 \
    --tls \
    --cafile "$ORDERER_CA" \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/ca.crt
```

✅ **Vérification** :
```bash
peer lifecycle chaincode querycommitted \
    --channelID contrats-fonciers \
    --name contrats-fonciers \
    --cafile "$ORDERER_CA"
```

---

## 🧪 ÉTAPE 10 : Test du Chaincode

### 10.1 Invoquer une transaction

```bash
# Créer un contrat foncier
peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --tls \
    --cafile "$ORDERER_CA" \
    -C contrats-fonciers \
    -n contrats-fonciers \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt \
    -c '{"function":"createContrat","Args":["CONTRAT001","123 hectares","Abidjan","Kouassi Yao","2024-01-15","AFOR"]}'
```

### 10.2 Query une transaction

```bash
peer chaincode query \
    -C contrats-fonciers \
    -n contrats-fonciers \
    -c '{"function":"readContrat","Args":["CONTRAT001"]}'
```

---

## 🎉 Félicitations !

Votre réseau Hyperledger Fabric 3.1.1 est maintenant **complètement opérationnel** avec :

✅ 1 Orderer
✅ 3 Peers (AFOR, CVGFR, PREFET)
✅ 3 CouchDB
✅ Channel créé et peers joints
✅ Chaincode Java déployé et fonctionnel

---

## 📚 Commandes Utiles

### Voir les logs
```bash
docker logs orderer.foncier.ci
docker logs peer0.afor.foncier.ci
docker logs peer0.cvgfr.foncier.ci
```

### Redémarrer un service
```bash
docker restart orderer.foncier.ci
```

### Entrer dans le CLI
```bash
docker exec -it cli bash
```

### Arrêter le réseau
```bash
cd deploy
docker-compose down
```

### Tout nettoyer
```bash
docker-compose down -v
sudo rm -rf ../network/organizations/*
sudo rm -rf ../network/channel-artifacts/*
```
