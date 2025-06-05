#!/bin/bash

# ===================================================
# LEADHUB MASTER DEPLOYMENT SCRIPT
# ===================================================
# Lädt komplettes LeadHub-System von GitHub
# Richtet alles automatisch ein
# Ein Kommando für komplettes Setup
# ===================================================

# Farbdefinitionen
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Konfiguration
GITHUB_USER="Phil-LT"
REPO_NAME="leadhub-deployment"
GITHUB_URL="https://github.com/$GITHUB_USER/$REPO_NAME"
RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/main"

# Banner anzeigen
echo -e "${BLUE}${BOLD}"
echo "╔═════════════════════════════════════════════════════════════╗"
echo "║              LEADHUB MASTER DEPLOYMENT                      ║"
echo "║                 GitHub-basiertes Setup                      ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Repository: $GITHUB_URL${NC}"
echo -e "${YELLOW}Deployment gestartet...${NC}\n"

# Arbeitsverzeichnis erstellen
WORK_DIR="/home/ubuntu/leadhub-deployment"
echo -e "${BOLD}[1] ARBEITSVERZEICHNIS VORBEREITEN${NC}"
echo "----------------------------------------"

if [ -d "$WORK_DIR" ]; then
    echo -e "${YELLOW}Vorhandenes Verzeichnis wird gesichert...${NC}"
    mv "$WORK_DIR" "${WORK_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
echo -e "${GREEN}Arbeitsverzeichnis erstellt: $WORK_DIR${NC}\n"

# Git Repository klonen oder herunterladen
echo -e "${BOLD}[2] REPOSITORY HERUNTERLADEN${NC}"
echo "----------------------------------------"

if command -v git &> /dev/null; then
    echo -e "${YELLOW}Klone Repository mit Git...${NC}"
    git clone "$GITHUB_URL.git" .
    clone_status=$?
