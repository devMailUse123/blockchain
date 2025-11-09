package ci.foncier.chaincode.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Représente la validation finale d'un contrat avec signature numérique
 */
@DataType()
public class ContractValidation {

    @Property()
    private String validatedBy; // User ID

    @Property()
    private String validatorName;

    @Property()
    private String validatorRole; // ADMIN_CVGFR

    @Property()
    private String validatorOrganization; // CVGFR

    @Property()
    private LocalDateTime validatedAt;

    @Property()
    private String digitalSignature; // Signature numérique finale ECDSA

    @Property()
    private String documentHash; // Hash SHA-256 du contrat complet

    @Property()
    private String hashAlgorithm; // SHA-256

    @Property()
    private String signatureAlgorithm; // ECDSA-SHA256

    @Property()
    private String publicKeyFingerprint; // Empreinte de la clé publique

    @Property()
    private Long blockchainTimestamp; // Timestamp blockchain (epoch)

    @Property()
    private String transactionId; // Blockchain transaction ID

    @Property()
    private String pdfUrl; // URL du PDF signé

    @Property()
    private String verificationUrl; // URL de vérification publique

    public ContractValidation() {
    }

    public ContractValidation(
            @JsonProperty("validatedBy") String validatedBy,
            @JsonProperty("validatorName") String validatorName,
            @JsonProperty("validatedAt") LocalDateTime validatedAt) {
        this.validatedBy = validatedBy;
        this.validatorName = validatorName;
        this.validatedAt = validatedAt;
        this.hashAlgorithm = "SHA-256";
        this.signatureAlgorithm = "ECDSA-SHA256";
    }

    // Getters and Setters
    public String getValidatedBy() {
        return validatedBy;
    }

    public void setValidatedBy(String validatedBy) {
        this.validatedBy = validatedBy;
    }

    public String getValidatorName() {
        return validatorName;
    }

    public void setValidatorName(String validatorName) {
        this.validatorName = validatorName;
    }

    public String getValidatorRole() {
        return validatorRole;
    }

    public void setValidatorRole(String validatorRole) {
        this.validatorRole = validatorRole;
    }

    public String getValidatorOrganization() {
        return validatorOrganization;
    }

    public void setValidatorOrganization(String validatorOrganization) {
        this.validatorOrganization = validatorOrganization;
    }

    public LocalDateTime getValidatedAt() {
        return validatedAt;
    }

    public void setValidatedAt(LocalDateTime validatedAt) {
        this.validatedAt = validatedAt;
    }

    public String getDigitalSignature() {
        return digitalSignature;
    }

    public void setDigitalSignature(String digitalSignature) {
        this.digitalSignature = digitalSignature;
    }

    public String getDocumentHash() {
        return documentHash;
    }

    public void setDocumentHash(String documentHash) {
        this.documentHash = documentHash;
    }

    public String getHashAlgorithm() {
        return hashAlgorithm;
    }

    public void setHashAlgorithm(String hashAlgorithm) {
        this.hashAlgorithm = hashAlgorithm;
    }

    public String getSignatureAlgorithm() {
        return signatureAlgorithm;
    }

    public void setSignatureAlgorithm(String signatureAlgorithm) {
        this.signatureAlgorithm = signatureAlgorithm;
    }

    public String getPublicKeyFingerprint() {
        return publicKeyFingerprint;
    }

    public void setPublicKeyFingerprint(String publicKeyFingerprint) {
        this.publicKeyFingerprint = publicKeyFingerprint;
    }

    public Long getBlockchainTimestamp() {
        return blockchainTimestamp;
    }

    public void setBlockchainTimestamp(Long blockchainTimestamp) {
        this.blockchainTimestamp = blockchainTimestamp;
    }

    public String getTransactionId() {
        return transactionId;
    }

    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }

    public String getPdfUrl() {
        return pdfUrl;
    }

    public void setPdfUrl(String pdfUrl) {
        this.pdfUrl = pdfUrl;
    }

    public String getVerificationUrl() {
        return verificationUrl;
    }

    public void setVerificationUrl(String verificationUrl) {
        this.verificationUrl = verificationUrl;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ContractValidation that = (ContractValidation) o;
        return Objects.equals(transactionId, that.transactionId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(transactionId);
    }

    @Override
    public String toString() {
        return "ContractValidation{" +
                "validatorName='" + validatorName + '\'' +
                ", validatedAt=" + validatedAt +
                ", documentHash='" + documentHash + '\'' +
                ", transactionId='" + transactionId + '\'' +
                '}';
    }
}
