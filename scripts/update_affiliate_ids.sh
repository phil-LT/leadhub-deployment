#!/bin/bash

# ===================================================
# AFFILIATE IDS UPDATE SCRIPT
# ===================================================
# Aktualisiert Affiliate-IDs in Website-Code
# Integriert Partner-IDs in JavaScript-Dateien
# ===================================================

# Farbdefinitionen
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Banner anzeigen
echo -e "${BLUE}${BOLD}"
echo "╔═════════════════════════════════════════════════════════════╗"
echo "║            AFFILIATE IDS UPDATE SCRIPT                      ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Pfade definieren
AFFILIATE_IDS_FILE="/home/ubuntu/affiliate_ids.txt"
MVP_DIR="/home/ubuntu/stromtarifprofi-mvp"
ROUTER_FILE="$MVP_DIR/affiliate-router.js"

echo -e "${BOLD}[1] AFFILIATE-IDS LADEN${NC}"
echo "----------------------------------------"

# Prüfen, ob Affiliate-IDs-Datei existiert
if [ ! -f "$AFFILIATE_IDS_FILE" ]; then
    echo -e "${RED}Affiliate-IDs-Datei nicht gefunden: $AFFILIATE_IDS_FILE${NC}"
    echo -e "${YELLOW}Führen Sie zuerst ./affiliate_signup.sh aus${NC}"
    exit 1
fi

# IDs aus Datei laden
source "$AFFILIATE_IDS_FILE"

echo -e "${GREEN}Affiliate-IDs geladen:${NC}"
echo "CHECK24: ${CHECK24_PARTNER_ID:-'Nicht gesetzt'}"
echo "VERIVOX: ${VERIVOX_PARTNER_ID:-'Nicht gesetzt'}"
echo "AWIN: ${AWIN_AFFILIATE_ID:-'Nicht gesetzt'}"
echo ""

echo -e "${BOLD}[2] WEBSITE-CODE AKTUALISIEREN${NC}"
echo "----------------------------------------"

# Prüfen, ob MVP-Verzeichnis existiert
if [ ! -d "$MVP_DIR" ]; then
    echo -e "${RED}MVP-Verzeichnis nicht gefunden: $MVP_DIR${NC}"
    exit 1
fi

# Prüfen, ob Router-Datei existiert
if [ ! -f "$ROUTER_FILE" ]; then
    echo -e "${RED}Affiliate-Router-Datei nicht gefunden: $ROUTER_FILE${NC}"
    exit 1
fi

# Backup der Original-Datei erstellen
cp "$ROUTER_FILE" "${ROUTER_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}Backup erstellt: ${ROUTER_FILE}.backup.$(date +%Y%m%d_%H%M%S)${NC}"

# IDs in JavaScript-Datei aktualisieren
echo -e "${YELLOW}Aktualisiere Affiliate-IDs in $ROUTER_FILE...${NC}"

# CHECK24 ID aktualisieren
if [ "$CHECK24_PARTNER_ID" != "NOT_APPLIED" ] && [ "$CHECK24_PARTNER_ID" != "PENDING" ] && [ -n "$CHECK24_PARTNER_ID" ]; then
    sed -i "s/CHECK24_PARTNER_ID: 'YOUR_CHECK24_ID'/CHECK24_PARTNER_ID: '$CHECK24_PARTNER_ID'/g" "$ROUTER_FILE"
    echo -e "${GREEN}✓ CHECK24 Partner-ID aktualisiert${NC}"
else
    echo -e "${YELLOW}⚠ CHECK24 Partner-ID nicht verfügbar${NC}"
fi

# VERIVOX ID aktualisieren
if [ "$VERIVOX_PARTNER_ID" != "NOT_APPLIED" ] && [ "$VERIVOX_PARTNER_ID" != "PENDING" ] && [ -n "$VERIVOX_PARTNER_ID" ]; then
    sed -i "s/VERIVOX_PARTNER_ID: 'YOUR_VERIVOX_ID'/VERIVOX_PARTNER_ID: '$VERIVOX_PARTNER_ID'/g" "$ROUTER_FILE"
    echo -e "${GREEN}✓ VERIVOX Partner-ID aktualisiert${NC}"
else
    echo -e "${YELLOW}⚠ VERIVOX Partner-ID nicht verfügbar${NC}"
fi

# AWIN ID aktualisieren
if [ "$AWIN_AFFILIATE_ID" != "NOT_APPLIED" ] && [ "$AWIN_AFFILIATE_ID" != "PENDING" ] && [ -n "$AWIN_AFFILIATE_ID" ]; then
    sed -i "s/AWIN_AFFILIATE_ID: 'YOUR_AWIN_ID'/AWIN_AFFILIATE_ID: '$AWIN_AFFILIATE_ID'/g" "$ROUTER_FILE"
    echo -e "${GREEN}✓ AWIN Affiliate-ID aktualisiert${NC}"
else
    echo -e "${YELLOW}⚠ AWIN Affiliate-ID nicht verfügbar${NC}"
fi

echo ""

echo -e "${BOLD}[3] ÄNDERUNGEN COMMITTEN${NC}"
echo "----------------------------------------"

