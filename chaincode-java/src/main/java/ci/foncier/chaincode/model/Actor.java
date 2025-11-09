package ci.foncier.chaincode.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.util.Objects;

/**
 * Représente un acteur (utilisateur) effectuant une action dans le workflow
 */
@DataType()
public class Actor {

    @Property()
    private String userId;

    @Property()
    private String userName;

    @Property()
    private String role; // AGENT, OWNER, BENEFICIARY, APPROVER, VALIDATOR, WITNESS

    @Property()
    private String organization; // AFOR, CVGFR, PREFET

    @Property()
    private String email;

    @Property()
    private String phoneNumber;

    public Actor() {
    }

    public Actor(
            @JsonProperty("userId") String userId,
            @JsonProperty("userName") String userName,
            @JsonProperty("role") String role,
            @JsonProperty("organization") String organization) {
        this.userId = userId;
        this.userName = userName;
        this.role = role;
        this.organization = organization;
    }

    // Getters and Setters
    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getOrganization() {
        return organization;
    }

    public void setOrganization(String organization) {
        this.organization = organization;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Actor actor = (Actor) o;
        return Objects.equals(userId, actor.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId);
    }

    @Override
    public String toString() {
        return "Actor{" +
                "userId='" + userId + '\'' +
                ", userName='" + userName + '\'' +
                ", role='" + role + '\'' +
                ", organization='" + organization + '\'' +
                '}';
    }
}
