#!/usr/bin/env node

/**
 * Script de test de connexion au réseau Fabric
 */

const fabricService = require('./src/services/fabricService');
const logger = require('./src/utils/logger');

async function testConnection() {
  try {
    logger.info('=== Test de connexion au réseau Fabric ===');
    
    // Test 1: Connexion au réseau
    logger.info('\n1. Test de connexion à AFOR...');
    const contract = await fabricService.connect('afor');
    logger.info('✅ Connexion réussie à AFOR');
    
    // Test 2: Query simple (listerContrats)
    logger.info('\n2. Test de requête listerContrats...');
    const result = await fabricService.evaluateTransaction('listerContrats');
    const contracts = JSON.parse(result);
    logger.info(`✅ Requête réussie: ${contracts.length} contrats trouvés`);
    
    // Test 3: Query avec paramètre
    logger.info('\n3. Test de requête lireContrat avec ID test...');
    try {
      const singleContract = await fabricService.evaluateTransaction('lireContrat', 'test-id-123');
      logger.info('✅ Query avec paramètre réussie');
    } catch (error) {
      if (error.message.includes('non trouvé') || error.message.includes('CONTRAT_NOT_FOUND')) {
        logger.info('✅ Query avec paramètre fonctionne (contrat non trouvé comme attendu)');
      } else {
        throw error;
      }
    }
    
    logger.info('\n=== ✅ TOUS LES TESTS RÉUSSIS ===\n');
    
    // Déconnexion
    await fabricService.disconnect();
    logger.info('Déconnecté du réseau');
    
    process.exit(0);
  } catch (error) {
    logger.error('\n❌ ERREUR LORS DES TESTS:', error);
    logger.error('Stack:', error.stack);
    process.exit(1);
  }
}

// Lancer le test
testConnection();
