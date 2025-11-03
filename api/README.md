# API REST - Blockchain AFOR

API REST pour communiquer avec le réseau Hyperledger Fabric de sécurisation foncière rurale en Côte d'Ivoire.

## 🚀 Démarrage Rapide

### Installation

```bash
cd api
npm install
```

### Configuration

Copier le fichier `.env.example` vers `.env` et ajuster les valeurs :

```bash
cp .env.example .env
```

### Démarrage

```bash
# Mode développement (avec nodemon)
npm run dev

# Mode production
npm start
```

L'API sera accessible sur : `http://localhost:3000`

## 📚 Documentation Interactive (Swagger)

Une fois l'API démarrée, accédez à la **documentation Swagger UI** :

```
http://localhost:3000/api-docs
```

**Fonctionnalités Swagger :**
- ✅ Tester tous les endpoints directement depuis le navigateur
- ✅ Voir les modèles de données complets (ContratAgraire avec 73+ propriétés)
- ✅ Consulter les exemples de requêtes/réponses
- ✅ Télécharger la spécification OpenAPI 3.0.0 JSON
- ✅ Importer dans Postman ou générer des clients SDK

👉 **Voir le guide complet** : [SWAGGER.md](./SWAGGER.md)

## 📚 Endpoints

### Health Check

#### GET /api/health
Vérifier l'état de santé de l'API

**Réponse:**
```json
{
  "status": "UP",
  "timestamp": "2025-10-21T00:00:00.000Z",
  "uptime": 123.45,
  "environment": "development",
  "version": "1.0.0",
  "services": {
    "api": "UP",
    "blockchain": "Connected"
  }
}
```

#### GET /api/health/blockchain
Vérifier la connexion à la blockchain

**Réponse:**
```json
{
  "status": "Connected",
  "channel": "contrat-agraire",
  "chaincode": "foncier",
  "version": "4.0",
  "timestamp": "2025-10-21T00:00:00.000Z"
}
```

---

### Contrats

#### POST /api/contracts
Créer un nouveau contrat foncier

**Body:**
```json
{
  "codeContract": "CA-2024-001",
  "type": "VENTE",
  "ownerId": "USER001",
  "beneficiaryId": "USER002",
  "terrainId": "TERRAIN001",
  "village": "Abobo",
  "department": "Abidjan",
  "duration": 99,
  "durationUnit": "ANNEE",
  "rent": 0,
  "usagesAutorises": ["HABITATION", "AGRICULTURE"]
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Contrat créé avec succès",
  "data": {
    "id": "CONTRACT123",
    "codeContract": "CA-2024-001",
    "type": "VENTE",
    "creationDate": "2025-10-21T00:00:00.000Z",
    ...
  }
}
```

#### GET /api/contracts/:id
Récupérer un contrat par son ID

**Réponse:**
```json
{
  "success": true,
  "data": {
    "id": "CONTRACT123",
    "codeContract": "CA-2024-001",
    "type": "VENTE",
    "owner": { ... },
    "beneficiary": { ... },
    "terrain": { ... },
    ...
  }
}
```

#### PUT /api/contracts/:id
Mettre à jour un contrat

**Body:** Mêmes champs que la création

**Réponse:**
```json
{
  "success": true,
  "message": "Contrat mis à jour avec succès",
  "data": { ... }
}
```

#### DELETE /api/contracts/:id
Supprimer un contrat

**Réponse:**
```json
{
  "success": true,
  "message": "Contrat supprimé avec succès"
}
```

#### GET /api/contracts
Récupérer tous les contrats

**Réponse:**
```json
{
  "success": true,
  "count": 10,
  "data": [
    { ... },
    { ... }
  ]
}
```

#### GET /api/contracts/search/:query
Rechercher des contrats

**Exemple:** `/api/contracts/search/Abobo`

**Réponse:**
```json
{
  "success": true,
  "count": 5,
  "data": [
    { ... }
  ]
}
```

