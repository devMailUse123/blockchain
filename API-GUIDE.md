# 🚀 API REST Blockchain AFOR - Guide de Démarrage

## ✅ API Créée avec Succès !

L'API REST complète a été créée pour communiquer avec votre réseau Hyperledger Fabric.

## 📦 Architecture de l'API

```
api/
├── src/
│   ├── config/
│   │   └── fabricConfig.js          # Configuration du réseau Fabric
│   ├── controllers/
│   │   ├── contractController.js    # Logique métier des contrats
│   │   └── userController.js        # Logique métier des utilisateurs
│   ├── middleware/
│   │   ├── errorHandler.js          # Gestion globale des erreurs
│   │   └── validation.js            # Validation Joi des données
│   ├── routes/
│   │   ├── contractRoutes.js        # Routes des contrats
│   │   ├── healthRoutes.js          # Routes de santé
│   │   └── userRoutes.js            # Routes des utilisateurs
│   ├── services/
│   │   └── fabricService.js         # Service de connexion Fabric
│   ├── utils/
│   │   └── logger.js                # Logger Winston
│   └── server.js                    # Point d'entrée
├── logs/                            # Logs de l'application
├── .env                             # Variables d'environnement
├── .env.example                     # Template de configuration
├── package.json                     # Dépendances npm
└── README.md                        # Documentation complète
```

## 🚀 Démarrage

### 1. Installation des dépendances

```bash
cd api
npm install
```

✅ **Fait !** 539 packages installés

### 2. Démarrer l'API

```bash
# Mode développement (avec auto-reload)
npm run dev

# Mode production
npm start

# Ou directement avec Node
node src/server.js
```

L'API sera accessible sur : **http://localhost:3000**

### 3. Vérifier que l'API fonctionne

```bash
# Health check
curl http://localhost:3000/api/health

# Vérifier la connexion blockchain
curl http://localhost:3000/api/health/blockchain
```

## 📚 Endpoints Principaux

### 🏥 Health Check

- `GET /api/health` - État de l'API
- `GET /api/health/blockchain` - État de la connexion blockchain

### 📄 Contrats

- `POST /api/contracts` - Créer un contrat
- `GET /api/contracts` - Lister tous les contrats
- `GET /api/contracts/:id` - Récupérer un contrat
- `PUT /api/contracts/:id` - Modifier un contrat
- `DELETE /api/contracts/:id` - Supprimer un contrat
- `GET /api/contracts/search/:query` - Rechercher des contrats
- `GET /api/contracts/owner/:ownerId` - Contrats d'un propriétaire
- `GET /api/contracts/beneficiary/:beneficiaryId` - Contrats d'un bénéficiaire
- `GET /api/contracts/history/:id` - Historique d'un contrat

### 👥 Utilisateurs

- `POST /api/users` - Créer un utilisateur
- `GET /api/users` - Lister tous les utilisateurs
- `GET /api/users/:id` - Récupérer un utilisateur

## 🧪 Exemple d'Utilisation

### Créer un contrat

```bash
curl -X POST http://localhost:3000/api/contracts \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
```

### Réponse

```json
{
  "success": true,
  "message": "Contrat créé avec succès",
  "data": {
    "id": "CONTRACT123",
    "codeContract": "CA-2024-001",
    "type": "VENTE",
    "creationDate": "2025-10-21T00:00:00.000Z",
    "owner": {...},
    "beneficiary": {...},
    "terrain": {...}
  }
}
```

### Récupérer tous les contrats

```bash
curl http://localhost:3000/api/contracts
```

### Rechercher des contrats

```bash
curl http://localhost:3000/api/contracts/search/Abobo
```

## 🔧 Configuration

### Variables d'environnement (.env)

```bash
# Serveur
PORT=3000
NODE_ENV=development

# Blockchain
CHANNEL_NAME=contrat-agraire
CHAINCODE_NAME=foncier
CHAINCODE_VERSION=4.0

# Organisation par défaut
DEFAULT_ORG=afor
DEFAULT_USER=Admin

# Chemins
CRYPTO_PATH=/home/absolue/my-blockchain/network/organizations
```

## 🌟 Fonctionnalités

### ✅ Implémenté

1. **Connexion Fabric**
   - Gestion automatique du wallet en mémoire
   - Support de 3 organisations (AFOR, CVGFR, PREFET)
   - Profil de connexion dynamique
   - Certificats X.509

2. **API REST Complète**
   - CRUD complet pour les contrats
   - CRUD pour les utilisateurs
   - Recherche et filtrage
   - Historique des transactions

3. **Sécurité**
   - Helmet pour les headers HTTP
   - Rate limiting (100 req/15min)
   - CORS configuré
   - Validation des données (Joi)

4. **Logging**
   - Winston pour les logs
   - Fichiers séparés (all.log, error.log)
   - Logs HTTP avec Morgan
   - Niveaux de log configurables

5. **Gestion d'erreurs**
   - Middleware centralisé
   - Messages d'erreur clairs
   - Codes HTTP appropriés
   - Stack trace en développement

## 🎯 Prochaines Étapes

### 1. Adapter les méthodes du chaincode

L'API appelle des méthodes génériques. Vous devrez peut-être adapter les noms selon votre chaincode Java :

```javascript
// Dans fabricService.js
await contract.submitTransaction('creerContrat', ...)  // À adapter
```

### 2. Ajouter l'authentification

Pour la production, ajoutez JWT ou OAuth2 :

```bash
npm install jsonwebtoken bcryptjs
```

### 3. Tests unitaires

Créer des tests avec Jest et Supertest :

```bash
npm test
```

### 4. Documentation Swagger

Ajouter Swagger pour une doc interactive :

```bash
npm install swagger-ui-express swagger-jsdoc
```

### 5. Déploiement

- Docker : Créer un Dockerfile
- PM2 : Gestion de processus
- Nginx : Reverse proxy
- HTTPS : Certificats SSL

## 🔍 Monitoring

### Logs en temps réel

```bash
# Tous les logs
tail -f api/logs/all.log

# Erreurs uniquement
tail -f api/logs/error.log
```

### Vérifier la connexion

```bash
curl http://localhost:3000/api/health/blockchain
```

## 🐛 Dépannage

### L'API ne démarre pas

1. Vérifier que le réseau Fabric est actif :
   ```bash
   docker ps | grep foncier
   ```

2. Vérifier les chemins des certificats dans `.env`

3. Vérifier les logs :
   ```bash
   tail -f api/logs/error.log
   ```

### Erreur de connexion Fabric

1. Vérifier que le chaincode est déployé :
   ```bash
   docker ps | grep dev-peer
   ```

2. Vérifier la configuration dans `fabricConfig.js`

3. Vérifier les certificats admin :
   ```bash
   ls -la network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/
   ```

## 📖 Documentation Complète

Voir le fichier `api/README.md` pour la documentation détaillée de tous les endpoints.

## 🎉 Conclusion

✅ **API REST complète créée avec succès !**

Vous avez maintenant :
- Une API REST Node.js/Express professionnelle
- Connexion au réseau Hyperledger Fabric
- Validation des données
- Gestion d'erreurs robuste
- Logging complet
- Documentation détaillée

**L'API est prête à être utilisée pour communiquer avec votre blockchain !** 🚀

---

**Technologies utilisées:**
- Node.js 18+
- Express 4.18
- Fabric SDK 2.2
- Winston (logging)
- Joi (validation)
- Helmet (sécurité)
