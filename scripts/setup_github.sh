#!/bin/bash

# ===================================================
# GITHUB SETUP SCRIPT
# ===================================================
# Richtet GitHub-Repository für stromtarifprofi-mvp ein
# Konfiguriert Git, erstellt Repository und pusht Code
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
echo "║                LEADHUB GITHUB SETUP SCRIPT                  ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Prüfen, ob das Projekt-Verzeichnis existiert
if [ ! -d "/home/ubuntu/stromtarifprofi-mvp" ]; then
    echo -e "${RED}Das Verzeichnis /home/ubuntu/stromtarifprofi-mvp existiert nicht.${NC}"
    echo -e "${YELLOW}Erstelle MVP-Projekt...${NC}"
    
    # MVP-Projekt erstellen
    mkdir -p /home/ubuntu/stromtarifprofi-mvp
    cd /home/ubuntu/stromtarifprofi-mvp
    
    # Git initialisieren
    git init
    
    echo -e "${GREEN}MVP-Projekt-Verzeichnis erstellt.${NC}"
    echo -e "${YELLOW}Hinweis: Sie müssen noch die MVP-Dateien erstellen.${NC}"
else
    cd /home/ubuntu/stromtarifprofi-mvp
fi

# 1. Git-Konfiguration
echo -e "${BOLD}[1] GIT-KONFIGURATION${NC}"
echo "----------------------------------------"

# Git-User-Konfiguration abfragen
read -p "Git User Name eingeben: " git_user_name
read -p "Git User Email eingeben: " git_user_email

# Git-User konfigurieren
git config user.name "$git_user_name"
git config user.email "$git_user_email"

echo -e "${GREEN}Git-Benutzer konfiguriert:${NC}"
echo "Name: $git_user_name"
echo "Email: $git_user_email"
echo ""

# 2. GitHub-Repository-Informationen
echo -e "${BOLD}[2] GITHUB-REPOSITORY-INFORMATIONEN${NC}"
echo "----------------------------------------"

read -p "GitHub-Benutzername eingeben: " github_username
read -p "Repository-Name eingeben [stromtarifprofi-mvp]: " repo_name

# Standardwert setzen, wenn kein Repository-Name eingegeben wurde
if [ -z "$repo_name" ]; then
    repo_name="stromtarifprofi-mvp"
fi

echo -e "${GREEN}Repository-Informationen:${NC}"
echo "GitHub-Benutzername: $github_username"
echo "Repository-Name: $repo_name"
echo ""

# 3. GitHub-Repository erstellen
echo -e "${BOLD}[3] GITHUB-REPOSITORY ERSTELLEN${NC}"
echo "----------------------------------------"
echo -e "${YELLOW}Hinweis: Sie müssen das Repository manuell auf GitHub erstellen.${NC}"
echo "Bitte führen Sie folgende Schritte aus:"
echo "1. Besuchen Sie https://github.com/new"
echo "2. Geben Sie '$repo_name' als Repository-Namen ein"
echo "3. Wählen Sie 'Public' oder 'Private' nach Bedarf"
echo "4. Klicken Sie auf 'Create repository'"
echo "5. WICHTIG: Erstellen Sie das Repository LEER (ohne README, .gitignore, etc.)"

read -p "Haben Sie das Repository erstellt? (j/n): " repo_created

if [ "$repo_created" != "j" ] && [ "$repo_created" != "J" ]; then
    echo -e "${RED}Repository-Erstellung abgebrochen. Bitte erstellen Sie das Repository und führen Sie das Skript erneut aus.${NC}"
    exit 1
fi

# 4. Remote hinzufügen
echo -e "\n${BOLD}[4] REMOTE HINZUFÜGEN${NC}"
echo "----------------------------------------"

# Prüfen, ob bereits ein Remote existiert
if git remote -v | grep -q origin; then
    echo -e "${YELLOW}Ein Remote 'origin' existiert bereits. Wird entfernt...${NC}"
    git remote remove origin
