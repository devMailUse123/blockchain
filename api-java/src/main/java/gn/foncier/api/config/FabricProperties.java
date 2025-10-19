package gn.foncier.api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;

/**
 * Configuration des propriétés Fabric
 */
@ConfigurationProperties(prefix = "fabric")
public class FabricProperties {
    
    private final String networkConfigPath;
    private final String walletPath;
    private final String channelName;
    private final String chaincodeId;
    private final String mspId;
    private final String userId;
    private final Tls tls;
    
    @ConstructorBinding
    public FabricProperties(String networkConfigPath, String walletPath, String channelName, 
                           String chaincodeId, String mspId, String userId, Tls tls) {
        this.networkConfigPath = networkConfigPath;
        this.walletPath = walletPath;
        this.channelName = channelName;
        this.chaincodeId = chaincodeId;
        this.mspId = mspId;
        this.userId = userId;
        this.tls = tls;
    }
    
    // Getters
    public String getNetworkConfigPath() { return networkConfigPath; }
    public String getWalletPath() { return walletPath; }
    public String getChannelName() { return channelName; }
    public String getChaincodeId() { return chaincodeId; }
    public String getMspId() { return mspId; }
    public String getUserId() { return userId; }
    public Tls getTls() { return tls; }
    
    public static class Tls {
        private final boolean enabled;
        private final String certPath;
        private final String keyPath;
        private final String caPath;
        
        @ConstructorBinding
        public Tls(boolean enabled, String certPath, String keyPath, String caPath) {
            this.enabled = enabled;
            this.certPath = certPath;
            this.keyPath = keyPath;
            this.caPath = caPath;
        }
        
        public boolean isEnabled() { return enabled; }
        public String getCertPath() { return certPath; }
        public String getKeyPath() { return keyPath; }
        public String getCaPath() { return caPath; }
    }
}