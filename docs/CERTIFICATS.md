# Génération des Certificats - Système Foncier Côte d'Ivoire

## 🔐 Architecture des Certificats Hyperledger Fabric 3.1.1

### Vue d'ensemble

Le système foncier ivoirien utilise une PKI (Public Key Infrastructure) robuste basée sur :
- **Certificate Authorities (CA)** : Une par organisation (AFOR, CVGFR, PREFET)
- **MSP (Membership Service Provider)** : Structure organisationnelle des identités
- **TLS** : Chiffrement des communications inter-noeuds
- **NodeOUs** : Identification granulaire des rôles (peer, client, admin, orderer)

## 🏗️ Structure des Certificats

### Organisations et CAs

```
network/organizations/
├── peerOrganizations/
│   ├── afor.foncier.ci/
│   │   ├── ca/                     # Certificats CA AFOR
│   │   ├── msp/                    # MSP organisationnel
│   │   ├── peers/peer0.afor.foncier.ci/
│   │   ├── users/Admin@afor.foncier.ci/
│   │   └── orderers/orderer-afor.foncier.ci/
│   ├── cvgfr.foncier.ci/
│   │   ├── ca/                     # Certificats CA CVGFR
│   │   └── ...
│   └── prefet.foncier.ci/
│       ├── ca/                     # Certificats CA PREFET
│       └── ...
└── ordererOrganizations/
    └── foncier.ci/
        ├── ca/                     # Certificats CA Orderer
        ├── msp/                    # MSP Orderer global
        └── orderers/orderer.foncier.ci/
```

### Rôles et Identités

| Organisation | CA Port | Identités | Rôles |
|--------------|---------|-----------|-------|
| **AFOR** | 7054 | Admin, peer0, user1, orderer-afor | Principal, validation |
| **CVGFR** | 8054 | Admin, peer0, user1, orderer-cvgfr | Validation locale |
| **PREFET** | 9054 | Admin, peer0, user1, orderer-prefet | Autorité administrative |

## 🛠️ Méthodes de Génération

### 1. Méthode cryptogen (Développement)

**Avantages** :
- ✅ Simple et rapide
- ✅ Parfait pour développement/test
- ✅ Génération automatique complète

**Usage** :
```bash
# Génération automatique avec cryptogen
./scripts/network.sh generateCerts

# Le script crée automatiquement crypto-config.yaml et génère tous les certificats
```

**Configuration automatique** (crypto-config.yaml) :
```yaml
OrdererOrgs:
  - Name: Orderer
    Domain: foncier.ci
    EnableNodeOUs: true
    Specs:
      - Hostname: orderer
      - Hostname: orderer-afor
      - Hostname: orderer-cvgfr  
      - Hostname: orderer-prefet

PeerOrgs:
  - Name: AFOR
    Domain: afor.foncier.ci
    EnableNodeOUs: true
    Template:
      Count: 1
    Users:
      Count: 1
  # ... CVGFR, PREFET
```

### 2. Méthode Fabric CA (Production)

**Avantages** :
- ✅ Production-ready
- ✅ Révocation des certificats
- ✅ Renouvellement automatique
- ✅ Audit et traçabilité

**Usage** :
```bash
# Si cryptogen n'est pas disponible, utilisation automatique de Fabric CA
./scripts/network.sh generateCerts

# Ou forcer l'utilisation de Fabric CA
export USE_FABRIC_CA=true
./scripts/network.sh generateCerts
```

**Processus Fabric CA** :
1. **Démarrage des CAs** : 3 containers Fabric CA (ports 7054, 8054, 9054)
2. **Enregistrement** : Créer les identités dans chaque CA
3. **Inscription** : Générer les certificats pour chaque identité
4. **Configuration MSP** : Structurer les certificats pour Fabric

## 🔧 Commandes de Gestion

### Nettoyage et Régénération

```bash
# Nettoyer tous les certificats existants
./scripts/network.sh cleanCerts

# Nettoyer et régénérer complètement
./scripts/network.sh generateCerts

# Démarrage complet avec génération
./scripts/network.sh up
```

### Vérification des Certificats

