# API REST - Système Foncier Côte d'Ivoire

## Architecture API Spring Boot 3.2.0

### Vue d'ensemble

Cette API REST moderne remplace l'ancienne API Node.js et fournit une interface complète pour interagir avec le réseau Hyperledger Fabric 3.1.1.

## 🏗️ Architecture des Canaux

### Canaux Spécialisés

1. **afor-contrat-agraire**
   - **Participants** : AFOR + CVGFR
   - **Usage** : Contrats agraires entre propriétaires et exploitants
   - **Endorsement** : Signature des deux organisations requise

2. **afor-certificate**
   - **Participants** : AFOR + CVGFR + PREFET (toutes les organisations)
   - **Usage** : Certificats fonciers officiels
   - **Endorsement** : AFOR obligatoire + une autre organisation (CVGFR ou PREFET)

3. **admin**
   - **Participants** : AFOR + CVGFR + PREFET (toutes les organisations)
   - **Usage** : Administration et supervision technique du réseau
   - **Endorsement** : Consensus majoritaire

### Rôle des Organisations

- **AFOR** : Organisation principale - Agence Foncière Rurale de Côte d'Ivoire
- **CVGFR** : Comité Villageois de Gestion Foncière Rurale (validation locale)
- **PREFET** : Autorité administrative préfectorale (validation officielle)

## 🚀 Démarrage Rapide

### Prérequis
- Java 11+
- Maven 3.6+
- Réseau Fabric démarré
- Port 8080 disponible

### Démarrage Local

```bash
# Construction et démarrage
cd api-java
mvn clean package -DskipTests
java -jar target/foncier-api-1.0.0.jar

# Ou via Maven
mvn spring-boot:run
```

### Accès Swagger UI
- **URL** : http://localhost:8080/swagger-ui.html
- **Documentation OpenAPI** : http://localhost:8080/api-docs

## 🔐 Authentification

### JWT Token

L'API utilise l'authentification JWT pour sécuriser les endpoints.

```bash
# Obtenir un token (exemple de développement)
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Réponse
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600,
  "organization": "AFOR"
}
```

### Utilisation du Token

```bash
# Inclure le token dans les requêtes
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     http://localhost:8080/api/contrats
```

## 📊 Endpoints Disponibles

### 1. Authentification

#### POST /auth/login
Authentification et génération de token JWT.

**Request Body:**
```json
{
  "username": "admin",
  "password": "admin123",
  "organization": "AFOR"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600,
  "user": {
    "username": "admin",
    "organization": "AFOR",
    "roles": ["ADMIN"]
  }
}
```

### 2. Santé et Monitoring

#### GET /actuator/health
Vérification de l'état de l'API et de ses dépendances.

**Response:**
```json
{
  "status": "UP",
  "components": {
    "fabric": {
      "status": "UP",
      "details": {
        "network": "foncier",
        "channels": ["afor-contrat-agraire", "afor-certificate", "admin"],
        "peers": ["peer0.afor.foncier.ci", "peer0.cvgfr.foncier.ci", "peer0.prefet.foncier.ci"]
      }
    }
  }
}
```

#### GET /actuator/metrics
Métriques Prometheus pour monitoring.

### 3. Gestion des Contrats

#### GET /api/contrats
Liste tous les contrats accessibles selon l'organisation.

**Query Parameters:**
- `channel` : Canal à consulter (afor-contrat-agraire, afor-certificate)
- `type` : Type de contrat (AGRAIRE, CERTIFICATE)
- `statut` : Statut (ACTIF, SUSPENDU, EXPIRE)
- `page` : Numéro de page (défaut: 0)
- `size` : Taille de page (défaut: 10)

**Response:**
```json
{
  "content": [
    {
      "id": "CONT-2025-001",
      "type": "AGRAIRE",
      "proprietaire": {
        "nom": "KOUASSI",
        "prenom": "Yves",
        "telephone": "+225623456789"
      },
      "parcelle": {
        "superficie": 2.5,
        "localisation": "Bouaké, Yamoussoukro",
        "coordonnees": {
          "latitude": 10.0570,
          "longitude": -12.3456
        }
      },
      "statut": "ACTIF",
      "dateCreation": "2025-10-18T10:30:00Z",
      "dureeContrat": 60
    }
  ],
  "totalElements": 1,
  "totalPages": 1,
  "number": 0,
  "size": 10
}
```

#### POST /api/contrats
Création d'un nouveau contrat.

