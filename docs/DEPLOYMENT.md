# Guide de Déploiement - Système Foncier Côte d'Ivoire

## Architecture Hyperledger Fabric 3.1.1 avec Java

### Vue d'ensemble du Déploiement

Ce guide décrit le déploiement de l'architecture refactorisée avec :
- **Chaincode Java** moderne
- **API REST Spring Boot**
- **3 organisations** avec orderers distribués
- **Canaux spécialisés** (AFOR_CONTRAT_AGRAIRE, AFOR_CERTIFICATE, ADMIN)

## 🎯 Objectifs de l'Architecture

### Organisations et Rôles

| Organisation | Domaine | Responsabilités | Orderer | CouchDB |
|-------------|---------|-----------------|---------|----------|
| **AFOR** | afor.foncier.ci | Gestion principale des contrats | orderer-afor:7050 | couchdb-afor:5984 |
| **CVGFR** | cvgfr.foncier.ci | Validation locale des contrats agraires | orderer-cvgfr:8050 | couchdb-cvgfr:6984 |
| **PREFET** | prefet.foncier.ci | Validation des certificats fonciers | orderer-prefet:9050 | couchdb-prefet:7984 |

### Canaux Spécialisés

1. **AFOR_CONTRAT_AGRAIRE**
   - Participants : AFOR + CVGFR
   - Usage : Contrats agraires entre propriétaires et exploitants
   - Endorsement : Signature des deux organisations requise

2. **AFOR_CERTIFICATE**
   - Participants : AFOR + PREFET
   - Usage : Certificats fonciers officiels
   - Endorsement : Validation AFOR + autorité administrative

3. **ADMIN**
   - Participants : AFOR + CVGFR + PREFET
   - Usage : Administration et supervision technique
   - Endorsement : Consensus majoritaire

## 🛠️ Prérequis Techniques

### Environnement Système

```bash
# Système d'exploitation
Ubuntu 20.04+ / CentOS 8+ / macOS 10.15+

# Ressources minimales
RAM: 8GB minimum, 16GB recommandés
CPU: 4 cores minimum
Stockage: 20GB disponible
```

### Logiciels Requis

```bash
# Docker et Docker Compose
sudo apt update
sudo apt install docker.io docker-compose

# Java 11+
sudo apt install openjdk-11-jdk

# Maven
sudo apt install maven

# Vérification des versions
docker --version          # >= 20.10
docker-compose --version  # >= 1.29
java -version             # >= 11
mvn --version             # >= 3.6
```

### Binaires Hyperledger Fabric (Optionnel)

```bash
# Installation des binaires Fabric 3.1.1 (dernière version)
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- 3.1.1 1.6.0

# Ajouter au PATH
export PATH=$PATH:$PWD/fabric-samples/bin
export FABRIC_CFG_PATH=$PWD/fabric-samples/config
```

## 🚀 Processus de Déploiement

### Étape 1 : Préparation de l'Environnement

```bash
# Cloner le projet
git clone <repository-url>
cd my-blockchain

# Vérifier la structure
ls -la
# Doit contenir : chaincode-java/, api-java/, network/, scripts/

# Rendre les scripts exécutables
chmod +x scripts/*.sh
```

### Étape 2 : Configuration des Variables

```bash
# Variables d'environnement principales
export COMPOSE_PROJECT_NAME=foncier
export FABRIC_CFG_PATH=$PWD/network
export FABRIC_LOGGING_SPEC=INFO

# Variables Java
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export MAVEN_OPTS="-Xmx1024m"
```

### Étape 3 : Construction des Composants Java

```bash
# Construire le chaincode Java
echo "🔨 Construction du chaincode Java..."
cd chaincode-java
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
    echo "❌ Échec de la construction du chaincode"
    exit 1
fi
cd ..

# Construire l'API Spring Boot
echo "🔨 Construction de l'API REST..."
cd api-java  
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
    echo "❌ Échec de la construction de l'API"
    exit 1
fi
cd ..

echo "✅ Composants Java construits avec succès"
```

### Étape 4 : Génération des Artefacts Réseau

```bash
# Créer les répertoires nécessaires
mkdir -p network/channel-artifacts
mkdir -p network/organizations

# Générer les certificats MSP (simulation pour ce guide)
echo "🔐 Génération des certificats MSP..."

# Structure des certificats pour chaque organisation
for org in afor cvgfr prefet; do
    mkdir -p network/organizations/peerOrganizations/${org}.foncier.ci/{ca,msp,peers,users,orderers}
done

# Certificats pour l'orderer global
mkdir -p network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci

echo "✅ Structure des certificats créée"
```

