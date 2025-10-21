#!/bin/bash

# Script de test de l'API

API_URL="http://localhost:3000"

echo "🧪 Test de l'API Blockchain AFOR"
echo "================================="
echo ""

# Test 1: Health Check
echo "1️⃣  Test Health Check..."
curl -s "${API_URL}/api/health" | jq .
echo ""

# Test 2: Blockchain Health
echo "2️⃣  Test Blockchain Health..."
curl -s "${API_URL}/api/health/blockchain" | jq .
echo ""

# Test 3: Créer un contrat
echo "3️⃣  Test Création de Contrat..."
curl -s -X POST "${API_URL}/api/contracts" \
  -H "Content-Type: application/json" \
  -d '{
    "codeContract": "CA-TEST-001",
    "type": "VENTE",
    "ownerId": "USER001",
    "beneficiaryId": "USER002",
    "terrainId": "TERRAIN001",
    "village": "Abobo",
    "department": "Abidjan",
    "duration": 99,
    "durationUnit": "ANNEE",
    "rent": 0,
    "usagesAutorises": ["HABITATION"]
  }' | jq .
echo ""

# Test 4: Lire tous les contrats
echo "4️⃣  Test Lecture de tous les contrats..."
curl -s "${API_URL}/api/contracts" | jq .
echo ""

echo "✅ Tests terminés!"
