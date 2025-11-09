package ci.foncier.chaincode.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Représente l'approbation d'un contrat par un responsable (Chef CVGFR ou Préfet)
 */
@DataType()
public class ContractApprobation {

    @Property()
    private String approvedBy; // User ID

    @Property()
    private String approverName;

    @Property()
    private String approverRole; // CHEF_CVGFR, PREFET, ADMIN_CVGFR

    @Property()
    private String approverOrganization; // CVGFR, PREFET

    @Property()
    private LocalDateTime approvedAt;

    @Property()
    private String comment;

    @Property()
    private String digitalSignature; // Signature numérique ECDSA

    @Property()
    private String publicKeyFingerprint; // Empreinte de la clé publique

    @Property()
    private String transactionId; // Blockchain transaction ID

    public ContractApprobation() {
    }

    public ContractApprobation(
            @JsonProperty("approvedBy") String approvedBy,
            @JsonProperty("approverName") String approverName,
            @JsonProperty("approverRole") String approverRole,
            @JsonProperty("approvedAt") LocalDateTime approvedAt) {
        this.approvedBy = approvedBy;
        this.approverName = approverName;
        this.approverRole = approverRole;
        this.approvedAt = approvedAt;
    }

    // Getters and Setters
    public String getApprovedBy() {
        return approvedBy;
    }

    public void setApprovedBy(String approvedBy) {
        this.approvedBy = approvedBy;
    }

    public String getApproverName() {
        return approverName;
    }

    public void setApproverName(String approverName) {
        this.approverName = approverName;
    }

    public String getApproverRole() {
        return approverRole;
    }

    public void setApproverRole(String approverRole) {
        this.approverRole = approverRole;
    }

    public String getApproverOrganization() {
        return approverOrganization;
    }

    public void setApproverOrganization(String approverOrganization) {
        this.approverOrganization = approverOrganization;
    }

    public LocalDateTime getApprovedAt() {
        return approvedAt;
    }

    public void setApprovedAt(LocalDateTime approvedAt) {
        this.approvedAt = approvedAt;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public String getDigitalSignature() {
        return digitalSignature;
    }

    public void setDigitalSignature(String digitalSignature) {
        this.digitalSignature = digitalSignature;
    }

    public String getPublicKeyFingerprint() {
        return publicKeyFingerprint;
    }

    public void setPublicKeyFingerprint(String publicKeyFingerprint) {
        this.publicKeyFingerprint = publicKeyFingerprint;
    }

    public String getTransactionId() {
        return transactionId;
    }

    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ContractApprobation that = (ContractApprobation) o;
        return Objects.equals(approvedBy, that.approvedBy) &&
                Objects.equals(approvedAt, that.approvedAt);
    }

    @Override
    public int hashCode() {
        return Objects.hash(approvedBy, approvedAt);
    }

    @Override
    public String toString() {
        return "ContractApprobation{" +
                "approverName='" + approverName + '\'' +
                ", approverRole='" + approverRole + '\'' +
                ", approvedAt=" + approvedAt +
                '}';
    }
}
