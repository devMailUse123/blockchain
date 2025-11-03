# 📚 Documentation Swagger - API Blockchain AFOR

## 🎯 Accès à la Documentation Interactive

Une fois l'API démarrée, accédez à la documentation Swagger :

### Interface Swagger UI
```
http://localhost:3000/api-docs
```

### Spécification OpenAPI JSON
```
http://localhost:3000/api-docs.json
```

## 🚀 Démarrage de l'API avec Swagger

```bash
cd /home/absolue/my-blockchain/api
node src/server.js
```

Ou avec le Makefile :
```bash
make api-start
```

## 📖 Structure de la Documentation

### Tags Disponibles

1. **Health** - État de santé de l'API
2. **Contrats** - Gestion des contrats fonciers (9 endpoints)
3. **Utilisateurs** - Gestion des utilisateurs (3 endpoints)

### Endpoints Documentés

#### Health Check
- `GET /api/health` - Vérifier l'état de l'API

#### Contrats Fonciers
- `POST /api/contracts` - Créer un contrat
- `GET /api/contracts/{id}` - Récupérer un contrat
- `PUT /api/contracts/{id}` - Modifier un contrat
- `DELETE /api/contracts/{id}` - Supprimer un contrat
- `GET /api/contracts` - Lister tous les contrats
- `GET /api/contracts/search/{query}` - Rechercher des contrats
- `GET /api/contracts/owner/{ownerId}` - Contrats d'un propriétaire
- `GET /api/contracts/beneficiary/{beneficiaryId}` - Contrats d'un bénéficiaire
- `GET /api/contracts/history/{id}` - Historique d'un contrat

#### Utilisateurs
- `POST /api/users` - Créer un utilisateur
- `GET /api/users/{id}` - Récupérer un utilisateur
- `GET /api/users` - Lister tous les utilisateurs

## 📋 Modèles de Données

### ContratAgraire
Modèle complet avec 73+ propriétés :
- **Identification** : numeroContrat, dateContrat, typeContrat
- **Localisation** : region, prefecture, sousPrefecture, village, coordonneesGPS
- **Parties** : proprietaire, beneficiaire, representantsCVGFR, agentAFOR
- **Parcelle** : parcellesInfos (superficie, limites, occupation, culture)
- **Clauses** : duree, montantLoyer, modalitePaiement, conditionsResiliation
- **Validation** : validationCVGFR, validationAFOR, validationPrefet
- **Statut** : statut (ACTIF, SUSPENDU, RESILIE, EXPIRE, EN_ATTENTE)

### User
- userId : string
- nom : string
- prenoms : string
- dateNaissance : date
- lieuNaissance : string
- numeroIdentite : string
- telephone : string
- role : enum (PROPRIETAIRE, EXPLOITANT, ADMIN, CVGFR, AFOR, PREFET)

## 🔧 Fonctionnalités Swagger UI

### 1. Explorer les Endpoints
- Navigation par tags
- Descriptions détaillées
- Schémas de requêtes et réponses
- Exemples de données

### 2. Tester l'API (Try it out)
```
1. Cliquez sur un endpoint
2. Cliquez sur "Try it out"
3. Remplissez les paramètres
4. Cliquez sur "Execute"
5. Consultez la réponse
```

### 3. Schémas de Validation
- Types de données requis
- Formats attendus
- Valeurs enum
- Exemples complets

### 4. Codes de Réponse
- `200` - Succès
- `201` - Créé
- `400` - Requête invalide
- `404` - Non trouvé
- `500` - Erreur serveur/blockchain

## 📊 Configuration Swagger

### Fichier : `api/src/config/swagger.js`

```javascript
{
  openapi: '3.0.0',
  info: {
    title: 'API Blockchain AFOR - Sécurisation Foncière',
    version: '1.0.0',
    description: 'API REST Hyperledger Fabric 3.1.1...',
    contact: {
      name: 'AFOR - Côte d\'Ivoire',
      email: 'support@afor.ci'
    }
  },
  servers: [
    { url: 'http://localhost:3000', description: 'Développement' },
    { url: 'https://api.afor.ci', description: 'Production' }
  ]
}
```

## 🎨 Personnalisation

### CSS Personnalisé
```javascript
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'API Blockchain AFOR - Documentation'
}));
```

### Export de la Spécification
Téléchargez la spec OpenAPI pour :
- **Postman** : Importer directement
- **Insomnia** : Importer la spec
- **Code Generators** : Générer des clients SDK

## 📝 Annotations JSDoc

Les routes utilisent des annotations JSDoc pour générer la documentation :

```javascript
/**
 * @swagger
 * /api/contracts:
 *   post:
 *     summary: Créer un nouveau contrat foncier
 *     tags: [Contrats]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ContratAgraire'
 *     responses:
 *       201:
 *         description: Contrat créé avec succès
 */
```

## 🔐 Sécurité (Future)

La documentation mentionne que certains endpoints devraient être protégés en production :
- Authentification JWT à implémenter
- Gestion des rôles et permissions
- Rate limiting configuré

## 🌐 Déploiement

### Production
Configurez l'URL du serveur de production dans `swagger.js` :
```javascript
servers: [
  { url: 'https://api.afor.ci', description: 'Production' }
]
```

### HTTPS
Activez TLS pour sécuriser les communications :
```javascript
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem')
};

https.createServer(options, app).listen(443);
```

## 📦 Export Postman

Pour générer une collection Postman :
```bash
# Téléchargez la spec JSON
curl http://localhost:3000/api-docs.json > openapi.json

# Importez dans Postman : File > Import > openapi.json
```

## 🔍 Validation OpenAPI

Validez la spécification :
```bash
npm install -g @apidevtools/swagger-cli

swagger-cli validate http://localhost:3000/api-docs.json
```

## 💡 Astuces

1. **Recherche** : Utilisez Ctrl+F dans Swagger UI
2. **Filtrage** : Cliquez sur les tags pour filtrer
3. **Exemples** : Tous les modèles ont des exemples pré-remplis
4. **Authentification** : Bouton "Authorize" pour les tokens (à implémenter)
5. **Try it out** : Testez directement depuis le navigateur

## 📚 Ressources

- **OpenAPI Spec** : https://swagger.io/specification/
- **Swagger UI** : https://swagger.io/tools/swagger-ui/
- **JSDoc Swagger** : https://github.com/Surnet/swagger-jsdoc

---

**✅ Documentation Swagger complète et fonctionnelle !**
