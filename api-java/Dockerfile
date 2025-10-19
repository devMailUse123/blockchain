# Dockerfile pour l'API REST Java Spring Boot
FROM openjdk:11-jre-slim

# Métadonnées
LABEL maintainer="AFOR - Agence Foncière Rurale Guinée"
LABEL description="API REST Java pour la gestion des contrats fonciers sur Hyperledger Fabric"
LABEL version="1.0.0"

# Variables d'environnement
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV SPRING_PROFILES_ACTIVE=docker

# Création du répertoire de travail
WORKDIR /app

# Installation des dépendances système
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copie du fichier JAR de l'application
COPY target/foncier-api-*.jar app.jar

# Copie des scripts de démarrage
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Création du répertoire pour les logs
RUN mkdir -p /app/logs

# Exposition du port
EXPOSE 8080

# Point de santé pour Docker
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Utilisateur non-root pour la sécurité
RUN groupadd -r appuser && useradd --no-log-init -r -g appuser appuser
RUN chown -R appuser:appuser /app
USER appuser

# Point d'entrée
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java", "-jar", "/app/app.jar"]