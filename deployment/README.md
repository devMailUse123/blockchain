# 🌐 Configuration Déploiement Multi-VM

Ce dossier contient les configurations Docker Compose pour le déploiement distribué du réseau Hyperledger Fabric sur 4 VMs.

## 📁 Structure

```
deployment/
├── vm1-afor/
│   └── docker-compose.yml      # Peer AFOR + CA + CouchDB + API
├── vm2-cvgfr/
│   └── docker-compose.yml      # Peer CVGFR + CA + CouchDB
├── vm3-prefet/
│   └── docker-compose.yml      # Peer PREFET + CA + CouchDB
└── vm4-orderer/
    └── docker-compose.yml      # Orderer + CA
```

## 🎯 Architecture Cible

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   VM1       │     │   VM2       │     │   VM3       │
│   AFOR      │────▶│   CVGFR     │────▶│   PREFET    │
│ Peer:7051   │     │ Peer:8051   │     │ Peer:9051   │
│ CA:7054     │     │ CA:8054     │     │ CA:9054     │
│ CouchDB:5984│     │ CouchDB:6984│     │ CouchDB:7984│
│ API:3000    │     │             │     │             │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                     ┌─────▼──────┐
                     │   VM4      │
                     │  Orderer   │
                     │ Order:7050 │
                     │ CA:10054   │
                     └────────────┘
```

## 🚀 Déploiement Rapide

### Option 1 : Script Automatique (Recommandé)

```bash
# Depuis votre machine locale
cd /home/absolue/my-blockchain

# 1. Éditer le script avec vos IPs
nano scripts/deploy-multi-vm.sh
# Remplacer VM1_IP, VM2_IP, VM3_IP, VM4_IP

# 2. Déployer tout automatiquement
./scripts/deploy-multi-vm.sh deploy
```

### Option 2 : Déploiement Manuel

#### Étape 1 : Générer les certificats (sur machine locale)

```bash
cd /home/absolue/my-blockchain
cryptogen generate --config=./network/crypto-config.yaml --output=./network/organizations
```

#### Étape 2 : Copier les fichiers vers chaque VM

**VM1 (AFOR) :**
```bash
# Copier les certificats
scp -r network/organizations/peerOrganizations/afor.foncier.ci ubuntu@VM1_IP:/opt/fabric/organizations/
scp -r network/organizations/ordererOrganizations ubuntu@VM1_IP:/opt/fabric/organizations/

# Copier docker-compose
scp deployment/vm1-afor/docker-compose.yml ubuntu@VM1_IP:/opt/fabric/docker-compose.yml

# Remplacer les IPs dans docker-compose.yml
ssh ubuntu@VM1_IP
cd /opt/fabric
sed -i "s/ORDERER_IP_HERE/VM4_IP_REELLE/g" docker-compose.yml
sed -i "s/CVGFR_IP_HERE/VM2_IP_REELLE/g" docker-compose.yml
sed -i "s/PREFET_IP_HERE/VM3_IP_REELLE/g" docker-compose.yml
```

**VM2 (CVGFR) :**
```bash
scp -r network/organizations/peerOrganizations/cvgfr.foncier.ci ubuntu@VM2_IP:/opt/fabric/organizations/
scp -r network/organizations/ordererOrganizations ubuntu@VM2_IP:/opt/fabric/organizations/
scp deployment/vm2-cvgfr/docker-compose.yml ubuntu@VM2_IP:/opt/fabric/docker-compose.yml

ssh ubuntu@VM2_IP
cd /opt/fabric
sed -i "s/ORDERER_IP_HERE/VM4_IP_REELLE/g" docker-compose.yml
sed -i "s/AFOR_IP_HERE/VM1_IP_REELLE/g" docker-compose.yml
sed -i "s/PREFET_IP_HERE/VM3_IP_REELLE/g" docker-compose.yml
```

**VM3 (PREFET) :**
```bash
scp -r network/organizations/peerOrganizations/prefet.foncier.ci ubuntu@VM3_IP:/opt/fabric/organizations/
scp -r network/organizations/ordererOrganizations ubuntu@VM3_IP:/opt/fabric/organizations/
scp deployment/vm3-prefet/docker-compose.yml ubuntu@VM3_IP:/opt/fabric/docker-compose.yml

