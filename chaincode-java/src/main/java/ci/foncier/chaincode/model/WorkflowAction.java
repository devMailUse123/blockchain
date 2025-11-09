package ci.foncier.chaincode.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Représente une action dans le workflow du contrat (création, modification, signature, etc.)
 */
@DataType()
public class WorkflowAction {

    @Property()
    private String type; // CREATE, MODIFY, SIGN, APPROVE, VALIDATE, REJECT, DELETE

    @Property()
    private Actor actor;

    @Property()
    private LocalDateTime timestamp;

    @Property()
    private String signature; // Signature numérique (optionnel)

    @Property()
    private String comment;

    @Property()
    private String previousStatus; // État avant l'action

    @Property()
    private String newStatus; // État après l'action

    @Property()
    private String ipAddress;

    @Property()
    private String transactionId; // Blockchain transaction ID

    public WorkflowAction() {
    }

    public WorkflowAction(
            @JsonProperty("type") String type,
            @JsonProperty("actor") Actor actor,
            @JsonProperty("timestamp") LocalDateTime timestamp) {
        this.type = type;
        this.actor = actor;
        this.timestamp = timestamp;
    }

    // Getters and Setters
    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Actor getActor() {
        return actor;
    }

    public void setActor(Actor actor) {
        this.actor = actor;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public String getSignature() {
        return signature;
    }

    public void setSignature(String signature) {
        this.signature = signature;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public String getPreviousStatus() {
        return previousStatus;
    }

    public void setPreviousStatus(String previousStatus) {
        this.previousStatus = previousStatus;
    }

    public String getNewStatus() {
        return newStatus;
    }

    public void setNewStatus(String newStatus) {
        this.newStatus = newStatus;
    }

    public String getIpAddress() {
        return ipAddress;
    }

    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
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
        WorkflowAction that = (WorkflowAction) o;
        return Objects.equals(timestamp, that.timestamp) &&
                Objects.equals(actor, that.actor);
    }

    @Override
    public int hashCode() {
        return Objects.hash(timestamp, actor);
    }

    @Override
    public String toString() {
        return "WorkflowAction{" +
                "type='" + type + '\'' +
                ", actor=" + actor +
                ", timestamp=" + timestamp +
                ", newStatus='" + newStatus + '\'' +
                '}';
    }
}