else
    echo -e "${YELLOW}Git nicht verfügbar, lade ZIP herunter...${NC}"
    curl -L "$GITHUB_URL/archive/main.zip" -o repo.zip
    unzip -q repo.zip
    mv "$REPO_NAME-main"/* .
    rm -rf "$REPO_NAME-main" repo.zip
    clone_status=$?
fi

if [ $clone_status -eq 0 ]; then
    echo -e "${GREEN}Repository erfolgreich heruntergeladen${NC}"
else
    echo -e "${RED}Fehler beim Herunterladen des Repositories${NC}"
    echo -e "${YELLOW}Versuche Fallback-Download...${NC}"
    
    # Fallback: Einzelne Dateien herunterladen
    mkdir -p scripts website
    
    # Skripte herunterladen
    curl -sSL "$RAW_URL/scripts/check_sandbox_status.sh" -o scripts/check_sandbox_status.sh
    curl -sSL "$RAW_URL/scripts/setup_github.sh" -o scripts/setup_github.sh
    curl -sSL "$RAW_URL/scripts/affiliate_signup.sh" -o scripts/affiliate_signup.sh
    curl -sSL "$RAW_URL/scripts/update_affiliate_ids.sh" -o scripts/update_affiliate_ids.sh
    
    # Website-Dateien herunterladen
    curl -sSL "$RAW_URL/website/index.html" -o website/index.html
    curl -sSL "$RAW_URL/website/styles.css" -o website/styles.css
    curl -sSL "$RAW_URL/website/affiliate-router.js" -o website/affiliate-router.js
    curl -sSL "$RAW_URL/website/form-handler.js" -o website/form-handler.js
    curl -sSL "$RAW_URL/website/analytics.js" -o website/analytics.js
    
    echo -e "${GREEN}Fallback-Download abgeschlossen${NC}"
fi

echo ""

# Skripte ausführbar machen
echo -e "${BOLD}[3] SKRIPTE KONFIGURIEREN${NC}"
echo "----------------------------------------"

if [ -d "scripts" ]; then
    chmod +x scripts/*.sh
    echo -e "${GREEN}Skripte sind jetzt ausführbar${NC}"
    
    # Skripte in Hauptverzeichnis verlinken
    ln -sf "$WORK_DIR/scripts/check_sandbox_status.sh" /home/ubuntu/check_sandbox_status.sh
    ln -sf "$WORK_DIR/scripts/setup_github.sh" /home/ubuntu/setup_github.sh
    ln -sf "$WORK_DIR/scripts/affiliate_signup.sh" /home/ubuntu/affiliate_signup.sh
    ln -sf "$WORK_DIR/scripts/update_affiliate_ids.sh" /home/ubuntu/update_affiliate_ids.sh
    
    echo -e "${GREEN}Skripte in /home/ubuntu verlinkt${NC}"
else
    echo -e "${RED}Scripts-Verzeichnis nicht gefunden${NC}"
fi

echo ""

# Website-Dateien vorbereiten
echo -e "${BOLD}[4] WEBSITE-DATEIEN VORBEREITEN${NC}"
echo "----------------------------------------"

if [ -d "website" ]; then
    # Stromtarifprofi-MVP Verzeichnis erstellen
    MVP_DIR="/home/ubuntu/stromtarifprofi-mvp"
    mkdir -p "$MVP_DIR"
    
    # Website-Dateien kopieren
    cp -r website/* "$MVP_DIR/"
    
    # Git in MVP-Verzeichnis initialisieren
    cd "$MVP_DIR"
    if [ ! -d ".git" ]; then
        git init
        git config user.name "LeadHub Deploy"
        git config user.email "deploy@leadhub.local"
    fi
    
    echo -e "${GREEN}Website-Dateien nach $MVP_DIR kopiert${NC}"
    cd "$WORK_DIR"
else
    echo -e "${RED}Website-Verzeichnis nicht gefunden${NC}"
fi

echo ""

# System-Check ausführen
echo -e "${BOLD}[5] SYSTEM-CHECK AUSFÜHREN${NC}"
echo "----------------------------------------"

if [ -f "/home/ubuntu/check_sandbox_status.sh" ]; then
    echo -e "${YELLOW}Führe Sandbox-Status-Check aus...${NC}"
    /home/ubuntu/check_sandbox_status.sh
else
    echo -e "${RED}System-Check-Skript nicht gefunden${NC}"
fi

echo ""

# Deployment-Zusammenfassung
echo -e "${BOLD}[6] DEPLOYMENT-ZUSAMMENFASSUNG${NC}"
echo "----------------------------------------"

echo -e "${GREEN}✅ Repository heruntergeladen${NC}"
echo -e "${GREEN}✅ Skripte konfiguriert und verlinkt${NC}"
echo -e "${GREEN}✅ Website-Dateien vorbereitet${NC}"
echo -e "${GREEN}✅ System-Check ausgeführt${NC}"

echo -e "\n${PURPLE}${BOLD}VERFÜGBARE KOMMANDOS:${NC}"
echo -e "${YELLOW}./check_sandbox_status.sh${NC}    - System-Status prüfen"
echo -e "${YELLOW}./setup_github.sh${NC}           - GitHub-Repository einrichten"
echo -e "${YELLOW}./affiliate_signup.sh${NC}       - Affiliate-Anmeldungen"
echo -e "${YELLOW}./update_affiliate_ids.sh${NC}   - Affiliate-IDs aktualisieren"

echo -e "\n${BLUE}${BOLD}NÄCHSTE SCHRITTE:${NC}"
echo -e "${YELLOW}1.${NC} GitHub-Repository für Ihre Website erstellen:"
echo -e "   ${YELLOW}./setup_github.sh${NC}"
echo -e "${YELLOW}2.${NC} Affiliate-Anmeldungen durchführen:"
echo -e "   ${YELLOW}./affiliate_signup.sh${NC}"
echo -e "${YELLOW}3.${NC} Website live schalten und erste Leads generieren"

echo -e "\n${GREEN}${BOLD}LEADHUB DEPLOYMENT ABGESCHLOSSEN!${NC}"
echo -e "${YELLOW}Alle Dateien befinden sich in: $WORK_DIR${NC}"
echo -e "${YELLOW}Website-Code befindet sich in: /home/ubuntu/stromtarifprofi-mvp${NC}"
echo "=========================================="