#### GET /api/contracts/owner/:ownerId
Récupérer les contrats d'un propriétaire

**Exemple:** `/api/contracts/owner/USER001`

**Réponse:**
```json
{
  "success": true,
  "count": 3,
  "data": [
    { ... }
  ]
}
```

#### GET /api/contracts/beneficiary/:beneficiaryId
Récupérer les contrats d'un bénéficiaire

**Exemple:** `/api/contracts/beneficiary/USER002`

#### GET /api/contracts/history/:id
Récupérer l'historique d'un contrat

**Réponse:**
```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "txId": "abc123",
      "timestamp": "2025-10-21T00:00:00.000Z",
      "isDelete": false,
      "value": { ... }
    }
  ]
}
```

---

### Utilisateurs

#### POST /api/users
Créer un nouvel utilisateur

**Body:**
```json
{
  "userId": "USER001",
  "nom": "Kouassi",
  "prenoms": "Jean",
  "dateNaissance": "1980-01-01",
  "lieuNaissance": "Abidjan",
  "typeIdentite": "CNI",
  "numeroIdentite": "CI123456",
  "contact": "+225 01 02 03 04 05"
}
```

#### GET /api/users/:id
Récupérer un utilisateur par son ID

#### GET /api/users
Récupérer tous les utilisateurs

---

## 📊 Modèle de Données

### ContratAgraire

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| codeContract | string | Oui | Code unique du contrat |
| type | enum | Oui | VENTE, LOCATION, PRET, DON, HERITAGE |
| ownerId | string | Oui | ID du propriétaire |
| beneficiaryId | string | Oui | ID du bénéficiaire |
| terrainId | string | Oui | ID du terrain |
| village | string | Oui | Village |
| department | string | Non | Département |
| duration | number | Non | Durée du contrat |
| durationUnit | enum | Non | JOUR, MOIS, ANNEE, ILLIMITE |
| rent | number | Non | Montant du loyer |
| usagesAutorises | array | Non | Liste des usages autorisés |

*Voir le fichier `src/middleware/validation.js` pour la liste complète des champs*

---

## 🔒 Sécurité

### Rate Limiting
- **Fenêtre:** 15 minutes
- **Maximum:** 100 requêtes par IP

### Headers de sécurité
L'API utilise Helmet pour ajouter les headers de sécurité HTTP.

---

## 🐛 Gestion des Erreurs

### Format de réponse d'erreur

```json
{
  "success": false,
  "message": "Description de l'erreur",
  "error": "Détails techniques"
}
```

### Codes HTTP

| Code | Description |
|------|-------------|
| 200 | Succès |
| 201 | Ressource créée |
| 400 | Requête invalide |
| 404 | Ressource non trouvée |
| 500 | Erreur serveur |
| 502 | Erreur blockchain |
| 503 | Service indisponible |

---

## 📝 Logs

Les logs sont stockés dans le dossier `logs/` :
- `all.log` - Tous les logs
- `error.log` - Logs d'erreurs uniquement

---

## 🧪 Tests

```bash
# Lancer les tests
npm test

# Tests avec couverture
npm run test:coverage
```

---

## 🔧 Architecture

```
api/
├── src/
│   ├── config/          # Configuration Fabric
│   ├── controllers/     # Contrôleurs REST
│   ├── middleware/      # Middlewares (validation, erreurs)
│   ├── routes/          # Définition des routes
│   ├── services/        # Services Fabric
│   ├── utils/           # Utilitaires (logger)
│   └── server.js        # Point d'entrée
├── logs/                # Fichiers de logs
├── .env                 # Variables d'environnement
└── package.json
```

---

## 🤝 Support

Pour toute question ou problème :
- Documentation Fabric : https://hyperledger-fabric.readthedocs.io/
- Issues GitHub : [Votre repo]

---

## 📄 Licence

Apache-2.0
