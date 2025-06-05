#!/bin/bash

# ===================================================
# AFFILIATE ANMELDUNG SCRIPT
# ===================================================
# Führt durch den Anmeldeprozess bei allen Affiliate-Partnern
# Sammelt alle erforderlichen Informationen und IDs
# ===================================================

# Farbdefinitionen
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
echo "║              AFFILIATE ANMELDUNG SCRIPT                     ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Affiliate-IDs-Datei erstellen
affiliate_ids_file="/home/ubuntu/affiliate_ids.txt"

echo -e "${BOLD}[1] VORAUSSETZUNGEN PRÜFEN${NC}"
echo "----------------------------------------"

# Website-URL prüfen
echo -e "${YELLOW}Ihre Website-URL (für Affiliate-Anmeldungen):${NC}"
read -p "Website-URL eingeben (z.B. https://stromtarifprofi.de): " website_url

if [ -z "$website_url" ]; then
    echo -e "${RED}Website-URL ist erforderlich für Affiliate-Anmeldungen.${NC}"
    exit 1
fi

# Gewerbeanmeldung prüfen
echo -e "\n${YELLOW}Gewerbeanmeldung:${NC}"
read -p "Haben Sie eine Gewerbeanmeldung? (j/n): " gewerbe_anmeldung

if [ "$gewerbe_anmeldung" != "j" ] && [ "$gewerbe_anmeldung" != "J" ]; then
    echo -e "${RED}WARNUNG: Eine Gewerbeanmeldung ist für alle Affiliate-Programme erforderlich.${NC}"
    echo "Bitte melden Sie ein Gewerbe an, bevor Sie sich bei den Affiliate-Programmen anmelden."
    read -p "Trotzdem fortfahren? (j/n): " continue_anyway
    if [ "$continue_anyway" != "j" ] && [ "$continue_anyway" != "J" ]; then
        exit 1
    fi
fi

# Impressum und Datenschutz prüfen
echo -e "\n${YELLOW}Rechtliche Anforderungen:${NC}"
read -p "Haben Sie ein vollständiges Impressum auf Ihrer Website? (j/n): " impressum
read -p "Haben Sie eine DSGVO-konforme Datenschutzerklärung? (j/n): " datenschutz

if [ "$impressum" != "j" ] || [ "$datenschutz" != "j" ]; then
    echo -e "${RED}WARNUNG: Impressum und Datenschutzerklärung sind rechtlich erforderlich.${NC}"
fi

echo -e "\n${BOLD}[2] CHECK24 PARTNERPROGRAMM${NC}"
echo "----------------------------------------"
echo -e "${YELLOW}CHECK24 ist der empfohlene Hauptpartner (€20 pro Lead, stornofrei)${NC}"
echo ""
echo "Anmeldung unter: https://www.check24-partnerprogramm.de/"
echo ""
echo "Erforderliche Informationen für die Anmeldung:"
echo "- Website-URL: $website_url"
echo "- Geschätzte monatliche Leads: 50-200"
echo "- Zielgruppe: Deutsche Haushalte"
echo "- Traffic-Quellen: SEO, SEA, Social Media"
echo ""
echo -e "${YELLOW}Bewerbungstext-Vorlage:${NC}"
echo "\"Wir betreiben ein unabhängiges Stromvergleichsportal für deutsche Haushalte."
echo "Unser Fokus liegt auf qualifizierten Leads durch gezielte Online-Marketing-Maßnahmen."
echo "Wir erwarten 50-200 qualifizierte Leads pro Monat und haben bereits Erfahrung"
echo "im Affiliate-Marketing. Unsere Website ist DSGVO-konform und verfügt über"
echo "alle erforderlichen rechtlichen Angaben.\""
echo ""
read -p "Haben Sie sich bei CHECK24 angemeldet? (j/n): " check24_anmeldung

if [ "$check24_anmeldung" = "j" ] || [ "$check24_anmeldung" = "J" ]; then
    read -p "CHECK24 Partner-ID eingeben (falls bereits erhalten): " check24_id
    if [ -n "$check24_id" ]; then
        echo "CHECK24_PARTNER_ID=$check24_id" >> $affiliate_ids_file
        echo -e "${GREEN}CHECK24 Partner-ID gespeichert: $check24_id${NC}"
    else
        echo "CHECK24_PARTNER_ID=PENDING" >> $affiliate_ids_file
        echo -e "${YELLOW}CHECK24 Partner-ID als ausstehend markiert${NC}"
    fi
else
    echo "CHECK24_PARTNER_ID=NOT_APPLIED" >> $affiliate_ids_file
    echo -e "${RED}CHECK24 Anmeldung als nicht durchgeführt markiert${NC}"
fi

echo -e "\n${BOLD}[3] VERIVOX PARTNERPROGRAMM${NC}"
echo "----------------------------------------"
echo -e "${YELLOW}VERIVOX als Backup-Partner (€20 pro Vertragsabschluss)${NC}"
echo ""
echo "Anmeldung unter: https://www.verivox.de/partnerprogramm/"
echo ""
echo "Erforderliche Informationen:"
echo "- Website-URL: $website_url"
echo "- Geschätzte monatliche Abschlüsse: 20-100"
echo "- Zielgruppe: Preisbewusste deutsche Haushalte"
echo ""
echo -e "${YELLOW}Bewerbungstext-Vorlage:${NC}"
echo "\"Unser Stromvergleichsportal richtet sich an preisbewusste deutsche Haushalte."
echo "Wir generieren qualifizierte Leads durch SEO und SEA-Maßnahmen und erwarten"
echo "20-100 Vertragsabschlüsse pro Monat. Unsere Website ist vollständig DSGVO-konform"
echo "und verfügt über alle rechtlichen Angaben.\""
echo ""
read -p "Haben Sie sich bei VERIVOX angemeldet? (j/n): " verivox_anmeldung

