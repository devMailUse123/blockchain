package ci.foncier.chaincode.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.time.LocalDateTime;
import java.util.Objects;

@DataType()
public class Person {

    @Property()
    private int id;

    @Property()
    private String name;

    @Property()
    private String partnerName;

    @Property()
    private LocalDateTime birthDate;

    @Property()
    private String fatherName;

    @Property()
    private String motherName;

    @Property()
    private String idType;

    @Property()
    private String idNumber;

    @Property()
    private LocalDateTime idDate;

    @Property()
    private String phoneNumber;

    @Property()
    private String type;

    @Property()
    private String address;

    @Property()
    private String birthPlace;

    @Property()
    private String genre;

    public Person() {
    }

    // Constructor avec tous les paramètres
    public Person(@JsonProperty("id") int id,
                  @JsonProperty("name") String name,
                  @JsonProperty("partnerName") String partnerName,
                  @JsonProperty("birthDate") LocalDateTime birthDate,
                  @JsonProperty("fatherName") String fatherName,
                  @JsonProperty("motherName") String motherName,
                  @JsonProperty("idType") String idType,
                  @JsonProperty("idNumber") String idNumber,
                  @JsonProperty("idDate") LocalDateTime idDate,
                  @JsonProperty("phoneNumber") String phoneNumber,
                  @JsonProperty("type") String type,
                  @JsonProperty("address") String address,
                  @JsonProperty("birthPlace") String birthPlace,
                  @JsonProperty("genre") String genre) {
        this.id = id;
        this.name = name;
        this.partnerName = partnerName;
        this.birthDate = birthDate;
        this.fatherName = fatherName;
        this.motherName = motherName;
        this.idType = idType;
        this.idNumber = idNumber;
        this.idDate = idDate;
        this.phoneNumber = phoneNumber;
        this.type = type;
        this.address = address;
        this.birthPlace = birthPlace;
        this.genre = genre;
    }

    // Getters et Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getPartnerName() { return partnerName; }
    public void setPartnerName(String partnerName) { this.partnerName = partnerName; }

    public LocalDateTime getBirthDate() { return birthDate; }
    public void setBirthDate(LocalDateTime birthDate) { this.birthDate = birthDate; }

    public String getFatherName() { return fatherName; }
    public void setFatherName(String fatherName) { this.fatherName = fatherName; }

    public String getMotherName() { return motherName; }
    public void setMotherName(String motherName) { this.motherName = motherName; }

    public String getIdType() { return idType; }
    public void setIdType(String idType) { this.idType = idType; }

    public String getIdNumber() { return idNumber; }
    public void setIdNumber(String idNumber) { this.idNumber = idNumber; }

    public LocalDateTime getIdDate() { return idDate; }
    public void setIdDate(LocalDateTime idDate) { this.idDate = idDate; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getBirthPlace() { return birthPlace; }
    public void setBirthPlace(String birthPlace) { this.birthPlace = birthPlace; }

    public String getGenre() { return genre; }
    public void setGenre(String genre) { this.genre = genre; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Person person = (Person) o;
        return id == person.id && Objects.equals(idNumber, person.idNumber);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, idNumber);
    }
}