ssh ubuntu@VM3_IP
cd /opt/fabric
sed -i "s/ORDERER_IP_HERE/VM4_IP_REELLE/g" docker-compose.yml
sed -i "s/AFOR_IP_HERE/VM1_IP_REELLE/g" docker-compose.yml
sed -i "s/CVGFR_IP_HERE/VM2_IP_REELLE/g" docker-compose.yml
```

**VM4 (Orderer) :**
```bash
scp -r network/organizations/ordererOrganizations/foncier.ci ubuntu@VM4_IP:/opt/fabric/organizations/
scp -r network/organizations/peerOrganizations ubuntu@VM4_IP:/opt/fabric/organizations/
scp deployment/vm4-orderer/docker-compose.yml ubuntu@VM4_IP:/opt/fabric/docker-compose.yml

ssh ubuntu@VM4_IP
cd /opt/fabric
sed -i "s/AFOR_IP_HERE/VM1_IP_REELLE/g" docker-compose.yml
sed -i "s/CVGFR_IP_HERE/VM2_IP_REELLE/g" docker-compose.yml
sed -i "s/PREFET_IP_HERE/VM3_IP_REELLE/g" docker-compose.yml
```

#### Étape 3 : Démarrer les conteneurs

**Orderer en premier (VM4) :**
```bash
ssh ubuntu@VM4_IP
cd /opt/fabric
docker-compose up -d
docker ps  # Vérifier que orderer et ca-orderer sont UP
```

**Puis les peers (VM1, VM2, VM3) :**
```bash
# VM1
ssh ubuntu@VM1_IP
cd /opt/fabric
docker-compose up -d

# VM2
ssh ubuntu@VM2_IP
cd /opt/fabric
docker-compose up -d

# VM3
ssh ubuntu@VM3_IP
cd /opt/fabric
docker-compose up -d
```

#### Étape 4 : Vérifier le réseau

```bash
# Sur chaque VM
docker ps
docker logs peer0.afor.foncier.ci   # (sur VM1)
docker logs peer0.cvgfr.foncier.ci  # (sur VM2)
docker logs peer0.prefet.foncier.ci # (sur VM3)
docker logs orderer.foncier.ci      # (sur VM4)
```

## 📋 Configuration des Fichiers

### Variables à Remplacer

Chaque `docker-compose.yml` contient des placeholders à remplacer :

| Placeholder | Description | Exemple |
|-------------|-------------|---------|
| `AFOR_IP_HERE` | IP de la VM1 (AFOR) | `10.0.1.10` |
| `CVGFR_IP_HERE` | IP de la VM2 (CVGFR) | `10.0.2.10` |
| `PREFET_IP_HERE` | IP de la VM3 (PREFET) | `10.0.3.10` |
| `ORDERER_IP_HERE` | IP de la VM4 (Orderer) | `10.0.4.10` |

### Ports Utilisés

**VM1 (AFOR) :**
- `7051` : Peer AFOR
- `7054` : CA AFOR
- `5984` : CouchDB AFOR
- `9447` : Metrics Peer AFOR
- `3000` : API REST

**VM2 (CVGFR) :**
- `8051` : Peer CVGFR
- `8054` : CA CVGFR
- `6984` : CouchDB CVGFR (mappé depuis 5984 interne)
- `9448` : Metrics Peer CVGFR

**VM3 (PREFET) :**
- `9051` : Peer PREFET
- `9054` : CA PREFET
- `7984` : CouchDB PREFET (mappé depuis 5984 interne)
- `9449` : Metrics Peer PREFET

**VM4 (Orderer) :**
- `7050` : Orderer
- `7053` : Admin API Orderer
- `10054` : CA Orderer
- `9443` : Metrics Orderer

## 🔧 Gestion du Réseau

### Démarrer le réseau
```bash
# Sur chaque VM
cd /opt/fabric
docker-compose up -d
```

### Arrêter le réseau
```bash
# Sur chaque VM
cd /opt/fabric
docker-compose down
```

### Redémarrer un service
```bash
# Exemple : redémarrer le peer AFOR
docker-compose restart peer0.afor.foncier.ci
```

### Voir les logs
```bash
# Logs en temps réel
docker-compose logs -f peer0.afor.foncier.ci

