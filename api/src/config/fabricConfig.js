const path = require('path');

/**
 * Configuration pour les 3 organisations du réseau Fabric
 */
const organizations = {
  afor: {
    mspId: 'AFOROrg',
    name: 'afor',
    domain: 'afor.foncier.ci',
    peer: 'peer0.afor.foncier.ci',
    peerPort: 7051,
    caPort: 7054,
    description: 'Agence Foncière Rurale'
  },
  cvgfr: {
    mspId: 'CVGFROrg',
    name: 'cvgfr',
    domain: 'cvgfr.foncier.ci',
    peer: 'peer0.cvgfr.foncier.ci',
    peerPort: 8051,
    caPort: 8054,
    description: 'Comité Villageois de Gestion Foncière Rurale'
  },
  prefet: {
    mspId: 'PREFETOrg',
    name: 'prefet',
    domain: 'prefet.foncier.ci',
    peer: 'peer0.prefet.foncier.ci',
    peerPort: 9051,
    caPort: 9054,
    description: 'Préfecture'
  }
};

/**
 * Configuration du réseau Fabric
 */
const fabricConfig = {
  channelName: process.env.CHANNEL_NAME || 'contrat-agraire',
  chaincodeName: process.env.CHAINCODE_NAME || 'foncier',
  chaincodeVersion: process.env.CHAINCODE_VERSION || '4.0',
  
  // Chemin vers les certificats
  cryptoPath: process.env.CRYPTO_PATH || path.resolve(__dirname, '../../../network/organizations'),
  
  // Configuration de l'orderer
  orderer: {
    name: 'orderer.foncier.ci',
    url: 'grpcs://localhost:7050',
    tlsCert: path.join(
      process.env.CRYPTO_PATH || path.resolve(__dirname, '../../../network/organizations'),
      'ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/ca.crt'
    )
  },
  
  // Organisations
  organizations,
  
  /**
   * Obtenir la configuration d'une organisation
   */
  getOrgConfig: (orgName) => {
    const org = organizations[orgName.toLowerCase()];
    if (!org) {
      throw new Error(`Organisation inconnue: ${orgName}. Organisations disponibles: ${Object.keys(organizations).join(', ')}`);
    }
    
    const cryptoPath = process.env.CRYPTO_PATH || path.resolve(__dirname, '../../../network/organizations');
    
    return {
      ...org,
      peerUrl: `grpcs://localhost:${org.peerPort}`,
      caUrl: `https://localhost:${org.caPort}`,
      
      // Chemins vers les certificats
      paths: {
        peerTlsCert: path.join(cryptoPath, `peerOrganizations/${org.domain}/peers/${org.peer}/tls/ca.crt`),
        adminCert: path.join(cryptoPath, `peerOrganizations/${org.domain}/users/Admin@${org.domain}/msp/signcerts/Admin@${org.domain}-cert.pem`),
        adminKey: path.join(cryptoPath, `peerOrganizations/${org.domain}/users/Admin@${org.domain}/msp/keystore`),
        mspPath: path.join(cryptoPath, `peerOrganizations/${org.domain}/users/Admin@${org.domain}/msp`)
      }
    };
  }
};

module.exports = fabricConfig;
