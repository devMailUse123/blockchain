/**
 * Middleware d'authentification Keycloak
 * Vérifie le token JWT fourni par Keycloak
 */

const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

/**
 * Middleware pour vérifier le token JWT Keycloak
 * Le token doit être fourni dans l'en-tête Authorization: Bearer <token>
 */
const verifyKeycloakToken = async (req, res, next) => {
  try {
    // Récupérer le token depuis l'en-tête Authorization
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Token d\'authentification manquant',
        message: 'Veuillez fournir un token JWT valide dans l\'en-tête Authorization: Bearer <token>'
      });
    }

    const token = authHeader.substring(7); // Enlever "Bearer "

    // Décoder le token sans vérification pour obtenir les informations
    const decoded = jwt.decode(token, { complete: true });

    if (!decoded) {
      return res.status(401).json({
        success: false,
        error: 'Token invalide',
        message: 'Le token JWT ne peut pas être décodé'
      });
    }

    // Vérifier l'expiration
    const now = Math.floor(Date.now() / 1000);
    if (decoded.payload.exp && decoded.payload.exp < now) {
      return res.status(401).json({
        success: false,
        error: 'Token expiré',
        message: 'Le token JWT a expiré. Veuillez vous reconnecter.'
      });
    }

    // Ajouter les informations utilisateur à la requête
    req.user = {
      id: decoded.payload.sub,
      username: decoded.payload.preferred_username || decoded.payload.email,
      email: decoded.payload.email,
      roles: decoded.payload.realm_access?.roles || [],
      organization: decoded.payload.organization || 'AFOR', // Custom claim
      name: decoded.payload.name,
      token: token
    };

    logger.info(`Utilisateur authentifié: ${req.user.username} (${req.user.organization})`);
    next();

  } catch (error) {
    logger.error('Erreur lors de la vérification du token:', error);
    return res.status(401).json({
      success: false,
      error: 'Erreur d\'authentification',
      message: error.message
    });
  }
};

/**
 * Middleware pour vérifier les rôles requis
 * @param {Array<string>} requiredRoles - Liste des rôles requis
 */
const requireRoles = (requiredRoles = []) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Non authentifié',
        message: 'Vous devez être authentifié pour accéder à cette ressource'
      });
    }

    const userRoles = req.user.roles || [];
    const hasRole = requiredRoles.some(role => userRoles.includes(role));

    if (!hasRole) {
      logger.warn(`Accès refusé pour ${req.user.username}: rôles requis ${requiredRoles.join(', ')}`);
      return res.status(403).json({
        success: false,
        error: 'Accès refusé',
        message: `Vous devez avoir l'un des rôles suivants: ${requiredRoles.join(', ')}`
      });
    }

    next();
  };
};

/**
 * Middleware pour vérifier l'organisation
 * @param {Array<string>} allowedOrgs - Liste des organisations autorisées
 */
const requireOrganization = (allowedOrgs = []) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Non authentifié'
      });
    }

    const userOrg = req.user.organization;
    const hasOrg = allowedOrgs.includes(userOrg);

    if (!hasOrg) {
      logger.warn(`Accès refusé pour ${req.user.username}: organisation ${userOrg} non autorisée`);
      return res.status(403).json({
        success: false,
        error: 'Accès refusé',
        message: `Votre organisation (${userOrg}) n'est pas autorisée à accéder à cette ressource`
      });
    }

    next();
  };
};

module.exports = {
  verifyKeycloakToken,
  requireRoles,
  requireOrganization
};
