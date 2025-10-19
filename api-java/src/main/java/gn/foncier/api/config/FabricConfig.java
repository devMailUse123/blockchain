package gn.foncier.api.config;

import org.hyperledger.fabric.gateway.*;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.InvalidKeyException;
import java.security.cert.CertificateException;

/**
 * Configuration Fabric Gateway
 */
@Configuration
@EnableConfigurationProperties(FabricProperties.class)
public class FabricConfig {

    private static final Logger logger = LoggerFactory.getLogger(FabricConfig.class);
    
    private final FabricProperties fabricProperties;

    public FabricConfig(FabricProperties fabricProperties) {
        this.fabricProperties = fabricProperties;
    }

    @Bean
    public Gateway fabricGateway() throws IOException, CertificateException, InvalidKeyException {
        logger.info("Initialisation de la connexion Fabric Gateway");
        
        // Chemin vers le connection profile
        Path networkConfigPath = Paths.get(fabricProperties.getNetworkConfigPath());
        
        // Charger l'identité depuis le wallet
        Wallet wallet = Wallets.newFileSystemWallet(Paths.get(fabricProperties.getWalletPath()));
        
        // Builder du gateway
        Gateway.Builder builder = Gateway.createBuilder();
        
        builder.identity(wallet, fabricProperties.getUserId())
               .networkConfig(networkConfigPath)
               .discovery(true);

        Gateway gateway = builder.connect();
        
        logger.info("Connexion Fabric Gateway établie avec succès pour l'utilisateur: {}", 
                   fabricProperties.getUserId());
        
        return gateway;
    }

    @Bean
    public Network fabricNetwork(Gateway gateway) {
        logger.info("Accès au réseau Fabric - Canal: {}", fabricProperties.getChannelName());
        
        Network network = gateway.getNetwork(fabricProperties.getChannelName());
        
        logger.info("Connexion au canal {} établie", fabricProperties.getChannelName());
        
        return network;
    }

    @Bean
    public Contract fabricContract(Network network) {
        logger.info("Accès au chaincode: {}", fabricProperties.getChaincodeId());
        
        Contract contract = network.getContract(fabricProperties.getChaincodeId());
        
        logger.info("Connexion au chaincode {} établie", fabricProperties.getChaincodeId());
        
        return contract;
    }
}