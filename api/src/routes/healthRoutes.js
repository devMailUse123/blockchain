const express = require('express');
const router = express.Router();

/**
 * @route   GET /api/health
 * @desc    Vérifier l'état de santé de l'API
 * @access  Public
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
