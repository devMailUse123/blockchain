const logger = require('../utils/logger');

/**
 * Middleware de gestion des erreurs global
 */
const errorHandler = (err, req, res, next) => {
  // Logger l'erreur
  logger.error('Erreur:', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    body: req.body,
    params: req.params
  });

  // Erreurs de validation Joi
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Erreur de validation',
      errors: err.details
    });
  }

  // Erreurs Fabric
  if (err.message && err.message.includes('endorsement')) {
    return res.status(502).json({
      success: false,
      message: 'Erreur lors de la communication avec la blockchain',
      error: err.message
    });
  }

  // Erreur par défaut
  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || 'Erreur interne du serveur',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

module.exports = errorHandler;
