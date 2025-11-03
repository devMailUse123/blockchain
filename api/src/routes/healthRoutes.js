const express = require('express');
const router = express.Router();

/**
 * @swagger
 * /api/health:
 *   get:
 *     summary: Vérifier l'état de santé de l'API
 *     tags: [Health]
 *     description: Retourne l'état général de l'API et des services associés
 *     responses:
 *       200:
 *         description: API en bonne santé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/HealthResponse'
 *             example:
 *               status: UP
 *               timestamp: "2025-10-21T00:00:00.000Z"
 *               uptime: 123.45
 *               environment: development
 *               version: "1.0.0"
 *               services:
 *                 api: UP
 *                 blockchain: Connected
 */
router.get('/', (req, res) => {
  res.json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
    version: '1.0.0',
    services: {
      api: 'UP',
      blockchain: 'Connected'
    }
  });
});

/**
 * @route   GET /api/health/blockchain
 * @desc    Vérifier la connexion à la blockchain
 * @access  Public
 */
router.get('/blockchain', async (req, res) => {
  try {
    const fabricService = require('../services/fabricService');
    await fabricService.getContract();
    
    res.json({
      status: 'Connected',
      channel: process.env.CHANNEL_NAME,
      chaincode: process.env.CHAINCODE_NAME,
      version: process.env.CHAINCODE_VERSION,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      status: 'Disconnected',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