```bash
# Vérifier la structure des certificats
ls -la network/organizations/peerOrganizations/*/msp/

# Vérifier les CAs (si Fabric CA utilisé)
docker ps | grep "ca\."

# Tester la connectivité TLS
openssl s_client -connect localhost:7051 -cert network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/server.crt
```

## 📋 Configuration NodeOUs

### Structure MSP avec NodeOUs

Chaque organisation a un fichier `msp/config.yaml` :

```yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.afor.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.afor.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.afor.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.afor.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: orderer
```

### Avantages des NodeOUs

- **Identification granulaire** : Distinction automatique peer/client/admin/orderer
- **Sécurité renforcée** : Politiques basées sur les rôles
- **Compatibilité Fabric 3.1.1** : Requis pour les nouvelles fonctionnalités

## 🚨 Dépannage

### Problèmes Courants

**1. Erreur "certificate verify failed"**
```bash
# Régénérer tous les certificats
./scripts/network.sh cleanCerts
./scripts/network.sh generateCerts
```

**2. CA non accessible**
```bash
# Vérifier les ports des CAs
netstat -tulpn | grep -E "7054|8054|9054"

# Redémarrer les CAs
docker-compose -f network/docker/docker-compose-ca.yaml restart
```

**3. MSP mal configuré**
```bash
# Vérifier la structure MSP
find network/organizations/ -name "config.yaml" -exec cat {} \;

# Vérifier les certificats CA
find network/organizations/ -name "*-cert.pem" -exec openssl x509 -in {} -text -noout \;
```

### Validation des Certificats

```bash
# Script de validation automatique
#!/bin/bash

echo "🔍 Validation des certificats..."

# Vérifier la présence des CAs
for org in afor cvgfr prefet; do
    ca_cert="network/organizations/peerOrganizations/${org}.foncier.ci/ca/ca.${org}.foncier.ci-cert.pem"
    if [ -f "$ca_cert" ]; then
        echo "✅ CA $org : OK"
        # Vérifier la validité
        openssl x509 -in "$ca_cert" -noout -dates
    else
        echo "❌ CA $org : MANQUANT"
    fi
done

# Vérifier les MSP
for org in afor cvgfr prefet; do
    msp_config="network/organizations/peerOrganizations/${org}.foncier.ci/msp/config.yaml"
    if [ -f "$msp_config" ]; then
        echo "✅ MSP $org : OK"
    else
        echo "❌ MSP $org : MANQUANT"
    fi
done

echo "🎯 Validation terminée"
```

## 📊 Métriques de Sécurité

### Algorithmes Utilisés

| Composant | Algorithme | Taille Clé | Validité |
|-----------|------------|------------|----------|
| **Certificats CA** | ECDSA P-256 | 256 bits | 10 ans |
| **Certificats TLS** | RSA | 2048 bits | 1 an |
| **Signatures** | ECDSA | 256 bits | - |
| **Hachage** | SHA-256 | 256 bits | - |

### Rotation des Certificats

```bash
# Planification de rotation (production)
# Certificats CA : 10 ans
# Certificats TLS : 1 an  
# Certificats utilisateur : 1 an

# Script de renouvellement automatique
0 0 1 * * /opt/fabric/scripts/renew-certificates.sh
```

## 🎯 Bonnes Pratiques

### Sécurité
1. **Sauvegarde des clés privées CA** : Critiques pour la sécurité
2. **Rotation régulière** : Certificats utilisateurs annuellement
3. **Audit des accès** : Logs des opérations CA
4. **HSM en production** : Protection matérielle des clés

### Performance
1. **Cache des certificats** : Réduire les vérifications
2. **Pools de connexion TLS** : Optimiser les connexions
3. **Révocation efficace** : CRL ou OCSP
4. **Monitoring** : Alertes d'expiration

---

**Infrastructure PKI complète pour le système foncier ivoirien ! 🇨🇮🔐**

### Prochaines Étapes

1. **Générer** : `./scripts/network.sh generateCerts`
2. **Déployer** : `./scripts/quick-start.sh`
3. **Valider** : Tester les connexions TLS
4. **Monitorer** : Surveillance de l'expiration des certificats