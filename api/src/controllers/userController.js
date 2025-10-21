const fabricService = require('../services/fabricService');
const logger = require('../utils/logger');

/**
 * Contrôleur pour les utilisateurs
 */
class UserController {
  /**
   * Créer un nouvel utilisateur
   */
  async createUser(req, res) {
    try {
      const userData = req.body;
      
      logger.info('Création d\'un nouvel utilisateur', { userData });
      
      // Soumettre la transaction au chaincode
      const result = await fabricService.submitTransaction(
        'creerUtilisateur',
        JSON.stringify(userData)
      );
      
      const user = JSON.parse(result);
      
      res.status(201).json({
        success: true,
        message: 'Utilisateur créé avec succès',
        data: user
      });
    } catch (error) {
      logger.error('Erreur lors de la création de l\'utilisateur:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la création de l\'utilisateur',
        error: error.message
      });
    }
  }

  /**
   * Récupérer un utilisateur par son ID
   */
  async getUser(req, res) {
    try {
      const { id } = req.params;
      
      logger.info('Récupération de l\'utilisateur', { id });
      
      // Évaluer la transaction (query)
      const result = await fabricService.evaluateTransaction('lireUtilisateur', id);
      const user = JSON.parse(result);
      
      res.json({
        success: true,
        data: user
      });
    } catch (error) {
      logger.error('Erreur lors de la récupération de l\'utilisateur:', error);
      
      if (error.message.includes('does not exist')) {
        return res.status(404).json({
          success: false,
          message: 'Utilisateur non trouvé',
          error: error.message
        });
      }
      
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération de l\'utilisateur',
        error: error.message
      });
    }
  }

  /**
   * Récupérer tous les utilisateurs
   */
  async getAllUsers(req, res) {
    try {
      logger.info('Récupération de tous les utilisateurs');
      
      // Évaluer la transaction
      const result = await fabricService.evaluateTransaction('lireTousLesUtilisateurs');
      const users = JSON.parse(result);
      
      res.json({
        success: true,
        count: users.length,
        data: users
      });
    } catch (error) {
      logger.error('Erreur lors de la récupération des utilisateurs:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération des utilisateurs',
        error: error.message
      });
    }
  }
}

module.exports = new UserController();