**Request Body:**
```json
{
  "type": "AGRAIRE",
  "proprietaire": {
    "nom": "KOUASSI",
    "prenom": "Yves",
    "telephone": "+225623456789",
    "adresse": "Abidjan, Côte d'Ivoire"
  },
  "exploitant": {
    "nom": "BAH",
    "prenom": "Koffi",
    "telephone": "+225654321098"
  },
  "parcelle": {
    "superficie": 2.5,
    "localisation": "Bouaké, Yamoussoukro",
    "coordonnees": {
      "latitude": 10.0570,
      "longitude": -12.3456
    }
  },
  "conditionsContrat": {
    "dureeContrat": 60,
    "montantLocation": 500000.0,
    "modalitePaiement": "ANNUEL"
  }
}
```

**Response:**
```json
{
  "id": "CONT-2025-002",
  "status": "CREATED",
  "message": "Contrat créé avec succès",
  "transactionId": "tx_abc123def456",
  "timestamp": "2025-10-18T10:35:00Z"
}
```

#### GET /api/contrats/{id}
Récupération d'un contrat par son ID.

**Path Parameters:**
- `id` : Identifiant unique du contrat

**Response:** Structure identique à la liste des contrats

#### PUT /api/contrats/{id}
Mise à jour d'un contrat existant.

**Request Body:** Structure identique à la création

#### DELETE /api/contrats/{id}
Suppression logique d'un contrat.

**Response:**
```json
{
  "id": "CONT-2025-001",
  "status": "DELETED",
  "message": "Contrat supprimé avec succès",
  "timestamp": "2025-10-18T10:40:00Z"
}
```

### 4. Recherche Avancée

#### GET /api/contrats/recherche
Recherche multicritère dans les contrats.

**Query Parameters:**
- `proprietaire` : Nom du propriétaire
- `exploitant` : Nom de l'exploitant
- `localisation` : Localisation de la parcelle
- `superficieMin` : Superficie minimale
- `superficieMax` : Superficie maximale
- `dateDebut` : Date de début (yyyy-MM-dd)
- `dateFin` : Date de fin (yyyy-MM-dd)

**Example:**
```bash
GET /api/contrats/recherche?proprietaire=KOUASSI&superficieMin=1.0&superficieMax=5.0
```

#### POST /api/contrats/recherche-geographique
Recherche par zone géographique.

**Request Body:**
```json
{
  "zone": {
    "nordEst": {
      "latitude": 10.1000,
      "longitude": -12.3000
    },
    "sudOuest": {
      "latitude": 10.0000,
      "longitude": -12.4000
    }
  },
  "typeContrat": "AGRAIRE"
}
```

### 5. Statistiques et Rapports

#### GET /api/statistiques
Statistiques globales du système.

**Response:**
```json
{
  "totalContrats": 150,
  "contratsActifs": 120,
  "contratsSuspendus": 20,
  "contratsExpires": 10,
  "superficieTotale": 750.5,
  "repartitionParType": {
    "AGRAIRE": 120,
    "CERTIFICATE": 30
  },
  "repartitionParOrganisation": {
    "AFOR": 80,
    "CVGFR": 40,
    "PREFET": 30
  }
}
```

#### GET /api/rapports/mensuel
Rapport mensuel d'activité.

**Query Parameters:**
- `mois` : Mois (1-12)
- `annee` : Année (yyyy)

### 6. Administration (Canal ADMIN)

#### GET /api/admin/organisations
Liste des organisations du réseau.

**Response:**
```json
[
  {
    "name": "AFOR",
    "mspId": "AFOROrg",
    "peer": "peer0.afor.foncier.ci:7051",
    "status": "ACTIVE",
    "channels": ["afor-contrat-agraire", "afor-certificate", "admin"]
  },
  {
    "name": "CVGFR",
    "mspId": "CVGFROrg", 
    "peer": "peer0.cvgfr.foncier.ci:8051",
    "status": "ACTIVE",
    "channels": ["afor-contrat-agraire", "admin"]
  },
  {
    "name": "PREFET",
    "mspId": "PREFETOrg",
    "peer": "peer0.prefet.foncier.ci:9051", 
    "status": "ACTIVE",
    "channels": ["afor-certificate", "admin"]
  }
]
```

#### GET /api/admin/channels
État des canaux du réseau.

#### POST /api/admin/maintenance
Opérations de maintenance (réservé aux super-administrateurs).

## 🔧 Configuration

### Variables d'Environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `FABRIC_NETWORK_PATH` | Chemin vers les certificats réseau | `../network` |
| `FABRIC_WALLET_PATH` | Chemin vers le wallet des identités | `../network/wallet` |
| `JWT_SECRET` | Clé secrète pour JWT | `your-secret-key` |
| `JWT_EXPIRATION` | Durée de validité JWT (secondes) | `3600` |
| `SERVER_PORT` | Port d'écoute de l'API | `8080` |

