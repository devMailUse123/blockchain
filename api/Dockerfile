# Dockerfile pour l'API REST Hyperledger Fabric
# Pour déploiement mono-VM sur AWS

FROM node:18-alpine

# Métadonnées
LABEL maintainer="AFOR Innovation"
LABEL description="API REST pour réseau Hyperledger Fabric - Sécurisation Foncière CI"
LABEL version="1.0"

# Installer les dépendances système
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Créer répertoire de travail
WORKDIR /app

# Copier package.json et package-lock.json
COPY package*.json ./

# Installer les dépendances Node.js
RUN npm ci --only=production

# Copier le code source
COPY . .

# Créer répertoire pour les logs
RUN mkdir -p /app/logs && chmod 777 /app/logs

# Exposer le port API
EXPOSE 3000

# Variables d'environnement par défaut
ENV NODE_ENV=production \
    PORT=3000 \
    LOG_LEVEL=info

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Démarrer l'application
CMD ["node", "src/server.js"]