### Étape 5 : Démarrage du Réseau Docker

```bash
# Nettoyer les conteneurs existants
echo "🧹 Nettoyage des conteneurs existants..."
docker-compose -f network/docker/docker-compose-new.yaml down --volumes --remove-orphans
docker container prune -f

# Démarrer les services
echo "🚀 Démarrage du réseau Fabric..."
docker-compose -f network/docker/docker-compose-new.yaml up -d

# Attendre le démarrage
echo "⏳ Attente du démarrage des services..."
sleep 30

# Vérifier le statut des conteneurs
echo "🔍 Vérification des conteneurs..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Étape 6 : Configuration des Canaux

```bash
# Utiliser l'API Channel Participation (Fabric 3.x)
echo "📊 Configuration des canaux spécialisés..."

# Créer les blocs de configuration de canaux
export FABRIC_CFG_PATH=$PWD/network

# Canal AFOR_CONTRAT_AGRAIRE
configtxgen -profile AFORContratAgraire \
           -configPath $PWD/network \
           -outputCreateChannelTx network/channel-artifacts/afor-contrat-agraire.tx \
           -channelID afor-contrat-agraire

# Canal AFOR_CERTIFICATE  
configtxgen -profile AFORCertificate \
           -configPath $PWD/network \
           -outputCreateChannelTx network/channel-artifacts/afor-certificate.tx \
           -channelID afor-certificate

# Canal ADMIN
configtxgen -profile AdminChannel \
           -configPath $PWD/network \
           -outputCreateChannelTx network/channel-artifacts/admin.tx \
           -channelID admin

echo "✅ Artefacts de canaux générés"
```

### Étape 7 : Déploiement du Chaincode Java

```bash
# Empaqueter le chaincode
echo "📦 Empaquetage du chaincode Java..."
docker exec cli peer lifecycle chaincode package foncier-chaincode.tar.gz \
    --path /opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode-java \
    --lang java \
    --label foncier-chaincode_1.0

# Installer sur les peers
echo "💾 Installation du chaincode sur les peers..."

# Installation sur peer AFOR
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_ADDRESS="peer0.afor.foncier.ci:7051"
docker exec cli peer lifecycle chaincode install foncier-chaincode.tar.gz

# Installation sur peer CVGFR
export CORE_PEER_LOCALMSPID="CVGFROrg"  
export CORE_PEER_ADDRESS="peer0.cvgfr.foncier.ci:8051"
docker exec cli peer lifecycle chaincode install foncier-chaincode.tar.gz

# Installation sur peer PREFET
export CORE_PEER_LOCALMSPID="PREFETOrg"
export CORE_PEER_ADDRESS="peer0.prefet.foncier.ci:9051"
docker exec cli peer lifecycle chaincode install foncier-chaincode.tar.gz

echo "✅ Chaincode installé sur tous les peers"
```

## 🔧 Configuration Post-Déploiement

### Vérification des Services

```bash
# Vérifier l'état des conteneurs
docker ps --filter "label=service=hyperledger-fabric"

# Tester la connectivité des peers
for peer in 7051 8051 9051; do
    echo "Test du peer sur le port $peer..."
    curl -k https://localhost:$peer/
done

# Vérifier CouchDB
for port in 5984 6984 7984; do
    echo "Test CouchDB sur le port $port..."
    curl http://admin:adminpw@localhost:$port/
done

# Tester l'API REST
echo "Test de l'API REST..."
curl http://localhost:8080/actuator/health
```

### Configuration des Identités

```bash
# Configurer les identités pour l'API
mkdir -p network/wallet

# Importer l'identité Admin AFOR pour l'API
# (Nécessite les vrais certificats en production)
echo "👤 Configuration des identités..."
```

## 📊 Monitoring et Maintenance

### Logs et Diagnostics

```bash
# Logs temps réel de tous les services
docker-compose -f network/docker/docker-compose-new.yaml logs -f

# Logs spécifiques
docker logs -f peer0.afor.foncier.ci
docker logs -f orderer.foncier.ci
docker logs -f foncier-api

# Métriques Prometheus (si activées)
curl http://localhost:9447/metrics  # Peer AFOR
curl http://localhost:9443/metrics  # Orderer global
```

### Sauvegarde

```bash
# Sauvegarder les volumes Docker
docker run --rm -v foncier_peer0.afor.foncier.ci:/source -v $PWD/backup:/backup alpine tar czf /backup/peer-afor-$(date +%Y%m%d).tar.gz /source

