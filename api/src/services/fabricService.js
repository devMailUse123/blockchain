const { Gateway, Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const fs = require('fs');
const path = require('path');
const logger = require('../utils/logger');
const fabricConfig = require('../config/fabricConfig');

/**
 * Service pour interagir avec le réseau Hyperledger Fabric
 */
class FabricService {
  constructor() {
    this.gateway = null;
    this.wallet = null;
    this.network = null;
    this.contract = null;
  }

  /**
   * Initialiser le wallet en mémoire
   */
  async initWallet() {
    if (this.wallet) return this.wallet;
    
    // Fabric Network 2.x utilise newInMemoryWallet sans parenthèses
    this.wallet = await Wallets.newInMemoryWallet();
    logger.info('Wallet en mémoire initialisé');
    return this.wallet;
  }

  /**
   * Enregistrer une identité dans le wallet
   */
  async enrollAdmin(orgName) {
    try {
      const wallet = await this.initWallet();
      const orgConfig = fabricConfig.getOrgConfig(orgName);
      const identityLabel = `${orgName}-admin`;

      // Vérifier si l'identité existe déjà
      const identity = await wallet.get(identityLabel);
      if (identity) {
        logger.info(`L'identité ${identityLabel} existe déjà dans le wallet`);
        return;
      }

      // Lire les certificats depuis le système de fichiers
      const certPath = orgConfig.paths.adminCert;
      const keyPath = orgConfig.paths.adminKey;

      // Lire le certificat
      const cert = fs.readFileSync(certPath).toString();

      // Lire la clé privée (premier fichier dans keystore)
      const keyFiles = fs.readdirSync(keyPath);
      if (keyFiles.length === 0) {
        throw new Error(`Aucune clé privée trouvée dans ${keyPath}`);
      }
      const keyFile = path.join(keyPath, keyFiles[0]);
      const key = fs.readFileSync(keyFile).toString();

      // Créer l'identité X509
      const x509Identity = {
        credentials: {
          certificate: cert,
          privateKey: key,
        },
        mspId: orgConfig.mspId,
        type: 'X.509',
      };

      // Ajouter au wallet
      await wallet.put(identityLabel, x509Identity);
      logger.info(`Identité ${identityLabel} enregistrée dans le wallet`);
    } catch (error) {
      logger.error(`Erreur lors de l'enregistrement de l'admin ${orgName}:`, error);
      throw error;
    }
  }

  /**
   * Construire le profil de connexion pour une organisation
   */
  buildConnectionProfile(orgName) {
    const orgConfig = fabricConfig.getOrgConfig(orgName);
    
    return {
      name: `${orgName}-network`,
      version: '1.0.0',
      client: {
        organization: orgConfig.name,
        connection: {
          timeout: {
            peer: {
              endorser: '300'
            },
            orderer: '300'
          }
        }
      },
      organizations: {
        [orgConfig.mspId]: {
          mspid: orgConfig.mspId,
          peers: [orgConfig.peer],
          certificateAuthorities: [`ca-${orgConfig.name}`]
        }
      },
      peers: {
        [orgConfig.peer]: {
          url: orgConfig.peerUrl,
          tlsCACerts: {
            pem: fs.readFileSync(orgConfig.paths.peerTlsCert).toString()
          },
          grpcOptions: {
            'ssl-target-name-override': orgConfig.peer,
            'hostnameOverride': orgConfig.peer
          }
        }
      },
      orderers: {
        [fabricConfig.orderer.name]: {
          url: fabricConfig.orderer.url,
          tlsCACerts: {
            pem: fs.readFileSync(fabricConfig.orderer.tlsCert).toString()
          },
          grpcOptions: {
            'ssl-target-name-override': fabricConfig.orderer.name,
            'hostnameOverride': fabricConfig.orderer.name
          }
        }
      },
      channels: {
        [fabricConfig.channelName]: {
          orderers: [fabricConfig.orderer.name],
          peers: {
            [orgConfig.peer]: {
              endorsingPeer: true,
              chaincodeQuery: true,
              ledgerQuery: true,
              eventSource: true
            }
          }
        }
      }
    };
  }

  /**
   * Se connecter au réseau Fabric
   */
  async connect(orgName = 'afor', userName = 'Admin') {
    try {
      // Initialiser le wallet et enregistrer l'admin
      await this.enrollAdmin(orgName);

      // Créer une instance de gateway
      this.gateway = new Gateway();

      // Construire le profil de connexion
      const connectionProfile = this.buildConnectionProfile(orgName);

      // Options de connexion
      const connectionOptions = {
        wallet: this.wallet,
        identity: `${orgName}-admin`,
        discovery: { enabled: true, asLocalhost: true }
      };

      // Se connecter
      await this.gateway.connect(connectionProfile, connectionOptions);
      logger.info(`Connecté au réseau Fabric via l'organisation ${orgName}`);

      // Obtenir le réseau (canal)
      this.network = await this.gateway.getNetwork(fabricConfig.channelName);
      logger.info(`Connecté au canal ${fabricConfig.channelName}`);

      // Obtenir le contrat
      this.contract = this.network.getContract(fabricConfig.chaincodeName);
      logger.info(`Contrat ${fabricConfig.chaincodeName} obtenu`);

      return this.contract;
    } catch (error) {
      logger.error('Erreur de connexion au réseau Fabric:', error);
      throw error;
    }
  }

  /**
   * Se déconnecter du réseau
   */
  async disconnect() {
    if (this.gateway) {
      await this.gateway.disconnect();
      this.gateway = null;
      this.network = null;
      this.contract = null;
      logger.info('Déconnecté du réseau Fabric');
    }
  }

  /**
   * Obtenir le contrat (se connecte si nécessaire)
   */
  async getContract(orgName = 'afor') {
    if (!this.contract) {
      await this.connect(orgName);
    }
    return this.contract;
  }

  /**
   * Soumettre une transaction (invoke)
   */
  async submitTransaction(functionName, ...args) {
    try {
      const contract = await this.getContract();
      logger.info(`Soumission de la transaction: ${functionName}`, { args });
      
      const result = await contract.submitTransaction(functionName, ...args);
      
      logger.info(`Transaction ${functionName} soumise avec succès`);
      return result.toString();
    } catch (error) {
      logger.error(`Erreur lors de la soumission de ${functionName}:`, error);
      throw error;
    }
  }

  /**
   * Évaluer une transaction (query)
   */
  async evaluateTransaction(functionName, ...args) {
    try {
      const contract = await this.getContract();
      logger.info(`Évaluation de la transaction: ${functionName}`, { args });
      
      const result = await contract.evaluateTransaction(functionName, ...args);
      
      logger.info(`Transaction ${functionName} évaluée avec succès`);
      return result.toString();
    } catch (error) {
      logger.error(`Erreur lors de l'évaluation de ${functionName}:`, error);
      throw error;
    }
  }
}

// Exporter une instance singleton
module.exports = new FabricService();
