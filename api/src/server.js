const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
const session = require('express-session');
require('dotenv').config();
require('express-async-errors');

const logger = require('./utils/logger');
const errorHandler = require('./middleware/errorHandler');
const { verifyKeycloakToken } = require('./middleware/auth');
const swaggerSpec = require('./config/swagger');
const contractRoutes = require('./routes/contractRoutes');
const healthRoutes = require('./routes/healthRoutes');
const userRoutes = require('./routes/userRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware de sécurité
app.use(helmet({
  contentSecurityPolicy: false, // Désactiver CSP pour permettre Swagger UI
}));
app.use(cors());

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: 'Trop de requêtes depuis cette IP, veuillez réessayer plus tard.'
});
app.use('/api/', limiter);

// Parsing du body
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging HTTP
app.use(morgan('combined', { stream: logger.stream }));

// Swagger UI - Documentation avec support Bearer Token
const swaggerUiOptions = {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'API Blockchain AFOR - Documentation',
  swaggerOptions: {
    persistAuthorization: true,
  }
};

app.use('/api-docs', swaggerUi.serveFiles(swaggerSpec, swaggerUiOptions));
app.get('/api-docs', swaggerUi.setup(swaggerSpec, swaggerUiOptions));

// Swagger JSON
app.get('/api-docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

// Routes publiques (pas besoin d'authentification)
app.use('/api/health', healthRoutes);

// Routes protégées (nécessitent un token Keycloak)
app.use('/api/contracts', verifyKeycloakToken, contractRoutes);
app.use('/api/users', verifyKeycloakToken, userRoutes);

// Route racine
app.get('/', (req, res) => {
  res.json({
    message: 'API Blockchain AFOR - Sécurisation Foncière Rurale',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      health: '/api/health',
      contracts: '/api/contracts',
      users: '/api/users',
      documentation: '/api-docs',
      openapi: '/api-docs.json'
    }
  });
});

// Middleware de gestion des erreurs
app.use(errorHandler);

// Démarrage du serveur
app.listen(PORT, () => {
  logger.info(`🚀 Serveur API démarré sur le port ${PORT}`);
  logger.info(`📊 Environnement: ${process.env.NODE_ENV}`);
  logger.info(`🔗 Canal: ${process.env.CHANNEL_NAME}`);
  logger.info(`📦 Chaincode: ${process.env.CHAINCODE_NAME} v${process.env.CHAINCODE_VERSION}`);
});

// Gestion des erreurs non catchées
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Rejection:', err);
  process.exit(1);
});

module.exports = app;
