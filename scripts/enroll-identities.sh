#!/bin/bash

# Script pour inscrire toutes les identités via fabric-ca-client
set -e

export PATH=/home/absolue/fabric-samples/bin:$PATH
PROJECT_DIR="/home/absolue/my-blockchain"
cd $PROJECT_DIR

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Inscription des identités...${NC}"

# ================== AFOR ==================
echo -e "${GREEN}[1/4] AFOR${NC}"
mkdir -p /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/ca
docker cp ca-afor:/etc/hyperledger/fabric-ca-server/ca-cert.pem /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/ca/

# Admin
echo "  - Admin..."
fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 \
    --caname ca-afor \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp > /dev/null 2>&1

# Config NodeOUs pour l'admin
cat > /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: orderer
EOF

# Enregistrer peer0
echo "  - Enregistrement peer0..."
fabric-ca-client register -u https://localhost:7054 --caname ca-afor \
    --id.name peer0 --id.secret peer0pw --id.type peer \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp > /dev/null 2>&1

# Peer0 MSP
echo "  - Peer0 MSP..."
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 \
    --caname ca-afor \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/msp > /dev/null 2>&1

# Peer0 TLS
echo "  - Peer0 TLS..."
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 \
    --caname ca-afor \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/ca/ca-cert.pem \
    --enrollment.profile tls \
    --csr.hosts peer0.afor.foncier.ci \
    --csr.hosts localhost \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls > /dev/null 2>&1

cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/tlscacerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/signcerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/server.crt
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/keystore/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/server.key

# Config NodeOUs
cat > /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: orderer
EOF

# MSP de l'organisation AFOR
mkdir -p /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/msp/cacerts
mkdir -p /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/msp/tlscacerts
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/msp/cacerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/msp/cacerts/
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/tlscacerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/msp/tlscacerts/
cat > /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-afor.pem
    OrganizationalUnitIdentifier: orderer
EOF

# ================== CVGFR ==================
echo -e "${GREEN}[2/4] CVGFR${NC}"
mkdir -p /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/ca
docker cp ca-cvgfr:/etc/hyperledger/fabric-ca-server/ca-cert.pem /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/ca/

echo "  - Admin..."
fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 \
    --caname ca-cvgfr \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp > /dev/null 2>&1

echo "  - Enregistrement peer0..."
fabric-ca-client register -u https://localhost:8054 --caname ca-cvgfr \
    --id.name peer0 --id.secret peer0pw --id.type peer \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp > /dev/null 2>&1

echo "  - Peer0 MSP..."
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 \
    --caname ca-cvgfr \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/msp > /dev/null 2>&1

echo "  - Peer0 TLS..."
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 \
    --caname ca-cvgfr \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/ca/ca-cert.pem \
    --enrollment.profile tls \
    --csr.hosts peer0.cvgfr.foncier.ci \
    --csr.hosts localhost \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls > /dev/null 2>&1

cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/tlscacerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/signcerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/server.crt
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/keystore/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/server.key

cat > /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-cvgfr.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-cvgfr.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-cvgfr.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-cvgfr.pem
    OrganizationalUnitIdentifier: orderer
EOF

# MSP de l'organisation CVGFR
mkdir -p /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/msp/cacerts
mkdir -p /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/msp/tlscacerts
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/msp/cacerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/msp/cacerts/
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/tlscacerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/msp/tlscacerts/
cat > /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-cvgfr.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-cvgfr.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-cvgfr.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-cvgfr.pem
    OrganizationalUnitIdentifier: orderer
EOF

# ================== PREFET ==================
echo -e "${GREEN}[3/4] PREFET${NC}"
mkdir -p /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/ca
docker cp ca-prefet:/etc/hyperledger/fabric-ca-server/ca-cert.pem /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/ca/

echo "  - Admin..."
fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 \
    --caname ca-prefet \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/users/Admin@prefet.foncier.ci/msp > /dev/null 2>&1

echo "  - Enregistrement peer0..."
fabric-ca-client register -u https://localhost:9054 --caname ca-prefet \
    --id.name peer0 --id.secret peer0pw --id.type peer \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/users/Admin@prefet.foncier.ci/msp > /dev/null 2>&1

echo "  - Peer0 MSP..."
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:9054 \
    --caname ca-prefet \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/msp > /dev/null 2>&1

echo "  - Peer0 TLS..."
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:9054 \
    --caname ca-prefet \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/ca/ca-cert.pem \
    --enrollment.profile tls \
    --csr.hosts peer0.prefet.foncier.ci \
    --csr.hosts localhost \
    --mspdir /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls > /dev/null 2>&1

cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/tlscacerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/ca.crt
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/signcerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/server.crt
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/keystore/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/server.key

cat > /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-prefet.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-prefet.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-prefet.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-prefet.pem
    OrganizationalUnitIdentifier: orderer
EOF

# MSP de l'organisation PREFET
mkdir -p /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/msp/cacerts
mkdir -p /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/msp/tlscacerts
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/msp/cacerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/msp/cacerts/
cp /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/tlscacerts/* \
   /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/msp/tlscacerts/
cat > /home/absolue/my-blockchain/network/organizations/peerOrganizations/prefet.foncier.ci/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-prefet.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-prefet.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-prefet.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-prefet.pem
    OrganizationalUnitIdentifier: orderer
EOF

# ================== ORDERER ==================
echo -e "${GREEN}[4/4] ORDERER${NC}"
mkdir -p /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/ca
docker cp ca-orderer:/etc/hyperledger/fabric-ca-server/ca-cert.pem /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/ca/

echo "  - Admin..."
fabric-ca-client enroll -u https://admin:adminpw@localhost:10054 \
    --caname ca-orderer \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/users/Admin@foncier.ci/msp > /dev/null 2>&1

# Config NodeOUs pour l'admin
cat > /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/users/Admin@foncier.ci/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer
EOF

echo "  - Enregistrement orderer..."
fabric-ca-client register -u https://localhost:10054 --caname ca-orderer \
    --id.name orderer --id.secret ordererpw --id.type orderer \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/users/Admin@foncier.ci/msp > /dev/null 2>&1

echo "  - Orderer MSP..."
fabric-ca-client enroll -u https://orderer:ordererpw@localhost:10054 \
    --caname ca-orderer \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/ca/ca-cert.pem \
    --mspdir /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp > /dev/null 2>&1

echo "  - Orderer TLS..."
fabric-ca-client enroll -u https://orderer:ordererpw@localhost:10054 \
    --caname ca-orderer \
    --tls.certfiles /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/ca/ca-cert.pem \
    --enrollment.profile tls \
    --csr.hosts orderer.foncier.ci \
    --csr.hosts localhost \
    --mspdir /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls > /dev/null 2>&1

cp /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/tlscacerts/* \
   /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/ca.crt
cp /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/signcerts/* \
   /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.crt
cp /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/keystore/* \
   /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.key

cat > /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer
EOF

# MSP de l'organisation orderer
mkdir -p /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/msp/tlscacerts
mkdir -p /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/msp/cacerts
cp /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/tlscacerts/* \
   /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/msp/tlscacerts/
cp /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/cacerts/* \
   /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/msp/cacerts/
cp /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/users/Admin@foncier.ci/msp/config.yaml \
   /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/msp/config.yaml

echo -e "${GREEN}✓ Toutes les identités inscrites !${NC}"
