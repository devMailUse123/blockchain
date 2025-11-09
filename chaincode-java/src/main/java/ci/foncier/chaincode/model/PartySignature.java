package ci.foncier.chaincode.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Représente la signature d'une partie prenante (propriétaire, bénéficiaire, témoin)
 */
@DataType()
public class PartySignature {

    @Property()
    private String partyType; // OWNER, BENEFICIARY, WITNESS

    @Property()
    private String partyName;

    @Property()
    private String partyId;

    @Property()
    private String signatureData; // Image de la signature (base64) ou hash

    @Property()
    private LocalDateTime signedAt;

    @Property()
    private String ipAddress;

    @Property()
    private String deviceInfo; // Informations sur la tablette/appareil

    @Property()
    private String geoLocation; // Coordonnées GPS (optionnel)

    public PartySignature() {
    }

    public PartySignature(
            @JsonProperty("partyType") String partyType,
            @JsonProperty("partyName") String partyName,
            @JsonProperty("partyId") String partyId,
            @JsonProperty("signedAt") LocalDateTime signedAt) {
        this.partyType = partyType;
        this.partyName = partyName;
        this.partyId = partyId;
        this.signedAt = signedAt;
    }

    // Getters and Setters
    public String getPartyType() {
        return partyType;
    }

    public void setPartyType(String partyType) {
        this.partyType = partyType;
    }

    public String getPartyName() {
        return partyName;
    }

    public void setPartyName(String partyName) {
        this.partyName = partyName;
    }

    public String getPartyId() {
        return partyId;
    }

    public void setPartyId(String partyId) {
        this.partyId = partyId;
    }

    public String getSignatureData() {
        return signatureData;
    }

    public void setSignatureData(String signatureData) {
        this.signatureData = signatureData;
    }

    public LocalDateTime getSignedAt() {
        return signedAt;
    }

    public void setSignedAt(LocalDateTime signedAt) {
        this.signedAt = signedAt;
    }

    public String getIpAddress() {
        return ipAddress;
    }

    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
    }

    public String getDeviceInfo() {
        return deviceInfo;
    }

    public void setDeviceInfo(String deviceInfo) {
        this.deviceInfo = deviceInfo;
    }

    public String getGeoLocation() {
        return geoLocation;
    }

    public void setGeoLocation(String geoLocation) {
        this.geoLocation = geoLocation;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        PartySignature that = (PartySignature) o;
        return Objects.equals(partyId, that.partyId) &&
                Objects.equals(signedAt, that.signedAt);
    }

    @Override
    public int hashCode() {
        return Objects.hash(partyId, signedAt);
    }

    @Override
    public String toString() {
        return "PartySignature{" +
                "partyType='" + partyType + '\'' +
                ", partyName='" + partyName + '\'' +
                ", signedAt=" + signedAt +
                '}';
    }
}