# Logs des 100 dernières lignes
docker logs --tail 100 peer0.afor.foncier.ci
```

## 🔍 Dépannage

### Conteneur ne démarre pas

```bash
# Vérifier les logs
docker logs <container_name>

# Vérifier la configuration
docker inspect <container_name>

# Vérifier le réseau Docker
docker network inspect fabric-network
```

### Problèmes de connectivité entre VMs

```bash
# Tester la connectivité réseau
ping <autre_vm_ip>

# Tester un port spécifique
nc -zv <autre_vm_ip> 7050

# Vérifier les routes
ip route

# Vérifier les règles de pare-feu
sudo ufw status
```

### CouchDB non accessible

```bash
# Vérifier que CouchDB est démarré
docker ps | grep couchdb

# Vérifier les logs CouchDB
docker logs couchdb-afor

# Tester l'accès local
curl http://admin:adminpw@localhost:5984/_up

# Tester l'accès depuis l'extérieur
curl http://admin:adminpw@<vm_ip>:5984/_up
```

### Peer ne se connecte pas à l'orderer

```bash
# Vérifier les extra_hosts dans docker-compose.yml
docker inspect peer0.afor.foncier.ci | grep -A 10 ExtraHosts

# Tester la résolution DNS depuis le conteneur
docker exec peer0.afor.foncier.ci ping -c 3 orderer.foncier.ci

# Vérifier les certificats TLS
docker exec peer0.afor.foncier.ci ls -la /etc/hyperledger/fabric/tls/
```

## 📊 Monitoring

### Vérifier la santé des conteneurs

```bash
# Sur chaque VM
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Métriques Prometheus

```bash
# Peer AFOR
curl http://VM1_IP:9447/metrics

# Orderer
curl http://VM4_IP:9443/metrics
```

### CouchDB Stats

```bash
# Bases de données
curl http://admin:adminpw@VM1_IP:5984/_all_dbs

# Documents d'un canal
curl http://admin:adminpw@VM1_IP:5984/afor-contrat-agraire/_all_docs
```

## 🔐 Sécurité

### Recommandations

1. **Changer les mots de passe par défaut**
   - CouchDB : `admin/adminpw` → fort mot de passe
   - CA : `admin/adminpw` → fort mot de passe

2. **Restreindre l'accès réseau**
   ```bash
   # Utiliser ufw sur chaque VM
   sudo ufw enable
   sudo ufw allow from <ip_autorisee> to any port 7051
   ```

3. **Activer les logs d'audit**
   ```yaml
   environment:
     - FABRIC_LOGGING_SPEC=INFO:cauthdsl,policies,msp=DEBUG
   ```

4. **Monitoring des accès**
   - Surveiller les logs d'authentification
   - Alertes sur tentatives d'accès non autorisées

## 📚 Ressources

- **Guide de Déploiement** : `../GUIDE-DEPLOIEMENT-PRODUCTION.md`
- **Checklist** : `../CHECKLIST-DEPLOIEMENT.md`
- **Script Automatique** : `../scripts/deploy-multi-vm.sh`
- **Maintenance** : `../scripts/maintenance.sh`

## 🆘 Support

En cas de problème :
1. Consulter les logs Docker
2. Vérifier la connectivité réseau
3. Consulter `../GUIDE-DEPLOIEMENT-PRODUCTION.md`
4. Ouvrir une issue sur GitHub

---

**Dernière mise à jour** : 30 Octobre 2025
