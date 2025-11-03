# 🌾 Blockchain Foncière - Côte d'Ivoire

[![Fabric](https://img.shields.io/badge/Hyperledger%20Fabric-3.1.1-blue)](https://www.hyperledger.org/use/fabric)
[![Java](https://img.shields.io/badge/Chaincode-Java%2011-orange)](https://openjdk.org/)
[![Node.js](https://img.shields.io/badge/API-Node.js%2018+-green)](https://nodejs.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Plateforme de sécurisation des droits fonciers ruraux basée sur **Hyperledger Fabric 3.1.1** avec chaincode Java et API REST Node.js.

## 🎯 Vue d'Ensemble

Système blockchain pour la gestion sécurisée des contrats fonciers ruraux en Côte d'Ivoire, permettant:

- ✅ **Enregistrement immuable** des contrats fonciers
- ✅ **Traçabilité complète** de l'historique des transactions
- ✅ **API REST** pour l'intégration avec applications externes
- ✅ **Multi-organisations** (AFOR, CVGFR, PREFET)
- ✅ **Sécurité renforcée** avec certificats X.509 et TLS

## 🏗️ Architecture

### Réseau Hyperledger Fabric

**3 Organisations** + **1 Orderer**

- ✅ **Traçabilité complète** des transactions

- ✅ **Validation multi-parties** (AFOR, CVGFR, Préfet)| Organisation | Description | Rôle |

- ✅ **Recherche avancée** par terrain, propriétaire, bénéficiaire|-------------|-------------|------|

- ✅ **Déterminisme garanti** - Pas d'erreurs de consensus| **AFOR** | Agence Foncière Rurale de Côte d'Ivoire | Gestion principale des contrats fonciers |

| **CVGFR** | Comité Villageois de Gestion Foncière Rurale | Validation locale des contrats agraires |

---| **PREFET** | Préfecture Ivoirienne | Autorité administrative pour les certificats officiels |



## 🏗️ Architecture### Canaux Spécialisés



### Organisations| Canal | Participants | Usage | Chaincode |

|-------|-------------|-------|-----------|

| Organisation | Port Peer | Port CouchDB | Rôle || **CONTRAT-AGRAIRE** | AFOR + CVGFR | Contrats agraires entre propriétaires et exploitants | ✅ contrats-fonciers v1.0 |

|-------------|-----------|--------------|------|| **ADMIN** | AFOR + CVGFR + PREFET | Administration et supervision du réseau | ⏳ À déployer |

| **AFOR** | 7051 | 5984 | Agence Foncière Rurale - Gestion principale |

| **CVGFR** | 8051 | 6984 | Comité Villageois - Validation locale |> 📖 **Documentation détaillée**: Voir [CHANNEL-ARCHITECTURE.md](docs/CHANNEL-ARCHITECTURE.md)

| **PREFET** | 9051 | 7984 | Préfecture - Autorité administrative |

### Infrastructure Technique

### Canaux Blockchain

```

| Canal | Participants | Usage |📦 Réseau Fabric 3.1.1 avec 2 Channels

|-------|-------------|-------|├── 🏢 1 Orderer (EtcdRaft consensus)

| **contrat-agraire** | AFOR + CVGFR | Contrats entre propriétaires et exploitants |│   └── orderer.foncier.ci:7050

| **contrats-fonciers** | AFOR + CVGFR + PREFET | Tous les contrats fonciers |├── 🖥️ 3 Peers (un par organisation)

│   ├── peer0.afor.foncier.ci:7051        (CONTRAT-AGRAIRE + ADMIN)

### Chaincode Déployé│   ├── peer0.cvgfr.foncier.ci:8051       (CONTRAT-AGRAIRE + ADMIN)

│   └── peer0.prefet.foncier.ci:9051      (ADMIN uniquement)

```├── 🗄️ 3 CouchDB (base de données par organisation)

Nom:      foncier│   ├── couchdb-afor:5984

Version:  4.0│   ├── couchdb-cvgfr:6984

Type:     Java (fabric-contract-api)│   └── couchdb-prefet:7984

Status:   ✅ Déterministe (DeterministicMapper)├── 🔐 4 Certificate Authorities (Fabric CA 1.5.15)

```│   ├── ca-afor:7054

│   ├── ca-cvgfr:8054

---│   ├── ca-prefet:9054

│   └── ca-orderer:10054

## 🚀 Quick Start├── ⚙️ Chaincode Java (fabric-contract-api)

└── 🌐 API REST Node.js Express:3000

### Prérequis```



- Docker & Docker Compose## 🚀 Démarrage Rapide

- Java 11+

- Maven 3.6+### Prérequis

- Node.js 20+ (pour l'API)

- Hyperledger Fabric 3.1.1 binaries- **Docker** 20.10+

- **Docker Compose** 3.8+

### Installation Complète (1 commande)- **Java** 11+

- **Maven** 3.6+

```bash- **Git**

# Compiler, packager, démarrer réseau et déployer chaincode

make quick### Installation Automatique Complète

```

```bash

### Commandes Détaillées# Cloner le projet

git clone <repository-url>

```bashcd my-blockchain

# 1. Compiler le chaincode

make build# Déploiement automatique complet (tout-en-un)

./scripts/deploy-complete.sh

# 2. Créer le package```

make package

Ce script automatique exécute **14 étapes** :

# 3. Démarrer le réseau1. ✅ Vérification des prérequis (Docker, Java, jq, yq)

make network-up2. 🧹 Nettoyage de l'environnement

3. 🔐 Démarrage des 4 Certificate Authorities

# 4. Déployer le chaincode4. � Enrollment des identités (MSP + TLS)

make deploy-full5. 📋 Génération des genesis blocks (2 channels)

6. 🌐 Démarrage du réseau (orderer + 3 peers + 3 CouchDB)

# 5. Tester la création d'un contrat7. ✓ Vérification de l'orderer

make test-create8. � Création des 2 channels (CONTRAT-AGRAIRE + ADMIN)

9. 🔗 Jonction des peers aux channels

# 6. Interroger un contrat10. 📦 Build et package du chaincode Java

make test-query ID=TEST-2024-00111. ✓ Approbation du chaincode (AFOR + CVGFR)

12. ✓ Commit du chaincode sur CONTRAT-AGRAIRE

# 7. Vérifier CouchDB13. 🧪 Test du chaincode

make test-couchdb ID=TEST-2024-00114. 📊 Résumé du déploiement

```

### Démarrage Quick Start (10 minutes)

### Arrêt et Nettoyage

```bash

```bash# Script rapide pour démarrage

# Arrêter le réseau (avec suppression des volumes)./scripts/quick-start.sh

make network-down```



# Nettoyer les artefacts de build## 📊 Services Disponibles

make clean

Une fois déployé, les services suivants sont accessibles :

# Voir les logs

make logs### API REST

```- **URL**: http://localhost:8080

- **Documentation**: http://localhost:8080/swagger-ui.html

---- **Monitoring**: http://localhost:8080/actuator/health



## 📁 Structure du Projet### Bases de Données CouchDB

- **AFOR**: http://localhost:5984/_utils (admin/adminpw)

```- **CVGFR**: http://localhost:6984/_utils (admin/adminpw)  

my-blockchain/- **PREFET**: http://localhost:7984/_utils (admin/adminpw)

├── chaincode-java/          # Chaincode Java avec DeterministicMapper

│   ├── src/### Endpoints Fabric

│   │   └── main/java/ci/foncier/chaincode/- **Peers**: 7051 (AFOR), 8051 (CVGFR), 9051 (PREFET)

│   │       ├── FoncierChaincode.java    # Contrat principal- **Orderers**: 7050 (global), 7250 (AFOR), 8050 (CVGFR), 9050 (PREFET)

│   │       ├── models/                   # Modèles de données

│   │       └── util/## 🔧 Utilisation de l'API

│   │           └── DeterministicMapper.java  # Sérialisation déterministe

│   └── pom.xml### Authentification

│L'API utilise JWT pour l'authentification. Obtenez un token :

├── deploy/                   # Configuration réseau Fabric

│   ├── docker-compose.yaml   # 3 orgs + orderer + CouchDB```bash

│   └── configtx.yaml         # Configuration des canauxcurl -X POST http://localhost:8080/api/v1/auth/login \

│  -H "Content-Type: application/json" \

├── scripts/                  # Scripts d'automatisation  -d '{"username": "admin", "password": "password"}'

│   ├── deploy-full.sh        # Déploiement complet du chaincode```

│   ├── package-chaincode.sh  # Packaging du chaincode

│   ├── create-channels.sh    # Création des canaux### Créer un Contrat Agraire

│   ├── join-channels.sh      # Jonction des peers

│   ├── test-create-contract.sh   # Test de création```bash

│   ├── test-query-contracts.sh   # Test de requêtecurl -X POST http://localhost:8080/api/v1/contrats \

│   └── test-couchdb.sh       # Vérification CouchDB  -H "Authorization: Bearer <token>" \

│  -H "Content-Type: application/json" \

├── api/                      # API REST Node.js  -d '{

│   ├── server.js    "id": "CA-GUI-001",

│   ├── routes/    "type": "CONTRAT_AGRAIRE",

│   └── services/    "region": "Bouaké",

│    "proprietaire": {

├── test-data/                # Données de test      "nom": "Kouassi",

│   └── contrat-simple.json   # Contrat de test déterministe      "prenoms": "Yves",

│      "typePieceIdentite": "CNI",

├── docs/                     # Documentation      "numeroPiece": "123456789",

│   ├── API.md               # Spécification API REST      "typePersonne": "PHYSIQUE"

│   └── DEPLOYMENT.md        # Guide de déploiement    },

│    "terrain": {

├── network/                  # Certificats et artefacts Fabric      "localisation": "Village de Sobané",

│   ├── configtx.yaml        # Configuration initiale      "superficie": 2.5,

│   ├── configtx-channel.yaml      "unite": "HECTARE",

│   └── channel-artifacts/      "typeTitre": "CERTIFICAT",

│      "statutJuridique": "COUTUMIER",

├── Makefile                 # Automation principale      "usageAutorise": "AGRICOLE"

├── README.md                # Ce fichier    }

└── SUCCESS_REPORT.md        # Rapport de déploiement réussi  }'

``````



---### Rechercher des Contrats



## 🧪 Tests```bash

# Par propriétaire

### Test de Création de Contratcurl http://localhost:8080/api/v1/contrats/search/proprietaire?nom=Kouassi



```bash# Par région

make test-createcurl http://localhost:8080/api/v1/contrats/search/region?region=Bouaké

```

# Par type

**Résultat attendu**:curl http://localhost:8080/api/v1/contrats/search/type?type=CONTRAT_AGRAIRE

``````

✅ CONTRAT CRÉÉ AVEC SUCCÈS !

status:200## 🛠️ Développement

```

### Structure du Projet

### Test de Requête

```

```bashmy-blockchain/

make test-query ID=TEST-2024-001├── chaincode-java/          # Chaincode Java (Smart Contracts)

```│   ├── src/main/java/       # Code source

│   └── pom.xml             # Configuration Maven

**Résultat attendu**:├── api-java/               # API REST Spring Boot

```json│   ├── src/main/java/      # Code source Spring Boot

{│   ├── src/main/resources/ # Configuration Spring

  "uuid": "550e8400-e29b-41d4-a716-446655440000",│   └── pom.xml             # Configuration Maven

  "codeContract": "TEST-2024-001",├── network/                # Configuration Fabric

  "type": "LOCATION",│   ├── configtx-*.yaml     # Configurations des canaux

  "owner": {...},│   └── docker/             # Docker Compose

  "beneficiary": {...},├── scripts/                # Scripts d'automatisation

  "terrain": {...}└── docs/                   # Documentation

}```

```

### Modifier le Chaincode

### Vérification CouchDB

1. Éditez le code dans `chaincode-java/src/main/java/`

```bash2. Reconstruisez : `cd chaincode-java && mvn clean package`

# Via le script3. Redéployez : `./scripts/network-new.sh deployChaincode`

make test-couchdb ID=TEST-2024-001

### Modifier l'API

# Via Web UI

# AFOR:  http://localhost:5984/_utils1. Éditez le code dans `api-java/src/main/java/`

# CVGFR: http://localhost:6984/_utils2. Reconstruisez : `cd api-java && mvn clean package`

```3. Redémarrez : `docker-compose restart foncier-api`



---## 📋 Commandes Utiles



## 🔧 Makefile - Toutes les Commandes### Gestion du Réseau

```bash

```bash# Démarrer le réseau

make help              # Afficher l'aide./scripts/network-new.sh up

make build             # Compiler le chaincode Java

make package           # Créer le package .tar.gz# Arrêter le réseau

make network-up        # Démarrer le réseau Fabric./scripts/network-new.sh down

make network-down      # Arrêter le réseau (avec -v)

make deploy-full       # Déploiement complet du chaincode# Redémarrer le réseau

make test-create       # Créer un contrat de test./scripts/network-new.sh restart

make test-query        # Interroger un contrat

make test-couchdb      # Vérifier CouchDB# Voir le statut

make quick             # network-up + deploy-full./scripts/network-new.sh status

make clean             # Nettoyer les artefacts```

make logs              # Afficher les logs Docker

```### Monitoring et Logs

```bash

---# Logs de l'API

docker logs -f foncier-api

## 🛡️ Solution du Problème de Déterminisme

# Logs d'un peer

### Problème Initialdocker logs -f peer0.afor.foncier.ci



```# Logs d'un orderer

Error: ENDORSEMENT_POLICY_FAILUREdocker logs -f orderer.foncier.ci

ProposalResponsePayloads do not match

```# Statut des conteneurs

docker ps

### Causes Identifiées```



1. **UUID aléatoire**: `UUID.randomUUID()` générait des valeurs différentes sur chaque peer### Base de Données

2. **Timestamp aléatoire**: `LocalDateTime.now()` créait des timestamps différents```bash

3. **Sérialisation JSON inconsistante**: Jackson formatait les dates différemment# Se connecter à CouchDB AFOR

curl http://admin:adminpw@localhost:5984/_all_dbs

### Solution Implémentée

# Voir les documents du canal

#### DeterministicMappercurl http://admin:adminpw@localhost:5984/afor-contrat-agraire/_all_docs

```

Classe utilitaire garantissant une sérialisation JSON 100% déterministe:

## 🔐 Sécurité

```java

public class DeterministicMapper {### Certificats TLS

    private static final DateTimeFormatter FORMATTER = Tous les communications utilisent TLS avec des certificats générés pour chaque organisation.

        DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    ### Authentification

    public static ObjectMapper create() {- **API**: JWT avec expiration configurable

        ObjectMapper mapper = new ObjectMapper();- **Fabric**: Certificats X.509 et MSP

        

        JavaTimeModule javaTimeModule = new JavaTimeModule();### Autorisation

        javaTimeModule.addSerializer(LocalDateTime.class, - **Chaincode**: Politiques d'endorsement par canal

            new LocalDateTimeSerializer(FORMATTER));- **API**: Rôles basés sur l'organisation

        

        mapper.registerModule(javaTimeModule);## 🌍 Canaux et Cas d'Usage

        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

        mapper.disable(SerializationFeature.WRITE_DATES_WITH_ZONE_ID);### AFOR_CONTRAT_AGRAIRE

        mapper.configure(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS, true);- **Participants**: AFOR, CVGFR

        - **Usage**: Contrats de location/concession de terres agricoles

        return mapper;- **Validation**: Signature AFOR + CVGFR requis

    }

}### AFOR_CERTIFICATE  

```- **Participants**: AFOR, CVGFR, PREFET (toutes les organisations)

- **Usage**: Certificats fonciers officiels

**Caractéristiques**:- **Validation**: AFOR obligatoire + une autre organisation (CVGFR ou PREFET)

- ✅ Format ISO 8601 strict

- ✅ Ordre alphabétique des clés JSON### ADMIN

- ✅ Pas de variation entre JVMs- **Participants**: AFOR, CVGFR, PREFET

- ✅ Timestamps et UUID fournis en entrée- **Usage**: Administration, supervision, métriques

- **Validation**: Consensus majoritaire

**Résultat**: ✅ **Aucune erreur de consensus** - Le chaincode fonctionne parfaitement!

## 🚨 Dépannage

---

### Problèmes Courants

## 📊 Modèle de Données

**Conteneurs qui ne démarrent pas**

### ContratFoncier```bash

# Vérifier les logs

```javadocker logs <container_name>

public class ContratFoncier {

    private String id;# Nettoyer et redémarrer

    private String uuid;                    // Obligatoire (fourni en entrée)./scripts/network-new.sh down

    private String codeContract;docker system prune -f

    private LocalDateTime creationDate;     // Obligatoire (fourni en entrée)./scripts/network-new.sh up

    private TypeContrat type;```

    private String region;

    private String department;**API non accessible**

    private String sousPrefecture;```bash

    private String village;# Vérifier le statut

    curl http://localhost:8080/actuator/health

    private Personne owner;                 // Propriétaire

    private Personne beneficiary;           // Bénéficiaire# Vérifier les logs

    private Terrain terrain;                // Terraindocker logs foncier-api

    ```

    private String duration;

    private String durationUnit;**Problèmes de build Java**

    private String rent;```bash

    // ... autres champs# Nettoyer et reconstruire

}cd chaincode-java && mvn clean install

```cd ../api-java && mvn clean install

```

### Validation Jakarta

## 📚 Documentation Complémentaire

```java

@NotNull(message = "UUID is required")- [Guide de Déploiement](DEPLOYMENT.md)

@NotEmpty(message = "UUID cannot be empty")- [Documentation API](API.md) 

private String uuid;- [Architecture Détaillée](docs/ARCHITECTURE.md)

- [Guide de Contribution](docs/CONTRIBUTING.md)

@NotNull(message = "Creation date is required")

private LocalDateTime creationDate;## 📞 Support

```

Pour obtenir de l'aide :

---- 📧 Email: support@afor.gov.ci

- 📱 GitHub Issues: [Créer un ticket](https://github.com/repo/issues)

## 🔗 API REST- 📖 Wiki: [Documentation complète](https://github.com/repo/wiki)



L'API Node.js expose les fonctionnalités du chaincode via REST:---



```bash**Système de Gestion Foncière - République de Côte d'Ivoire**  

# Démarrer l'API*Développé par AFOR avec la technologie Hyperledger Fabric*
cd api
npm install
npm start
```

### Endpoints Principaux

```
POST   /api/contracts              # Créer un contrat
GET    /api/contracts/:id          # Lire un contrat
PUT    /api/contracts/:id          # Modifier un contrat
DELETE /api/contracts/:id          # Supprimer un contrat
GET    /api/contracts/search/terrain/:id   # Rechercher par terrain
GET    /api/contracts/search/owner/:id     # Rechercher par propriétaire
GET    /api/health                 # Health check
```

Voir [docs/API.md](docs/API.md) pour la spécification complète.

---

## 📚 Documentation

- **[SUCCESS_REPORT.md](SUCCESS_REPORT.md)** - Rapport de déploiement réussi
- **[docs/API.md](docs/API.md)** - Spécification API REST
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Guide de déploiement détaillé

---

## 🤝 Organisations Participantes

### AFOR - Agence Foncière Rurale
- Gestion principale des contrats fonciers
- Validation des certificats fonciers
- Coordination avec les CVGFR

### CVGFR - Comité Villageois de Gestion Foncière Rurale
- Validation locale des contrats agraires
- Enregistrement des transactions villageoises
- Gestion des conflits fonciers

### PREFET - Préfecture
- Autorité administrative
- Certification officielle
- Supervision réglementaire

---

## � Documentation Complète

### 🎯 Pour Commencer

1. **[GUIDE-DEPLOIEMENT-PRODUCTION.md](GUIDE-DEPLOIEMENT-PRODUCTION.md)** ⭐
   - Guide complet étape par étape
   - Tests locaux → Infrastructure → Multi-VM → Production
   - 7 phases détaillées avec toutes les commandes

2. **[CHECKLIST-DEPLOIEMENT.md](CHECKLIST-DEPLOIEMENT.md)** ✅
   - Plus de 150 points de vérification
   - Critères de mise en production
   - Procédures d'incident

3. **[RESUME-EXECUTIF.md](RESUME-EXECUTIF.md)** 📊
   - Évaluation du projet
   - Plan d'action sur 4 semaines
   - Points forts et à améliorer

### �️ Scripts Disponibles

| Script | Description | Usage |
|--------|-------------|-------|
| `test-local-complet.sh` | Test automatique complet | `./scripts/test-local-complet.sh` |
| `deploy-multi-vm.sh` | Déploiement sur VMs | `./scripts/deploy-multi-vm.sh deploy` |
| `maintenance.sh` | Backups, monitoring, stats | `./scripts/maintenance.sh menu` |
| `deploy-full.sh` | Déploiement chaincode | Utilisé par `make deploy-full` |

### 📁 Configuration Multi-VM

Voir **[deployment/README.md](deployment/README.md)** pour :
- Configuration Docker Compose par VM
- Instructions de déploiement distribué
- Dépannage réseau multi-machines

---

## 🚀 Roadmap

### ✅ Complété
- [x] Architecture Fabric 3.1.1 moderne
- [x] Chaincode Java avec sérialisation déterministe
- [x] API REST Node.js complète
- [x] Scripts d'automatisation
- [x] Configuration Docker Compose (local + production)
- [x] Infrastructure as Code (Terraform)
- [x] Documentation complète
- [x] Scripts de déploiement multi-VM

### 🔄 En Cours / À Faire
- [ ] Playbooks Ansible complets
- [ ] Tests unitaires chaincode (70% → 100%)
- [ ] Tests d'intégration API
- [ ] Monitoring Prometheus/Grafana
- [ ] CI/CD Pipeline GitHub Actions
- [ ] Tests de performance (load testing)
- [ ] Authentification JWT complète
- [ ] Logs centralisés (ELK Stack)

---

## 📞 Support

### En cas de problème

**Niveau 1 - Documentation**
1. Consultez [GUIDE-DEPLOIEMENT-PRODUCTION.md](GUIDE-DEPLOIEMENT-PRODUCTION.md)
2. Vérifiez [CHECKLIST-DEPLOIEMENT.md](CHECKLIST-DEPLOIEMENT.md)
3. Lisez [deployment/README.md](deployment/README.md) pour multi-VM

**Niveau 2 - Logs et Diagnostics**
```bash
# Logs des conteneurs
make logs

# Health checks
./scripts/maintenance.sh health

# Statistiques réseau
./scripts/maintenance.sh stats
```

**Niveau 3 - Scripts de Debug**
```bash
# Tester localement
./scripts/test-local-complet.sh

# Vérifier CouchDB
make test-couchdb

# Redémarrer un service
docker-compose restart peer0.afor.foncier.ci
```

**Niveau 4 - Communauté**
- GitHub Issues de ce projet
- [Hyperledger Fabric Discord](https://discord.gg/hyperledger)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/hyperledger-fabric)

---

## 📝 License

Apache License 2.0

---

## 🎯 Statut du Projet

**Status Actuel**: ✅ **PRÊT POUR TESTS LOCAUX** | ⚠️ **À COMPLÉTER POUR PRODUCTION**

| Composant | Statut | Notes |
|-----------|--------|-------|
| Chaincode Java | ✅ Prêt | Déterministe, validé |
| API REST | ✅ Prêt | À sécuriser (JWT) |
| Tests Locaux | ✅ Prêt | Script automatique |
| Docker Compose Local | ✅ Prêt | Testé et validé |
| Scripts Déploiement | ✅ Prêt | Multi-VM automatisé |
| Infrastructure Terraform | ✅ Prêt | AWS ready |
| Monitoring | ⚠️ Partiel | Structure présente |
| CI/CD | ❌ À faire | GitHub Actions |
| Tests E2E | ⚠️ Partiel | À compléter |

**Dernière mise à jour**: 30 Octobre 2025  
**Version**: 1.0  
**Équipe**: AFOR - Agence Foncière Rurale de Côte d'Ivoire