if [ "$verivox_anmeldung" = "j" ] || [ "$verivox_anmeldung" = "J" ]; then
    read -p "VERIVOX Partner-ID eingeben (falls bereits erhalten): " verivox_id
    if [ -n "$verivox_id" ]; then
        echo "VERIVOX_PARTNER_ID=$verivox_id" >> $affiliate_ids_file
        echo -e "${GREEN}VERIVOX Partner-ID gespeichert: $verivox_id${NC}"
    else
        echo "VERIVOX_PARTNER_ID=PENDING" >> $affiliate_ids_file
        echo -e "${YELLOW}VERIVOX Partner-ID als ausstehend markiert${NC}"
    fi
else
    echo "VERIVOX_PARTNER_ID=NOT_APPLIED" >> $affiliate_ids_file
    echo -e "${RED}VERIVOX Anmeldung als nicht durchgeführt markiert${NC}"
fi

echo -e "\n${BOLD}[4] RABOT ENERGY (AWIN) PREMIUM-PARTNER${NC}"
echo "----------------------------------------"
echo -e "${YELLOW}RABOT Energy für Premium-Leads (€30-80 pro Vertragsabschluss)${NC}"
echo ""
echo "Schritt 1: AWIN-Publisher-Account erstellen"
echo "Anmeldung unter: https://ui.awin.com/affiliate-signup"
echo ""
echo "Schritt 2: Bei RABOT Energy bewerben"
echo "Merchant-Profil: https://ui.awin.com/merchant-profile/70752"
echo ""
echo "Erforderliche Informationen:"
echo "- Website-URL: $website_url"
echo "- Fokus: E-Mobilität und Smart Energy"
echo "- Zielgruppe: Tech-affine Haushalte mit E-Auto/Smart Home"
echo "- Geschätzte monatliche Abschlüsse: 10-50"
echo ""
echo -e "${YELLOW}Bewerbungstext-Vorlage für RABOT Energy:${NC}"
echo "\"Unser Stromvergleichsportal hat einen besonderen Fokus auf E-Mobilität"
echo "und Smart Energy Lösungen. Wir erreichen tech-affine Haushalte mit E-Auto"
echo "und Smart Home Interesse. Durch gezielte Kampagnen erwarten wir 10-50"
echo "qualifizierte Premium-Abschlüsse pro Monat.\""
echo ""
read -p "Haben Sie einen AWIN-Account erstellt? (j/n): " awin_account

if [ "$awin_account" = "j" ] || [ "$awin_account" = "J" ]; then
    read -p "AWIN Affiliate-ID eingeben (falls bereits erhalten): " awin_id
    if [ -n "$awin_id" ]; then
        echo "AWIN_AFFILIATE_ID=$awin_id" >> $affiliate_ids_file
        echo -e "${GREEN}AWIN Affiliate-ID gespeichert: $awin_id${NC}"
    else
        echo "AWIN_AFFILIATE_ID=PENDING" >> $affiliate_ids_file
        echo -e "${YELLOW}AWIN Affiliate-ID als ausstehend markiert${NC}"
    fi
    
    read -p "Haben Sie sich bei RABOT Energy beworben? (j/n): " rabot_bewerbung
    if [ "$rabot_bewerbung" = "j" ] || [ "$rabot_bewerbung" = "J" ]; then
        echo "RABOT_ENERGY_STATUS=APPLIED" >> $affiliate_ids_file
        echo -e "${GREEN}RABOT Energy Bewerbung als durchgeführt markiert${NC}"
    else
        echo "RABOT_ENERGY_STATUS=NOT_APPLIED" >> $affiliate_ids_file
        echo -e "${YELLOW}RABOT Energy Bewerbung als ausstehend markiert${NC}"
    fi
else
    echo "AWIN_AFFILIATE_ID=NOT_APPLIED" >> $affiliate_ids_file
    echo "RABOT_ENERGY_STATUS=NOT_APPLIED" >> $affiliate_ids_file
    echo -e "${RED}AWIN/RABOT Energy Anmeldung als nicht durchgeführt markiert${NC}"
fi

echo -e "\n${BOLD}[5] ZUSAMMENFASSUNG${NC}"
echo "----------------------------------------"
echo -e "${GREEN}Affiliate-IDs und Konfiguration gespeichert in: $affiliate_ids_file${NC}"
echo ""
echo "Inhalt der Datei:"
cat $affiliate_ids_file
echo ""

echo -e "${YELLOW}Nächste Schritte:${NC}"
echo "1. Warten Sie auf die Freischaltung der Affiliate-Programme (1-7 Tage)"
echo "2. Aktualisieren Sie die IDs in der Datei, sobald Sie sie erhalten"
echo "3. Integrieren Sie die IDs in Ihre Website"
echo "4. Testen Sie die Affiliate-Links"
echo "5. Starten Sie mit der Lead-Generierung"

echo -e "\n${PURPLE}${BOLD}WICHTIGE HINWEISE:${NC}"
echo "- CHECK24: Freischaltung meist innerhalb 1-3 Tagen"
echo "- VERIVOX: Freischaltung meist innerhalb 3-7 Tagen"
echo "- RABOT Energy: Manuelle Prüfung, kann 7-14 Tage dauern"
echo "- Alle Programme erfordern eine vollständige Website mit Impressum/Datenschutz"

echo -e "\n${GREEN}${BOLD}AFFILIATE ANMELDUNG ABGESCHLOSSEN!${NC}"
echo "=========================================="