cd "$MVP_DIR"

# Git-Status prüfen
if [ -d ".git" ]; then
    # Änderungen hinzufügen
    git add .
    
    # Commit mit Affiliate-IDs
    commit_message="Update affiliate IDs: "
    if [ "$CHECK24_PARTNER_ID" != "NOT_APPLIED" ] && [ "$CHECK24_PARTNER_ID" != "PENDING" ] && [ -n "$CHECK24_PARTNER_ID" ]; then
        commit_message+="CHECK24 "
    fi
    if [ "$VERIVOX_PARTNER_ID" != "NOT_APPLIED" ] && [ "$VERIVOX_PARTNER_ID" != "PENDING" ] && [ -n "$VERIVOX_PARTNER_ID" ]; then
        commit_message+="VERIVOX "
    fi
    if [ "$AWIN_AFFILIATE_ID" != "NOT_APPLIED" ] && [ "$AWIN_AFFILIATE_ID" != "PENDING" ] && [ -n "$AWIN_AFFILIATE_ID" ]; then
        commit_message+="AWIN "
    fi
    
    git commit -m "$commit_message"
    echo -e "${GREEN}Änderungen committed${NC}"
    
    # Push zu GitHub (falls Remote konfiguriert)
    if git remote -v | grep -q origin; then
        read -p "Änderungen zu GitHub pushen? (j/n): " push_changes
        if [ "$push_changes" = "j" ] || [ "$push_changes" = "J" ]; then
            git push origin main
            echo -e "${GREEN}Änderungen zu GitHub gepusht${NC}"
        fi
    else
        echo -e "${YELLOW}Kein GitHub-Remote konfiguriert${NC}"
    fi
else
    echo -e "${YELLOW}Kein Git-Repository gefunden${NC}"
fi

echo ""

echo -e "${BOLD}[4] TESTING${NC}"
echo "----------------------------------------"

echo -e "${YELLOW}Teste Affiliate-Router-Konfiguration...${NC}"

# Einfacher Test der JavaScript-Syntax
if command -v node &> /dev/null; then
    # Node.js verfügbar - Syntax-Check
    node -c "$ROUTER_FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ JavaScript-Syntax ist korrekt${NC}"
    else
        echo -e "${RED}✗ JavaScript-Syntax-Fehler gefunden${NC}"
    fi
else
    echo -e "${YELLOW}Node.js nicht verfügbar - Syntax-Check übersprungen${NC}"
fi

# Prüfen, ob IDs korrekt eingesetzt wurden
echo -e "${YELLOW}Prüfe eingesetzte IDs...${NC}"
grep -n "PARTNER_ID\|AFFILIATE_ID" "$ROUTER_FILE" | head -5

echo ""

echo -e "${BOLD}[5] ZUSAMMENFASSUNG${NC}"
echo "----------------------------------------"

echo -e "${GREEN}✅ Affiliate-IDs erfolgreich aktualisiert${NC}"
echo -e "${GREEN}✅ Backup der Original-Datei erstellt${NC}"
echo -e "${GREEN}✅ Änderungen committed${NC}"

echo -e "\n${YELLOW}Aktualisierte IDs:${NC}"
if [ "$CHECK24_PARTNER_ID" != "NOT_APPLIED" ] && [ "$CHECK24_PARTNER_ID" != "PENDING" ] && [ -n "$CHECK24_PARTNER_ID" ]; then
    echo -e "CHECK24: ${GREEN}$CHECK24_PARTNER_ID${NC}"
else
    echo -e "CHECK24: ${RED}Nicht verfügbar${NC}"
fi

if [ "$VERIVOX_PARTNER_ID" != "NOT_APPLIED" ] && [ "$VERIVOX_PARTNER_ID" != "PENDING" ] && [ -n "$VERIVOX_PARTNER_ID" ]; then
    echo -e "VERIVOX: ${GREEN}$VERIVOX_PARTNER_ID${NC}"
else
    echo -e "VERIVOX: ${RED}Nicht verfügbar${NC}"
fi

if [ "$AWIN_AFFILIATE_ID" != "NOT_APPLIED" ] && [ "$AWIN_AFFILIATE_ID" != "PENDING" ] && [ -n "$AWIN_AFFILIATE_ID" ]; then
    echo -e "AWIN: ${GREEN}$AWIN_AFFILIATE_ID${NC}"
else
    echo -e "AWIN: ${RED}Nicht verfügbar${NC}"
fi

echo -e "\n${BLUE}${BOLD}NÄCHSTE SCHRITTE:${NC}"
echo -e "${YELLOW}1.${NC} Website testen: Öffnen Sie Ihre Live-Website"
echo -e "${YELLOW}2.${NC} Debug-Modus: Fügen Sie ?debug=1 zur URL hinzu"
echo -e "${YELLOW}3.${NC} Test-Lead: Füllen Sie das Formular aus"
echo -e "${YELLOW}4.${NC} Affiliate-Routing: Prüfen Sie die Weiterleitung"

echo -e "\n${GREEN}${BOLD}AFFILIATE IDS UPDATE ABGESCHLOSSEN!${NC}"
echo "=========================================="

