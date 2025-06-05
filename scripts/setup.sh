#!/bin/bash
# LeadHub Professional API Setup
# Version: 1.0

# Farben für Ausgaben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Konfiguration
API_PORT=8000
GRADIO_PORT=7860
INSTALL_DIR="/home/ubuntu/leadhub_api"
SERVICE_NAME="leadhub_api"
DB_PATH="leads.db"

# Funktion zum Anzeigen von Fortschritt
show_progress() {
    echo -e "${GREEN}[+] $1${NC}"
}

# Funktion zum Anzeigen von Warnungen
show_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Funktion zum Anzeigen von Fehlern
show_error() {
    echo -e "${RED}[-] $1${NC}"
}

# Prüfen, ob das Skript als Root ausgeführt wird
if [ "$EUID" -ne 0 ]; then
    show_error "Dieses Skript muss als Root ausgeführt werden."
    echo "Bitte mit 'sudo' ausführen."
    exit 1
fi

# Verzeichnis erstellen
show_progress "Erstelle Installationsverzeichnis..."
mkdir -p "$INSTALL_DIR"

# Abhängigkeiten installieren
show_progress "Installiere Abhängigkeiten..."
apt-get update
apt-get install -y python3-pip python3-venv

# Python-Umgebung erstellen
show_progress "Erstelle Python-Umgebung..."
python3 -m venv "$INSTALL_DIR/venv"
source "$INSTALL_DIR/venv/bin/activate"

# Python-Pakete installieren
show_progress "Installiere Python-Pakete..."
pip install -r requirements.txt

# Dateien kopieren
show_progress "Kopiere Dateien..."
cp api_integration.py "$INSTALL_DIR/"
cp create_db.py "$INSTALL_DIR/"

# Datenbank erstellen, falls nicht vorhanden
if [ ! -f "$INSTALL_DIR/$DB_PATH" ]; then
    show_progress "Erstelle Datenbank..."
    cd "$INSTALL_DIR"
    python create_db.py
else
    show_warning "Datenbank existiert bereits, überspringe Erstellung."
fi

# Systemd-Service erstellen
show_progress "Erstelle Systemd-Service..."
cp leadhub.service "/etc/systemd/system/$SERVICE_NAME.service"

# Systemd-Service aktivieren und starten
show_progress "Aktiviere und starte Systemd-Service..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# Status prüfen
show_progress "Prüfe Status..."
systemctl status "$SERVICE_NAME"

# Erfolgsmeldung
show_progress "Installation abgeschlossen!"
echo ""
echo -e "${GREEN}LeadHub Professional API wurde erfolgreich installiert.${NC}"
echo ""
echo "API-URL: http://3.77.229.60:$API_PORT/"
echo "Gradio-URL: http://3.77.229.60:$GRADIO_PORT/"