fi

# Remote hinzufügen
git remote add origin "https://github.com/$github_username/$repo_name.git"
echo -e "${GREEN}Remote 'origin' hinzugefügt:${NC}"
git remote -v
echo ""

# 5. Code committen (falls noch nicht geschehen)
echo -e "${BOLD}[5] CODE COMMITTEN${NC}"
echo "----------------------------------------"

# Prüfen, ob es Dateien gibt
if [ -z "$(ls -A)" ]; then
    echo -e "${YELLOW}Verzeichnis ist leer. Erstelle README.md...${NC}"
    echo "# Stromtarifprofi MVP" > README.md
    echo "MVP für Lead-Generierung im Strommarkt" >> README.md
fi

# Prüfen, ob es ungespeicherte Änderungen gibt
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo -e "${YELLOW}Es gibt ungespeicherte Änderungen. Diese werden jetzt committed.${NC}"
    git add .
    git commit -m "Initial commit: MVP setup"
elif [ "$(git rev-list --count HEAD 2>/dev/null || echo 0)" -eq 0 ]; then
    echo -e "${YELLOW}Erstelle ersten Commit...${NC}"
    git add .
    git commit -m "Initial commit: MVP setup"
fi

# 6. Code pushen
echo -e "${BOLD}[6] CODE PUSHEN${NC}"
echo "----------------------------------------"

# Branch-Namen ermitteln (main oder master)
current_branch=$(git branch --show-current)
if [ -z "$current_branch" ]; then
    current_branch="main"  # Standardwert, falls kein Branch existiert
    git checkout -b main
fi

echo -e "${YELLOW}Möchten Sie den Code jetzt zu GitHub pushen?${NC}"
echo "Dies erfordert Ihre GitHub-Anmeldedaten."
read -p "Fortfahren? (j/n): " push_code

if [ "$push_code" = "j" ] || [ "$push_code" = "J" ]; then
    echo -e "${YELLOW}Pushe Code zu GitHub...${NC}"
    git push -u origin $current_branch
    
    push_status=$?
    if [ $push_status -eq 0 ]; then
        echo -e "${GREEN}Code erfolgreich zu GitHub gepusht!${NC}"
    else
        echo -e "${RED}Fehler beim Pushen des Codes. Bitte überprüfen Sie Ihre Anmeldedaten und Berechtigungen.${NC}"
        echo "Sie können den Code später manuell pushen mit:"
        echo "cd /home/ubuntu/stromtarifprofi-mvp && git push -u origin $current_branch"
    fi
else
    echo -e "${YELLOW}Push übersprungen. Sie können den Code später manuell pushen mit:${NC}"
    echo "cd /home/ubuntu/stromtarifprofi-mvp && git push -u origin $current_branch"
fi

# 7. GitHub Pages Anleitung
echo -e "\n${BOLD}[7] GITHUB PAGES EINRICHTEN${NC}"
echo "----------------------------------------"
echo -e "${YELLOW}Anleitung zum Einrichten von GitHub Pages:${NC}"
echo "1. Besuchen Sie https://github.com/$github_username/$repo_name/settings/pages"
echo "2. Unter 'Source', wählen Sie 'Deploy from a branch'"
echo "3. Wählen Sie 'main' als Branch"
echo "4. Wählen Sie '/ (root)' als Folder"
echo "5. Klicken Sie 'Save'"
echo "6. Ihre Website wird unter https://$github_username.github.io/$repo_name/ verfügbar sein"

echo -e "\n${GREEN}${BOLD}GITHUB SETUP ABGESCHLOSSEN!${NC}"
echo "=========================================="
echo -e "${YELLOW}Nächste Schritte:${NC}"
echo "1. GitHub Pages aktivieren (siehe Anleitung oben)"
echo "2. Domain verbinden (optional)"
echo "3. Affiliate-Anmeldungen starten"
echo "4. Erste Test-Leads generieren"
echo ""

