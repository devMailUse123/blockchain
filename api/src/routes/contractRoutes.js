const express = require('express');
const router = express.Router();
const contractController = require('../controllers/contractController');
// const { validateContract } = require('../middleware/validation'); // Désactivé temporairement

/**
 * @swagger
 * /api/contracts:
 *   post:
 *     summary: Créer un nouveau contrat foncier
 *     tags: [Contrats]
 *     description: Enregistre un nouveau contrat agraire sur la blockchain
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ContratAgraire'
 *     responses:
 *       201:
 *         description: Contrat créé avec succès
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SuccessResponse'
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       500:
 *         $ref: '#/components/responses/BlockchainError'
 */
router.post('/', contractController.createContract);

/**
 * @swagger
 * /api/contracts/{id}:
 *   get:
 *     summary: Récupérer un contrat par son ID
 *     tags: [Contrats]
 *     description: Obtient les détails d'un contrat foncier depuis la blockchain
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Identifiant unique du contrat
 *     responses:
 *       200:
 *         description: Contrat trouvé
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/ContratAgraire'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       500:
 *         $ref: '#/components/responses/BlockchainError'
 */
router.get('/:id', contractController.getContract);

/**
 * @swagger
 * /api/contracts/{id}:
 *   put:
 *     summary: Mettre à jour un contrat
 *     tags: [Contrats]
 *     description: Modifie les données d'un contrat existant sur la blockchain
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Identifiant unique du contrat
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ContratAgraire'
 *     responses:
 *       200:
 *         description: Contrat mis à jour
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SuccessResponse'
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       500:
 *         $ref: '#/components/responses/BlockchainError'
 */
router.put('/:id', contractController.updateContract);

/**
 * @swagger
 * /api/contracts/{id}:
 *   delete:
 *     summary: Supprimer un contrat
 *     tags: [Contrats]
 *     description: Supprime définitivement un contrat de la blockchain
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Identifiant unique du contrat
 *     responses:
 *       200:
 *         description: Contrat supprimé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SuccessResponse'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       500:
 *         $ref: '#/components/responses/BlockchainError'
 */
router.delete('/:id', contractController.deleteContract);

/**
 * @swagger
 * /api/contracts:
 *   get:
 *     summary: Récupérer tous les contrats
 *     tags: [Contrats]
 *     description: Liste l'ensemble des contrats fonciers enregistrés
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 100
 *         description: Nombre maximum de résultats
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *         description: Nombre de résultats à ignorer
 *     responses:
 *       200:
 *         description: Liste des contrats
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/ContratAgraire'
 *                 count:
 *                   type: integer
 *       500:
 *         $ref: '#/components/responses/BlockchainError'
 */
router.get('/', contractController.getAllContracts);

/**
 * @swagger
 * /api/contracts/search/{query}:
 *   get:
 *     summary: Rechercher des contrats
 *     tags: [Contrats]
 *     description: Recherche de contrats par mots-clés (parcelles, localisation, etc.)
 *     parameters:
 *       - in: path
 *         name: query
 *         required: true
 *         schema:
 *           type: string
 *         description: Terme de recherche
 *     responses:
 *       200:
 *         description: Résultats de recherche
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/ContratAgraire'
 *       500:
 *         $ref: '#/components/responses/BlockchainError'
 */
router.get('/search/:query', contractController.searchContracts);

/**
 * @swagger
 * /api/contracts/owner/{ownerId}:
 *   get:
 *     summary: Récupérer les contrats d'un propriétaire
 *     tags: [Contrats]
 *     description: Liste tous les contrats appartenant à un propriétaire spécifique
 *     parameters:
 *       - in: path
 *         name: ownerId
 *         required: true
 *         schema:
 *           type: string
 *         description: Identifiant du propriétaire
 *     responses:
 *       200:
 *         description: Contrats du propriétaire
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/ContratAgraire'
 *       500:
 *         $ref: '#/components/responses/BlockchainError'
 */
router.get('/owner/:ownerId', contractController.getContractsByOwner);

/**
 * @swagger
 * /api/contracts/beneficiary/{beneficiaryId}:
 *   get:
 *     summary: Récupérer les contrats d'un bénéficiaire
 *     tags: [Contrats]
 *     description: Liste tous les contrats dont une personne est bénéficiaire
 *     parameters:
 *       - in: path
 *         name: beneficiaryId
 *         required: true
 *         schema:
 *           type: string
 *         description: Identifiant du bénéficiaire
 *     responses:
 *       200:
 *         description: Contrats du bénéficiaire
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/ContratAgraire'
 *       500:
 *         $ref: '#/components/responses/BlockchainError'
 */
router.get('/beneficiary/:beneficiaryId', contractController.getContractsByBeneficiary);

/**
 * @swagger
 * /api/contracts/history/{id}:
 *   get:
 *     summary: Récupérer l'historique d'un contrat
 *     tags: [Contrats]
 *     description: Obtient toutes les modifications historiques d'un contrat sur la blockchain
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Identifiant unique du contrat
 *     responses:
 *       200:
 *         description: Historique du contrat
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       txId:
 *                         type: string
 *                       timestamp:
 *                         type: string
 *                       isDelete:
 *                         type: boolean
 *                       value:
 *                         $ref: '#/components/schemas/ContratAgraire'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       500:
 *         $ref: '#/components/responses/BlockchainError'
 */
router.get('/history/:id', contractController.getContractHistory);

module.exports = router;
