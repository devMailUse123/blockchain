const session = require('express-session');
const Keycloak = require('keycloak-connect');

// Configuration Keycloak
const keycloakConfig = {
  realm: process.env.KEYCLOAK_REALM || 'afor-realm',
  'auth-server-url': process.env.KEYCLOAK_URL || 'http://localhost:8080/auth',
  'ssl-required': process.env.KEYCLOAK_SSL_REQUIRED || 'external',
  resource: process.env.KEYCLOAK_CLIENT_ID || 'afor-api',
  'public-client': false,
  'confidential-port': 0,
  credentials: {
    secret: process.env.KEYCLOAK_CLIENT_SECRET || 'your-client-secret'
  }
};

// Session store
const memoryStore = new session.MemoryStore();

const sessionConfig = {
  secret: process.env.SESSION_SECRET || 'afor-blockchain-secret-key-change-in-production',
  resave: false,
  saveUninitialized: true,
  store: memoryStore
};

// Initialiser Keycloak
const keycloak = new Keycloak({ store: memoryStore }, keycloakConfig);

module.exports = {
  keycloak,
  sessionConfig
};
