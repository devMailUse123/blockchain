const express = require('express');
const router = express.Router();
const contractController = require('../controllers/contractController');
const { validateContract } = require('../middleware/validation');

/**
 * @route   POST /api/contracts
 * @desc    Créer un nouveau contrat foncier
 * @access  Public (devrait être protégé en production)
 */
router.post('/', validateContract, contractController.createContract);

/**
 * @route   GET /api/contracts/:id
 * @desc    Récupérer un contrat par son ID
 * @access  Public
 */
router.get('/:id', contractController.getContract);

/**
 * @route   PUT /api/contracts/:id
 * @desc    Mettre à jour un contrat
 * @access  Public
 */
router.put('/:id', validateContract, contractController.updateContract);

/**
 * @route   DELETE /api/contracts/:id
 * @desc    Supprimer un contrat
 * @access  Public
 */
router.delete('/:id', contractController.deleteContract);

/**
 * @route   GET /api/contracts
 * @desc    Récupérer tous les contrats
 * @access  Public
 */
router.get('/', contractController.getAllContracts);

/**
 * @route   GET /api/contracts/search/:query
 * @desc    Rechercher des contrats
 * @access  Public
 */
router.get('/search/:query', contractController.searchContracts);

/**
 * @route   GET /api/contracts/owner/:ownerId
 * @desc    Récupérer les contrats d'un propriétaire
 * @access  Public
 */
router.get('/owner/:ownerId', contractController.getContractsByOwner);

/**
 * @route   GET /api/contracts/beneficiary/:beneficiaryId
 * @desc    Récupérer les contrats d'un bénéficiaire
 * @access  Public
 */
router.get('/beneficiary/:beneficiaryId', contractController.getContractsByBeneficiary);

/**
 * @route   GET /api/contracts/history/:id
 * @desc    Récupérer l'historique d'un contrat
 * @access  Public
 */
router.get('/history/:id', contractController.getContractHistory);

module.exports = router;