### Profils Spring

```bash
# Développement
java -jar -Dspring.profiles.active=dev target/foncier-api-1.0.0.jar

# Production  
java -jar -Dspring.profiles.active=prod target/foncier-api-1.0.0.jar

# Test
java -jar -Dspring.profiles.active=test target/foncier-api-1.0.0.jar
```

## 🚨 Gestion des Erreurs

### Codes de Réponse HTTP

| Code | Signification | Exemple |
|------|---------------|---------|
| `200` | Succès | Opération réussie |
| `201` | Créé | Contrat créé avec succès |
| `400` | Requête invalide | Données manquantes ou incorrectes |
| `401` | Non autorisé | Token JWT invalide ou expiré |
| `403` | Interdit | Permissions insuffisantes |
| `404` | Non trouvé | Contrat inexistant |
| `409` | Conflit | Contrat déjà existant |
| `500` | Erreur serveur | Problème réseau Fabric |

### Format des Erreurs

```json
{
  "timestamp": "2025-10-18T10:45:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Le champ 'proprietaire.nom' est obligatoire",
  "path": "/api/contrats",
  "details": {
    "field": "proprietaire.nom",
    "rejectedValue": null,
    "code": "NotNull"
  }
}
```

## 📈 Monitoring et Logs

### Logs Structurés

L'API génère des logs structurés au format JSON pour faciliter l'analyse :

```json
{
  "timestamp": "2025-10-18T10:50:00.123Z",
  "level": "INFO",
  "logger": "gn.foncier.api.service.FabricService",
  "message": "Transaction soumise avec succès",
  "mdc": {
    "transactionId": "tx_xyz789abc",
    "channel": "afor-contrat-agraire", 
    "chaincode": "foncier-chaincode",
    "function": "creerContrat",
    "user": "admin@afor.foncier.ci"
  }
}
```

### Métriques Disponibles

- `fabric_transactions_total` : Nombre total de transactions
- `fabric_transactions_duration` : Durée des transactions
- `fabric_errors_total` : Nombre d'erreurs par type
- `http_requests_total` : Requêtes HTTP par endpoint
- `jvm_memory_used` : Utilisation mémoire JVM

## 🔒 Sécurité

### Authentification Multi-Organisation

Chaque organisation possède ses propres utilisateurs et permissions :

```yaml
# Configuration RBAC
organizations:
  AFOR:
    roles:
      - ADMIN: "*"
      - USER: "read,write"
    channels:
      - afor-contrat-agraire
      - afor-certificate
      - admin
      
  CVGFR:
    roles:
      - VALIDATOR: "validate,read"
    channels:
      - afor-contrat-agraire
      - admin
      
  PREFET:
    roles:
      - AUTHORITY: "validate,approve"
    channels:
      - afor-certificate
      - admin
```

### HTTPS et TLS

En production, configurer HTTPS :

```yaml
# application-prod.yml
server:
  port: 8443
  ssl:
    enabled: true
    key-store: classpath:keystore.p12
    key-store-password: ${SSL_KEYSTORE_PASSWORD}
    key-store-type: PKCS12
```

## 🧪 Tests et Validation

### Tests d'Intégration

```bash
# Exécuter les tests d'intégration
mvn test -Dtest=**/*IntegrationTest

# Tests avec couverture
mvn test jacoco:report
```

### Test Manuel via cURL

```bash
# 1. Authentification
TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123","organization":"AFOR"}' \
  | jq -r '.token')

# 2. Créer un contrat
curl -X POST http://localhost:8080/api/contrats \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "AGRAIRE",
    "proprietaire": {
      "nom": "TEST",
      "prenom": "User", 
      "telephone": "+225600000000"
    },
    "parcelle": {
      "superficie": 1.0,
      "localisation": "Test Location"
    }
  }'

# 3. Lister les contrats
curl -H "Authorization: Bearer $TOKEN" \
     "http://localhost:8080/api/contrats?page=0&size=10"
```

## 📚 Ressources Supplémentaires

- **Code source** : `/api-java/src/main/java/gn/foncier/api/`
- **Tests** : `/api-java/src/test/java/gn/foncier/api/`
- **Configuration** : `/api-java/src/main/resources/application.yml`
- **Documentation OpenAPI** : http://localhost:8080/api-docs
- **Interface Swagger** : http://localhost:8080/swagger-ui.html

---

**Note** : Cette API remplace complètement l'ancienne API Node.js et est optimisée pour Hyperledger Fabric 3.1.1 avec l'architecture 3 organisations (AFOR, CVGFR, PREFET).