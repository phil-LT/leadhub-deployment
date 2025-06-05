# LeadHub Professional API

Diese Repository enthält den Code für die LeadHub Professional API, die es ermöglicht, Leads von der Website an den Gradio-Server zu übertragen.

## Übersicht

Die LeadHub Professional API besteht aus zwei Hauptkomponenten:

1. **API-Komponente**: Eine FastAPI-Anwendung, die Leads empfängt und in der Datenbank speichert.
2. **Gradio-Komponente**: Ein Dashboard zur Anzeige und Verwaltung von Leads.

## Verzeichnisstruktur

```
leadhub-deployment/
├── scripts/
│   ├── api_integration.py  # Hauptdatei mit FastAPI und Gradio-Integration
│   ├── create_db.py        # Skript zum Erstellen der Datenbank
│   └── setup.sh            # Setup-Skript für die Installation
├── configs/
│   ├── requirements.txt    # Python-Abhängigkeiten
│   └── leadhub.service     # Systemd-Service-Datei
└── .github/
    └── workflows/
        └── deploy.yml      # GitHub Actions Workflow für das Deployment
```

## Installation

Die Installation erfolgt automatisch über GitHub Actions. Wenn Sie Änderungen an diesem Repository vornehmen und auf den `main`-Branch pushen, wird der Deployment-Workflow ausgeführt.

### Manuelle Installation

Wenn Sie die API manuell installieren möchten, führen Sie die folgenden Schritte aus:

1. Klonen Sie das Repository:
   ```bash
   git clone https://github.com/phil-LT/leadhub-deployment.git
   cd leadhub-deployment
   ```

2. Führen Sie das Setup-Skript aus:
   ```bash
   sudo bash scripts/setup.sh
   ```

## Verwendung

Nach der Installation ist die API unter http://3.77.229.60:8000/ und das Gradio-Dashboard unter http://3.77.229.60:7860/ erreichbar.

### API-Endpunkte

- `GET /api/health`: Gesundheitsstatus der API
- `POST /api/submit-lead`: Lead einreichen und in der Datenbank speichern
- `GET /api/leads`: Leads aus der Datenbank abrufen
- `GET /api/stats`: Statistiken über Leads abrufen

### Beispiel für das Einreichen eines Leads

```bash
curl -X POST http://3.77.229.60:8000/api/submit-lead \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "+49 123 4567890",
    "plz": "10115",
    "verbrauch": "3500",
    "personen": "2",
    "e_auto": false,
    "smart_meter": false,
    "source": "API Test"
  }'
```

## Website-Integration

Die Website-Integration erfolgt über die JavaScript-Datei `website_integration.js`, die in die Website eingebunden werden muss. Diese Datei ist nicht Teil dieses Repositories, sondern wird separat in das Website-Repository eingefügt.

## Deployment

Das Deployment erfolgt automatisch über GitHub Actions. Der Workflow wird ausgeführt, wenn Änderungen auf den `main`-Branch gepusht werden.

### GitHub Secrets

Für das Deployment werden die folgenden GitHub Secrets benötigt:

- `SSH_PRIVATE_KEY`: Der SSH-Private-Key für den Zugriff auf den Server

## Support

Bei Fragen oder Problemen wenden Sie sich bitte an den Support.

