# 🚀 Guide de Déploiement Automatique - Réseau Blockchain Foncier CI

Ce guide explique comment déployer automatiquement le réseau Hyperledger Fabric 3.1.1 sur un serveur distant.

## 📋 Table des Matières

- [Prérequis Serveur](#prérequis-serveur)
- [Déploiement Initial](#déploiement-initial)
- [Déploiement avec GitHub Actions](#déploiement-avec-github-actions)
- [Variables d'Environnement](#variables-denvironnement)
- [Maintenance](#maintenance)

---

## 🖥️ Prérequis Serveur

Le serveur doit avoir :

### Logiciels Requis
```bash
# Docker 20.10+
docker --version

# Docker Compose 2.0+
docker-compose --version

# Git
git --version

# curl
curl --version
```

### Configuration Système
- **OS**: Ubuntu 20.04 LTS ou supérieur
- **RAM**: Minimum 8 GB (16 GB recommandé)
- **CPU**: Minimum 4 cores (8 cores recommandé)
- **Disque**: Minimum 50 GB disponible
- **Ports ouverts**: 
  - 7050, 7051, 7053 (Orderer)
  - 8051, 9051 (Peers)
  - 7054, 8054, 9054, 10054 (CAs)
  - 5984, 6984, 7984 (CouchDB)
  - 3000 (API REST)

### Installation des Prérequis

```bash
#!/bin/bash
# Installation sur Ubuntu 20.04/22.04

# 1. Mettre à jour le système
sudo apt-get update
sudo apt-get upgrade -y

# 2. Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# 3. Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 4. Installer les binaires Fabric 3.1.1
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- binary

# 5. Ajouter les binaires au PATH
echo 'export PATH=$PATH:$HOME/fabric-samples/bin' >> ~/.bashrc
source ~/.bashrc

# 6. Vérifier les installations
docker --version
docker-compose --version
peer version
fabric-ca-client version
```

---

## 🚀 Déploiement Initial

### Étape 1 : Cloner le Repository

```bash
# Se connecter au serveur
ssh user@votre-serveur.com

# Cloner le projet
git clone https://github.com/VOTRE-USERNAME/my-blockchain.git
cd my-blockchain
```

### Étape 2 : Configuration

```bash
# Copier le fichier d'environnement exemple
cp .env.example .env

# Éditer les variables d'environnement
nano .env
```

Exemple de fichier `.env` :
```bash
# Réseau
FABRIC_VERSION=3.1.1
FABRIC_CA_VERSION=1.5
COUCHDB_VERSION=3.3.2

# Domaine
DOMAIN=foncier.ci

# Ports
ORDERER_PORT=7050
PEER_AFOR_PORT=7051
PEER_CVGFR_PORT=8051
PEER_PREFET_PORT=9051

# API
API_PORT=3000
API_LOG_LEVEL=info
```

### Étape 3 : Déploiement Automatique

```bash
# Rendre les scripts exécutables
chmod +x scripts/*.sh

# Déployer le réseau complet
./scripts/deploy-complete.sh

# Vérifier le déploiement
docker ps
```

Le script `deploy-complete.sh` effectue automatiquement :
1. ✅ Vérification des prérequis
2. ✅ Nettoyage de l'environnement
3. ✅ Démarrage des CAs
4. ✅ Génération des certificats
5. ✅ Création du genesis block
6. ✅ Démarrage du réseau
7. ✅ Création du channel
8. ✅ Jonction des peers

---

## 🔄 Déploiement avec GitHub Actions

### Workflow CI/CD Automatique

Le projet inclut un workflow GitHub Actions pour déployer automatiquement sur votre serveur.

#### Configuration des Secrets GitHub

Allez dans `Settings > Secrets and variables > Actions` et ajoutez :

| Secret Name | Description | Exemple |
|------------|-------------|---------|
| `SERVER_HOST` | IP ou domaine du serveur | `192.168.1.100` |
| `SERVER_USER` | Utilisateur SSH | `ubuntu` |
| `SERVER_SSH_KEY` | Clé privée SSH | `-----BEGIN RSA PRIVATE KEY-----...` |
| `SERVER_PORT` | Port SSH (optionnel) | `22` |

#### Fichier Workflow

Le fichier `.github/workflows/deploy.yml` est déjà configuré. Chaque push sur `main` déclenche :

1. Tests de validation
2. Build des composants
3. Déploiement sur le serveur
4. Vérification post-déploiement

#### Déclenchement Manuel

Vous pouvez aussi déclencher le déploiement manuellement :

```bash
# Via l'interface GitHub
Actions > Deploy to Server > Run workflow

# Via GitHub CLI
gh workflow run deploy.yml
```

---

## 🔐 Variables d'Environnement

### Fichier `.env.example`

Créez ce fichier à la racine du projet :

```bash
# ============================================================================
# CONFIGURATION RÉSEAU FABRIC 3.1.1 - CÔTE D'IVOIRE
# ============================================================================

# Versions
FABRIC_VERSION=3.1.1
FABRIC_CA_VERSION=1.5.15
COUCHDB_VERSION=3.3.2

# Domaine
DOMAIN=foncier.ci
NETWORK_NAME=foncier

# Organisations
ORG1_NAME=AFOR
ORG2_NAME=CVGFR
ORG3_NAME=PREFET

# Ports - Orderer
ORDERER_PORT=7050
ORDERER_ADMIN_PORT=7053
ORDERER_OPERATIONS_PORT=9443

# Ports - Peers
PEER_AFOR_PORT=7051
PEER_AFOR_CHAINCODE_PORT=7052
PEER_AFOR_OPERATIONS_PORT=9447

PEER_CVGFR_PORT=8051
PEER_CVGFR_CHAINCODE_PORT=8052
PEER_CVGFR_OPERATIONS_PORT=9448

PEER_PREFET_PORT=9051
PEER_PREFET_CHAINCODE_PORT=9052
PEER_PREFET_OPERATIONS_PORT=9449

# Ports - CAs
CA_AFOR_PORT=7054
CA_CVGFR_PORT=8054
CA_PREFET_PORT=9054
CA_ORDERER_PORT=10054

# Ports - CouchDB
COUCHDB_AFOR_PORT=5984
COUCHDB_CVGFR_PORT=6984
COUCHDB_PREFET_PORT=7984

# CouchDB Credentials
COUCHDB_USER=admin
COUCHDB_PASSWORD=adminpw

# API REST
API_PORT=3000
API_HOST=0.0.0.0
API_LOG_LEVEL=info

# Chaincode
CHAINCODE_NAME=contrats-fonciers
CHAINCODE_VERSION=1.0
CHAINCODE_SEQUENCE=1

# Channel
CHANNEL_NAME=contrats-fonciers

# Logging
LOG_LEVEL=INFO
FABRIC_LOGGING_SPEC=INFO

# Monitoring (optionnel)
PROMETHEUS_ENABLED=true
GRAFANA_ENABLED=true
```

---

## 🛠️ Maintenance

### Redémarrer le Réseau

```bash
cd my-blockchain

# Arrêter tout
./scripts/network.sh down

# Redémarrer
./scripts/deploy-complete.sh
```

### Mettre à Jour depuis Git

```bash
cd my-blockchain

# Sauvegarder les données (si nécessaire)
docker-compose -f deploy/docker-compose.yaml exec couchdb-afor curl -X GET http://admin:adminpw@localhost:5984/_all_dbs

# Arrêter le réseau
docker-compose -f deploy/docker-compose.yaml down

# Mettre à jour le code
git pull origin main

# Redéployer
./scripts/deploy-complete.sh
```

### Sauvegarder les Données

```bash
# Sauvegarder les volumes Docker
docker run --rm -v deploy_orderer.foncier.ci:/data -v $(pwd)/backup:/backup ubuntu tar czf /backup/orderer-$(date +%Y%m%d).tar.gz /data

# Sauvegarder CouchDB
curl -X GET http://admin:adminpw@localhost:5984/_all_dbs | jq -r '.[]' | while read db; do
  curl -X GET http://admin:adminpw@localhost:5984/$db/_all_docs?include_docs=true > backup/$db-$(date +%Y%m%d).json
done
```

### Logs et Debugging

```bash
# Voir les logs d'un conteneur
docker logs orderer.foncier.ci
docker logs peer0.afor.foncier.ci

# Suivre les logs en temps réel
docker logs -f orderer.foncier.ci

# Voir tous les conteneurs
docker ps -a

# Entrer dans un conteneur
docker exec -it cli bash
```

### Métriques et Monitoring

```bash
# Prometheus (si activé)
curl http://localhost:9443/metrics

# Vérifier la santé des peers
curl http://localhost:9447/healthz

# Lister les channels
peer channel list
```

---

## 🔒 Sécurité

### Bonnes Pratiques

1. **NE JAMAIS commiter** :
   - Certificats (*.pem, *.key, *.crt)
   - Fichiers .env avec credentials
   - Données blockchain (production/)

2. **Toujours utiliser** :
   - TLS pour toutes les communications
   - Secrets GitHub pour les credentials
   - Pare-feu pour limiter l'accès aux ports

3. **Régulièrement** :
   - Mettre à jour les dépendances
   - Sauvegarder les données
   - Auditer les logs

### Génération de Nouveaux Certificats

```bash
# Sur le serveur de production
cd my-blockchain

# Nettoyer les anciens certificats
sudo rm -rf network/organizations/ordererOrganizations
sudo rm -rf network/organizations/peerOrganizations

# Régénérer avec Fabric CA
./scripts/setup-ca.sh full
```

---

## 📞 Support

Pour toute question ou problème :

1. Consulter les logs : `docker logs <container-name>`
2. Vérifier le statut : `docker ps`
3. Consulter la documentation : `docs/`
4. Ouvrir une issue sur GitHub

---

## 📝 Checklist de Déploiement

- [ ] Serveur configuré avec les prérequis
- [ ] Repository cloné
- [ ] Variables d'environnement configurées
- [ ] Secrets GitHub configurés (pour CI/CD)
- [ ] Scripts rendus exécutables
- [ ] Pare-feu configuré
- [ ] DNS configuré (si applicable)
- [ ] Certificats SSL (pour API en HTTPS)
- [ ] Déploiement testé
- [ ] Monitoring activé
- [ ] Sauvegardes planifiées

---

**Dernière mise à jour** : 19 octobre 2025  
**Version** : 1.0.0  
**Fabric** : 3.1.1
