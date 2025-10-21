package ci.foncier.chaincode.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.time.LocalDateTime;
import java.util.Objects;

@DataType()
public class ContractSignatory {

    @Property()
    private int id;

    @Property()
    private String codeContract;

    @Property()
    private String ownerName;

    @Property()
    private String ownerSignature;

    @Property()
    private String beneficiaryName;

    @Property()
    private String beneficiarySignature;

    @Property()
    private String ownerWitnessName;

    @Property()
    private String ownerWitnessSignature;

    @Property()
    private String beneficiaryWitnessName;

    @Property()
    private String beneficiaryWitnessSignature;

    @Property()
    private String cvgfrPresidentName;

    @Property()
    private String cvgfrPresidentSignature;

    @Property()
    private LocalDateTime creationDate;

    public ContractSignatory() {
    }

    public ContractSignatory(@JsonProperty("id") int id,
                             @JsonProperty("codeContract") String codeContract,
                             @JsonProperty("ownerName") String ownerName,
                             @JsonProperty("ownerSignature") String ownerSignature,
                             @JsonProperty("beneficiaryName") String beneficiaryName,
                             @JsonProperty("beneficiarySignature") String beneficiarySignature,
                             @JsonProperty("ownerWitnessName") String ownerWitnessName,
                             @JsonProperty("ownerWitnessSignature") String ownerWitnessSignature,
                             @JsonProperty("beneficiaryWitnessName") String beneficiaryWitnessName,
                             @JsonProperty("beneficiaryWitnessSignature") String beneficiaryWitnessSignature,
                             @JsonProperty("cvgfrPresidentName") String cvgfrPresidentName,
                             @JsonProperty("cvgfrPresidentSignature") String cvgfrPresidentSignature,
                             @JsonProperty("creationDate") LocalDateTime creationDate) {
        this.id = id;
        this.codeContract = codeContract;
        this.ownerName = ownerName;
        this.ownerSignature = ownerSignature;
        this.beneficiaryName = beneficiaryName;
        this.beneficiarySignature = beneficiarySignature;
        this.ownerWitnessName = ownerWitnessName;
        this.ownerWitnessSignature = ownerWitnessSignature;
        this.beneficiaryWitnessName = beneficiaryWitnessName;
        this.beneficiaryWitnessSignature = beneficiaryWitnessSignature;
        this.cvgfrPresidentName = cvgfrPresidentName;
        this.cvgfrPresidentSignature = cvgfrPresidentSignature;
        this.creationDate = creationDate;
    }

    // Getters et Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getCodeContract() { return codeContract; }
    public void setCodeContract(String codeContract) { this.codeContract = codeContract; }

    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String ownerName) { this.ownerName = ownerName; }

    public String getOwnerSignature() { return ownerSignature; }
    public void setOwnerSignature(String ownerSignature) { this.ownerSignature = ownerSignature; }

    public String getBeneficiaryName() { return beneficiaryName; }
    public void setBeneficiaryName(String beneficiaryName) { this.beneficiaryName = beneficiaryName; }

    public String getBeneficiarySignature() { return beneficiarySignature; }
    public void setBeneficiarySignature(String beneficiarySignature) { this.beneficiarySignature = beneficiarySignature; }

    public String getOwnerWitnessName() { return ownerWitnessName; }
    public void setOwnerWitnessName(String ownerWitnessName) { this.ownerWitnessName = ownerWitnessName; }

    public String getOwnerWitnessSignature() { return ownerWitnessSignature; }
    public void setOwnerWitnessSignature(String ownerWitnessSignature) { this.ownerWitnessSignature = ownerWitnessSignature; }

    public String getBeneficiaryWitnessName() { return beneficiaryWitnessName; }
    public void setBeneficiaryWitnessName(String beneficiaryWitnessName) { this.beneficiaryWitnessName = beneficiaryWitnessName; }

    public String getBeneficiaryWitnessSignature() { return beneficiaryWitnessSignature; }
    public void setBeneficiaryWitnessSignature(String beneficiaryWitnessSignature) { this.beneficiaryWitnessSignature = beneficiaryWitnessSignature; }

    public String getCvgfrPresidentName() { return cvgfrPresidentName; }
    public void setCvgfrPresidentName(String cvgfrPresidentName) { this.cvgfrPresidentName = cvgfrPresidentName; }

    public String getCvgfrPresidentSignature() { return cvgfrPresidentSignature; }
    public void setCvgfrPresidentSignature(String cvgfrPresidentSignature) { this.cvgfrPresidentSignature = cvgfrPresidentSignature; }

    public LocalDateTime getCreationDate() { return creationDate; }
    public void setCreationDate(LocalDateTime creationDate) { this.creationDate = creationDate; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ContractSignatory that = (ContractSignatory) o;
        return id == that.id;
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
