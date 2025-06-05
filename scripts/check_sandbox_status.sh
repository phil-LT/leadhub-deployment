#!/bin/bash

# ===================================================
# SANDBOX STATUS CHECK SCRIPT
# ===================================================
# Überprüft den Status aller Komponenten in der Sandbox
# Identifiziert fehlende Komponenten und nächste Schritte
# ===================================================

# Farbdefinitionen für bessere Lesbarkeit
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Banner anzeigen
echo -e "${BLUE}${BOLD}"
echo "╔═════════════════════════════════════════════════════════════╗"
echo "║                LEADHUB SANDBOX STATUS CHECK                 ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Systemstatus prüfen
echo -e "${BOLD}[1] SYSTEM STATUS${NC}"
echo "----------------------------------------"

# Uptime prüfen
echo -n "Uptime: "
uptime -p
echo ""

# Speichernutzung prüfen
echo "Speichernutzung:"
free -h | grep -v total
echo ""

# Festplattennutzung prüfen
echo "Festplattennutzung:"
df -h / | grep -v Filesystem
echo ""

# Installierte Pakete prüfen
echo -e "${BOLD}[2] INSTALLIERTE SYSTEM-TOOLS${NC}"
echo "----------------------------------------"

# Array mit zu prüfenden Paketen
packages=("git" "curl" "wget" "net-tools" "lsb-release" "htop" "python3" "pip3" "node" "npm")

# Pakete prüfen
for pkg in "${packages[@]}"; do
    if command -v $pkg &> /dev/null; then
        echo -e "$pkg: ${GREEN}✓ Installiert${NC}"
        if [ "$pkg" = "python3" ]; then
            echo -e "   Version: $(python3 --version)"
        elif [ "$pkg" = "node" ]; then
            echo -e "   Version: $(node --version)"
        elif [ "$pkg" = "npm" ]; then
            echo -e "   Version: $(npm --version)"
        fi
    else
        echo -e "$pkg: ${RED}✗ Nicht installiert${NC}"
    fi
done
echo ""

# Git-Konfiguration prüfen
echo -e "${BOLD}[3] GIT-KONFIGURATION${NC}"
echo "----------------------------------------"
if command -v git &> /dev/null; then
    if git config --get user.name &> /dev/null; then
        echo -e "Git User Name: ${GREEN}$(git config --get user.name)${NC}"
    else
        echo -e "Git User Name: ${RED}Nicht konfiguriert${NC}"
    fi
    
    if git config --get user.email &> /dev/null; then
        echo -e "Git User Email: ${GREEN}$(git config --get user.email)${NC}"
    else
        echo -e "Git User Email: ${RED}Nicht konfiguriert${NC}"
    fi
else
    echo -e "${RED}Git ist nicht installiert${NC}"
fi
echo ""

# Projektverzeichnisse prüfen
echo -e "${BOLD}[4] PROJEKT-VERZEICHNISSE${NC}"
echo "----------------------------------------"
directories=("/home/ubuntu/stromtarifprofi-mvp" "/home/ubuntu/upload")

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "$dir: ${GREEN}✓ Existiert${NC}"
        # Anzahl der Dateien im Verzeichnis
        file_count=$(find "$dir" -type f | wc -l)
        echo -e "   Dateien: $file_count"
    else
        echo -e "$dir: ${RED}✗ Existiert nicht${NC}"
    fi
done
echo ""

# Stromtarifprofi-MVP Status prüfen
echo -e "${BOLD}[5] STROMTARIFPROFI-MVP STATUS${NC}"
echo "----------------------------------------"
if [ -d "/home/ubuntu/stromtarifprofi-mvp" ]; then
    # Git-Status prüfen
    cd /home/ubuntu/stromtarifprofi-mvp
    
    if [ -d ".git" ]; then
        echo -e "Git Repository: ${GREEN}✓ Initialisiert${NC}"
        
        # Commit-Status
        commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        echo -e "Commits: $commit_count"
        
        # Untracked/Modified Files
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            echo -e "Änderungen: ${YELLOW}Nicht committed${NC}"
        else
            echo -e "Änderungen: ${GREEN}Alle committed${NC}"
        fi
        
        # Remote-Status
        if git remote -v 2>/dev/null | grep -q origin; then
            echo -e "Remote: ${GREEN}✓ Konfiguriert${NC}"
            echo -e "   $(git remote -v | head -n1)"
        else
            echo -e "Remote: ${RED}✗ Nicht konfiguriert${NC}"
        fi
    else
        echo -e "Git Repository: ${RED}✗ Nicht initialisiert${NC}"
    fi
    
    # Dateien prüfen
    key_files=("index.html" "styles.css" "affiliate-router.js" "form-handler.js" "analytics.js" ".github/workflows/deploy.yml")
    
    echo -e "\nKern-Dateien:"
    for file in "${key_files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "$file: ${GREEN}✓ Vorhanden${NC}"
        else
            echo -e "$file: ${RED}✗ Fehlt${NC}"
        fi
    done
else
    echo -e "${RED}Stromtarifprofi-MVP Verzeichnis existiert nicht${NC}"
fi
echo ""

# Nächste Schritte identifizieren
echo -e "${BOLD}[6] NÄCHSTE SCHRITTE${NC}"
echo "----------------------------------------"

# Array für nächste Schritte
declare -a next_steps

# MVP-Verzeichnis prüfen
if [ ! -d "/home/ubuntu/stromtarifprofi-mvp" ]; then
    next_steps+=("MVP-Projekt erstellen")
fi

# Git-Remote prüfen
if [ -d "/home/ubuntu/stromtarifprofi-mvp/.git" ]; then
    if ! git -C /home/ubuntu/stromtarifprofi-mvp remote -v 2>/dev/null | grep -q origin; then
        next_steps+=("GitHub-Repository erstellen und Remote hinzufügen")
    fi
fi

# Ausgabe der nächsten Schritte
if [ ${#next_steps[@]} -eq 0 ]; then
    echo -e "${GREEN}Alle Komponenten sind bereit für das Deployment!${NC}"
else
    echo -e "${YELLOW}Folgende Schritte sind erforderlich:${NC}"
    for i in "${!next_steps[@]}"; do
        echo -e "${YELLOW}$(($i+1)).${NC} ${next_steps[$i]}"
    done
fi

echo -e "\n${PURPLE}${BOLD}NÄCHSTE DEPLOYMENT-SCHRITTE:${NC}"
if [ -d "/home/ubuntu/stromtarifprofi-mvp" ]; then
    echo -e "${GREEN}1. GitHub-Repository erstellen${NC}"
    echo -e "${GREEN}2. Code hochladen mit 'setup_github.sh'${NC}"
    echo -e "${GREEN}3. GitHub Pages aktivieren${NC}"
    echo -e "${GREEN}4. Domain verbinden${NC}"
    echo -e "${GREEN}5. Affiliate-Anmeldungen starten${NC}"
else
    echo -e "${YELLOW}1. MVP-Projekt erstellen${NC}"
    echo -e "${YELLOW}2. GitHub-Repository erstellen${NC}"
    echo -e "${YELLOW}3. Code hochladen${NC}"
    echo -e "${YELLOW}4. GitHub Pages aktivieren${NC}"
    echo -e "${YELLOW}5. Domain verbinden${NC}"
    echo -e "${YELLOW}6. Affiliate-Anmeldungen starten${NC}"
fi

echo -e "\n${BLUE}${BOLD}SANDBOX CHECK ABGESCHLOSSEN${NC}"
echo "=========================================="

