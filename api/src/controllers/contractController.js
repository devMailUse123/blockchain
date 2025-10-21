const fabricService = require('../services/fabricService');
const logger = require('../utils/logger');

/**
 * Contrôleur pour les contrats fonciers
 */
class ContractController {
  /**
   * Créer un nouveau contrat
   */
  async createContract(req, res) {
    try {
      const contractData = req.body;
      
      logger.info('Création d\'un nouveau contrat', { contractData });
      
      // Soumettre la transaction au chaincode
      const result = await fabricService.submitTransaction(
        'creerContrat',
        JSON.stringify(contractData)
      );
      
      const contract = JSON.parse(result);
      
      res.status(201).json({
        success: true,
        message: 'Contrat créé avec succès',
        data: contract
      });
    } catch (error) {
      logger.error('Erreur lors de la création du contrat:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la création du contrat',
        error: error.message
      });
    }
  }

  /**
   * Récupérer un contrat par son ID
   */
  async getContract(req, res) {
    try {
      const { id } = req.params;
      
      logger.info('Récupération du contrat', { id });
      
      // Évaluer la transaction (query)
      const result = await fabricService.evaluateTransaction('lireContrat', id);
      const contract = JSON.parse(result);
      
      res.json({
        success: true,
        data: contract
      });
    } catch (error) {
      logger.error('Erreur lors de la récupération du contrat:', error);
      
      if (error.message.includes('does not exist')) {
        return res.status(404).json({
          success: false,
          message: 'Contrat non trouvé',
          error: error.message
        });
      }
      
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération du contrat',
        error: error.message
      });
    }
  }

  /**
   * Mettre à jour un contrat
   */
  async updateContract(req, res) {
    try {
      const { id } = req.params;
      const contractData = req.body;
      
      logger.info('Mise à jour du contrat', { id, contractData });
      
      // Soumettre la transaction
      const result = await fabricService.submitTransaction(
        'modifierContrat',
        id,
        JSON.stringify(contractData)
      );
      
      const contract = JSON.parse(result);
      
      res.json({
        success: true,
        message: 'Contrat mis à jour avec succès',
        data: contract
      });
    } catch (error) {
      logger.error('Erreur lors de la mise à jour du contrat:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la mise à jour du contrat',
        error: error.message
      });
    }
  }

  /**
   * Supprimer un contrat
   */
  async deleteContract(req, res) {
    try {
      const { id } = req.params;
      
      logger.info('Suppression du contrat', { id });
      
      // Soumettre la transaction
      await fabricService.submitTransaction('supprimerContrat', id);
      
      res.json({
        success: true,
        message: 'Contrat supprimé avec succès'
      });
    } catch (error) {
      logger.error('Erreur lors de la suppression du contrat:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la suppression du contrat',
        error: error.message
      });
    }
  }

  /**
   * Récupérer tous les contrats
   */
  async getAllContracts(req, res) {
    try {
      logger.info('Récupération de tous les contrats');
      
      // Évaluer la transaction
      const result = await fabricService.evaluateTransaction('lireTousLesContrats');
      const contracts = JSON.parse(result);
      
      res.json({
        success: true,
        count: contracts.length,
        data: contracts
      });
    } catch (error) {
      logger.error('Erreur lors de la récupération des contrats:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération des contrats',
        error: error.message
      });
    }
  }

  /**
   * Rechercher des contrats
   */
  async searchContracts(req, res) {
    try {
      const { query } = req.params;
      
      logger.info('Recherche de contrats', { query });
      
      // Évaluer la transaction
      const result = await fabricService.evaluateTransaction('rechercherContrats', query);
      const contracts = JSON.parse(result);
      
      res.json({
        success: true,
        count: contracts.length,
        data: contracts
      });
    } catch (error) {
      logger.error('Erreur lors de la recherche de contrats:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la recherche de contrats',
        error: error.message
      });
    }
  }

  /**
   * Récupérer les contrats d'un propriétaire
   */
  async getContractsByOwner(req, res) {
    try {
      const { ownerId } = req.params;
      
      logger.info('Récupération des contrats du propriétaire', { ownerId });
      
      // Évaluer la transaction
      const result = await fabricService.evaluateTransaction('lireContratsParProprietaire', ownerId);
      const contracts = JSON.parse(result);
      
      res.json({
        success: true,
        count: contracts.length,
        data: contracts
      });
    } catch (error) {
      logger.error('Erreur lors de la récupération des contrats du propriétaire:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération des contrats du propriétaire',
        error: error.message
      });
    }
  }

  /**
   * Récupérer les contrats d'un bénéficiaire
   */
  async getContractsByBeneficiary(req, res) {
    try {
      const { beneficiaryId } = req.params;
      
      logger.info('Récupération des contrats du bénéficiaire', { beneficiaryId });
      
      // Évaluer la transaction
      const result = await fabricService.evaluateTransaction('lireContratsParBeneficiaire', beneficiaryId);
      const contracts = JSON.parse(result);
      
      res.json({
        success: true,
        count: contracts.length,
        data: contracts
      });
    } catch (error) {
      logger.error('Erreur lors de la récupération des contrats du bénéficiaire:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération des contrats du bénéficiaire',
        error: error.message
      });
    }
  }

  /**
   * Récupérer l'historique d'un contrat
   */
  async getContractHistory(req, res) {
    try {
      const { id } = req.params;
      
      logger.info('Récupération de l\'historique du contrat', { id });
      
      // Évaluer la transaction
      const result = await fabricService.evaluateTransaction('lireHistoriqueContrat', id);
      const history = JSON.parse(result);
      
      res.json({
        success: true,
        count: history.length,
        data: history
      });
    } catch (error) {
      logger.error('Erreur lors de la récupération de l\'historique:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération de l\'historique',
        error: error.message
      });
    }
  }
}

module.exports = new ContractController();
