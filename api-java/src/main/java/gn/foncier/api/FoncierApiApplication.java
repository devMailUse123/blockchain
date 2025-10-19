package gn.foncier.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * Application principale de l'API REST pour la gestion des contrats fonciers
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class FoncierApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(FoncierApiApplication.class, args);
    }

}