# Sauvegarder CouchDB
docker exec couchdb-afor couchdb-dump -H localhost -u admin -p adminpw > backup/couchdb-afor-$(date +%Y%m%d).json
```

## 🚨 Dépannage

### Problèmes Courants

**1. Conteneurs qui ne démarrent pas**
```bash
# Vérifier les ressources système
docker system df
free -h

# Nettoyer complètement
docker system prune -a --volumes
```

**2. Erreurs de certificats**
```bash
# Régénérer les certificats
rm -rf network/organizations/*
./scripts/generate-certificates.sh
```

**3. API non accessible**
```bash
# Vérifier les logs de l'API
docker logs foncier-api

# Redémarrer uniquement l'API
docker-compose restart foncier-api
```

**4. Problèmes de build Java**
```bash
# Nettoyer le cache Maven
mvn dependency:purge-local-repository

# Forcer la recompilation
mvn clean compile -U
```

### Diagnostic Avancé

```bash
# Vérifier l'état du réseau Fabric
docker exec cli peer channel list

# Vérifier les chaincodes installés
docker exec cli peer lifecycle chaincode queryinstalled

# Tester les transactions
docker exec cli peer chaincode invoke \
    -o orderer.foncier.ci:7050 \
    -C afor-contrat-agraire \
    -n foncier-chaincode \
    -c '{"function":"listerContrats","Args":[]}'
```

## 🔐 Sécurité en Production

### Configuration TLS

```bash
# Générer des certificats TLS valides
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout tls.key -out tls.crt \
    -subj "/CN=*.foncier.ci"

# Configurer TLS dans Docker Compose
# Mettre à jour CORE_PEER_TLS_* dans docker-compose-new.yaml
```

### Firewall et Réseau

```bash
# Règles firewall recommandées
sudo ufw allow 7050  # Orderer global
sudo ufw allow 7051  # Peer AFOR
sudo ufw allow 8051  # Peer CVGFR
sudo ufw allow 9051  # Peer PREFET
sudo ufw allow 8080  # API REST (avec reverse proxy recommandé)
```

### Gestion des Secrets

```bash
# Utiliser Docker Secrets en production
echo "mot_de_passe_secret" | docker secret create db_password -

# Configurer dans docker-compose.yml
services:
  couchdb-afor:
    secrets:
      - db_password
    environment:
      - COUCHDB_PASSWORD_FILE=/run/secrets/db_password
```

## 📈 Optimisation des Performances

### Configuration JVM

```bash
# Variables d'environnement pour l'API Java
export JAVA_OPTS="-Xms512m -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=100"

# Configuration Maven pour le build
export MAVEN_OPTS="-Xmx1g -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
```

### Paramètres CouchDB

```yaml
# Dans docker-compose-new.yaml, ajouter pour chaque CouchDB
environment:
  - COUCHDB_USER=admin
  - COUCHDB_PASSWORD=adminpw
  - COUCHDB_MAX_DBS_OPEN=500
  - COUCHDB_MAX_DOCUMENT_SIZE=64MB
```

### Monitoring Avancé

```bash
# Installation de Prometheus et Grafana (optionnel)
docker run -d --name prometheus -p 9090:9090 prom/prometheus
docker run -d --name grafana -p 3000:3000 grafana/grafana
```

## 🔄 Mise à Jour et Migration

### Mise à Jour du Chaincode

```bash
# 1. Construire la nouvelle version
cd chaincode-java
mvn clean package -DskipTests

# 2. Empaqueter avec une nouvelle version
docker exec cli peer lifecycle chaincode package foncier-chaincode-v1.1.tar.gz \
    --path /opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode-java \
    --lang java \
    --label foncier-chaincode_1.1

# 3. Installer et approuver sur tous les peers
# 4. Valider la mise à jour
```

### Sauvegarde Avant Mise à Jour

```bash
# Script de sauvegarde complète
#!/bin/bash
BACKUP_DIR="backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Sauvegarder les volumes
docker run --rm -v foncier_peer0.afor.foncier.ci:/source -v $PWD/$BACKUP_DIR:/backup alpine tar czf /backup/peers.tar.gz /source

# Sauvegarder CouchDB
for org in afor cvgfr prefet; do
    docker exec couchdb-$org couchdb-dump > $BACKUP_DIR/couchdb-$org.json
done

echo "Sauvegarde complétée dans $BACKUP_DIR"
```

---

**Note**: Ce guide couvre un déploiement de développement. Pour la production, des adaptations supplémentaires sont nécessaires (certificats CA réels, haute disponibilité, monitoring, etc.)