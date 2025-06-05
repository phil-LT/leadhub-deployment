#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LeadHub Professional - API Integration
Version: 1.0

Diese Datei erweitert den bestehenden Gradio-Viewer um eine API-Schnittstelle,
um Leads von der Website zu empfangen.
"""

import gradio as gr
import sqlite3
import pandas as pd
import json
import os
import sys
import logging
from datetime import datetime
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uvicorn
import threading

# Logging konfigurieren
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("leadhub_api")

# Konfiguration
DB_PATH = 'leads.db'
API_PORT = 8000
GRADIO_PORT = 7860
SERVER_HOST = "0.0.0.0"  # Auf allen Netzwerkschnittstellen hören

# FastAPI App erstellen
app = FastAPI(
    title="LeadHub Professional API",
    description="API für LeadHub Professional",
    version="1.0.0"
)

# CORS für Website-Zugriff
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Datenmodelle
class Lead(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    source: Optional[str] = "Website"
    lead_stage: Optional[str] = "New"
    lead_score: Optional[int] = None
    company: Optional[str] = None
    industry: Optional[str] = None
    budget: Optional[float] = None
    notes: Optional[str] = None
    
    # Zusätzliche Felder für Stromtarifprofi
    plz: Optional[str] = None
    verbrauch: Optional[str] = None
    personen: Optional[str] = None
    e_auto: Optional[bool] = False
    smart_meter: Optional[bool] = False

class LeadResponse(BaseModel):
    success: bool
    message: str
    lead_id: Optional[int] = None
    affiliate_routing: Optional[str] = None
    redirect_url: Optional[str] = None

class HealthResponse(BaseModel):
    status: str
    version: str
    timestamp: str
    db_status: str
    leads_count: int

# Hilfsfunktionen
def ensure_db_exists():
    """Stellt sicher, dass die Datenbank existiert."""
    if not os.path.exists(DB_PATH):
        logger.error(f"Datenbank {DB_PATH} existiert nicht. Bitte erstellen Sie die Datenbank mit create_db.py")
        return False
    return True

def calculate_lead_score(lead_data):
    """Berechnet den Lead-Score basierend auf den Lead-Daten."""
    score = 50  # Basis-Score
    
    # Verbrauch (falls vorhanden)
    try:
        if hasattr(lead_data, 'verbrauch') and lead_data.verbrauch:
            verbrauch = int(lead_data.verbrauch)
            if verbrauch > 5000:
                score += 20
            elif verbrauch > 3500:
                score += 15
            elif verbrauch > 2500:
                score += 10
    except:
        pass
    
    # Personen im Haushalt (falls vorhanden)
    try:
        if hasattr(lead_data, 'personen') and lead_data.personen:
            personen = int(lead_data.personen)
            if personen >= 4:
                score += 15
            elif personen >= 2:
                score += 10
    except:
        pass
    
    # E-Auto und Smart Meter (falls vorhanden)
    if hasattr(lead_data, 'e_auto') and lead_data.e_auto:
        score += 25
    if hasattr(lead_data, 'smart_meter') and lead_data.smart_meter:
        score += 15
    
    # Budget (falls vorhanden)
    try:
        if hasattr(lead_data, 'budget') and lead_data.budget:
            budget = float(lead_data.budget)
            if budget > 10000:
                score += 20
            elif budget > 5000:
                score += 15
            elif budget > 2000:
                score += 10
    except:
        pass
    
    # Kontaktdaten
    if lead_data.email:
        score += 5
    if lead_data.phone:
        score += 5
    
    # Score begrenzen
    return max(1, min(100, score))

def determine_affiliate(lead_data, lead_score):
    """Bestimmt den passenden Affiliate basierend auf Lead-Daten."""
    # E-Auto-Leads zu RABOT
    if hasattr(lead_data, 'e_auto') and lead_data.e_auto:
        return "RABOT"
    
    # Hoher Verbrauch zu CHECK24
    try:
        if hasattr(lead_data, 'verbrauch') and lead_data.verbrauch:
            verbrauch = int(lead_data.verbrauch)
            if verbrauch > 4000:
                return "CHECK24"
    except:
        pass
    
    # Standard zu CHECK24
    return "CHECK24"

def generate_affiliate_url(affiliate, lead_data):
    """Generiert die Affiliate-URL basierend auf dem ausgewählten Affiliate und den Lead-Daten."""
    # Affiliate-URLs
    affiliate_urls = {
        "CHECK24": "https://www.check24.de/strom/",
        "VERIVOX": "https://www.verivox.de/stromvergleich/",
        "RABOT": "https://www.rabot-charge.de/"
    }
    
    # Basis-URL abrufen
    url = affiliate_urls.get(affiliate, affiliate_urls["CHECK24"])
    
    # Parameter für die URL vorbereiten
    params = {}
    
    # Lead-Daten als Parameter hinzufügen (falls vorhanden)
    if hasattr(lead_data, 'plz') and lead_data.plz:
        params["plz"] = lead_data.plz
    if hasattr(lead_data, 'verbrauch') and lead_data.verbrauch:
        params["verbrauch"] = lead_data.verbrauch
    if hasattr(lead_data, 'personen') and lead_data.personen:
        params["personen"] = lead_data.personen
    
    # UTM-Parameter hinzufügen
    params.update({
        "utm_source": "leadhub",
        "utm_medium": "affiliate",
        "utm_campaign": f"leadhub_{affiliate.lower()}",
        "utm_content": "lead_form"
    })
    
    # Parameter zur URL hinzufügen
    if params:
        separator = "&" if "?" in url else "?"
        url += separator + "&".join([f"{k}={v}" for k, v in params.items()])
    
    return url

def save_lead_to_db(lead_data, affiliate, lead_score):
    """Speichert den Lead in der Datenbank."""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Prüfen, ob zusätzliche Felder in der Datenbank vorhanden sind
        cursor.execute("PRAGMA table_info(leads)")
        columns = [column[1] for column in cursor.fetchall()]
        
        # Zusätzliche Felder für Stromtarifprofi in Notes speichern, wenn nicht in der Datenbank vorhanden
        additional_notes = []
        if hasattr(lead_data, 'plz') and lead_data.plz and 'plz' not in columns:
            additional_notes.append(f"PLZ: {lead_data.plz}")
        if hasattr(lead_data, 'verbrauch') and lead_data.verbrauch and 'verbrauch' not in columns:
            additional_notes.append(f"Verbrauch: {lead_data.verbrauch}")
        if hasattr(lead_data, 'personen') and lead_data.personen and 'personen' not in columns:
            additional_notes.append(f"Personen: {lead_data.personen}")
        if hasattr(lead_data, 'e_auto') and lead_data.e_auto and 'e_auto' not in columns:
            additional_notes.append("E-Auto: Ja")
        if hasattr(lead_data, 'smart_meter') and lead_data.smart_meter and 'smart_meter' not in columns:
            additional_notes.append("Smart Meter: Ja")
        
        # Notes zusammenführen
        notes = lead_data.notes or ""
        if additional_notes:
            if notes:
                notes += "\n\n"
            notes += "\n".join(additional_notes)
        
        # Affiliate in Notes speichern, wenn nicht in der Datenbank vorhanden
        if 'affiliate' not in columns:
            notes += f"\n\nAffiliate: {affiliate}"
        
        # Lead in Datenbank speichern
        cursor.execute('''INSERT INTO leads 
                       (name, email, phone, source, lead_stage, lead_score, company, industry, budget, created_date, notes)
                       VALUES (?,?,?,?,?,?,?,?,?,?,?)''',
                       (lead_data.name, lead_data.email, lead_data.phone, lead_data.source, 
                        lead_data.lead_stage, lead_score, lead_data.company, lead_data.industry, 
                        lead_data.budget, datetime.now().strftime('%Y-%m-%d'), notes))
        
        lead_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        return lead_id
    except Exception as e:
        logger.error(f"Fehler beim Speichern des Leads in der Datenbank: {e}")
        return None

# API-Endpunkte
@app.get("/")
async def root():
    """Root-Endpunkt mit API-Informationen."""
    return {
        "name": "LeadHub Professional API",
        "version": "1.0.0",
        "description": "API für LeadHub Professional",
        "endpoints": {
            "/api/health": "API-Gesundheitsstatus",
            "/api/submit-lead": "Lead einreichen",
            "/api/leads": "Leads abrufen",
            "/api/stats": "Statistiken abrufen"
        },
        "dashboard_url": f"http://3.77.229.60:{GRADIO_PORT}/"
    }

@app.get("/api/health", response_model=HealthResponse)
async def health_check():
    """Gesundheitsstatus der API."""
    if not ensure_db_exists():
        return {
            "status": "error",
            "version": "1.0.0",
            "timestamp": datetime.now().isoformat(),
            "db_status": "not found",
            "leads_count": 0
        }
    
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM leads")
        count = cursor.fetchone()[0]
        db_status = "online"
        conn.close()
    except Exception as e:
        logger.error(f"Fehler beim Zugriff auf die Datenbank: {e}")
        count = 0
        db_status = f"error: {str(e)}"
    
    return {
        "status": "online",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat(),
        "db_status": db_status,
        "leads_count": count
    }

@app.post("/api/submit-lead", response_model=LeadResponse)
async def submit_lead(lead: Lead):
    """Lead einreichen und in der Datenbank speichern."""
    if not ensure_db_exists():
        return {
            "success": False,
            "message": "Datenbank nicht gefunden."
        }
    
    try:
        # Lead-Score berechnen
        lead_score = calculate_lead_score(lead)
        
        # Affiliate bestimmen
        affiliate = determine_affiliate(lead, lead_score)
        
        # Lead in Datenbank speichern
        lead_id = save_lead_to_db(lead, affiliate, lead_score)
        
        if not lead_id:
            return {
                "success": False,
                "message": "Fehler beim Speichern des Leads in der Datenbank."
            }
        
        # Affiliate-URL generieren
        redirect_url = generate_affiliate_url(affiliate, lead)
        
        return {
            "success": True,
            "message": "Lead erfolgreich eingereicht.",
            "lead_id": lead_id,
            "affiliate_routing": affiliate,
            "redirect_url": redirect_url
        }
    except Exception as e:
        logger.error(f"Fehler beim Einreichen des Leads: {e}")
        return {
            "success": False,
            "message": f"Fehler beim Einreichen des Leads: {str(e)}"
        }

@app.get("/api/leads")
async def get_leads(limit: int = 100, offset: int = 0, status: str = None):
    """Leads aus der Datenbank abrufen."""
    if not ensure_db_exists():
        raise HTTPException(status_code=500, detail="Datenbank nicht gefunden.")
    
    try:
        conn = sqlite3.connect(DB_PATH)
        query = "SELECT * FROM leads"
        params = []
        
        if status:
            query += " WHERE lead_stage = ?"
            params.append(status)
        
        query += " ORDER BY id DESC LIMIT ? OFFSET ?"
        params.extend([limit, offset])
        
        df = pd.read_sql_query(query, conn, params=params)
        conn.close()
        
        return df.to_dict(orient="records")
    except Exception as e:
        logger.error(f"Fehler beim Abrufen der Leads: {e}")
        raise HTTPException(status_code=500, detail=f"Fehler beim Abrufen der Leads: {str(e)}")

@app.get("/api/stats")
async def get_stats():
    """Statistiken über Leads abrufen."""
    if not ensure_db_exists():
        raise HTTPException(status_code=500, detail="Datenbank nicht gefunden.")
    
    try:
        conn = sqlite3.connect(DB_PATH)
        
        # Gesamtzahl der Leads
        total = pd.read_sql_query("SELECT COUNT(*) as count FROM leads", conn).iloc[0]['count']
        
        # Leads nach Status
        stages = pd.read_sql_query("SELECT lead_stage, COUNT(*) as count FROM leads GROUP BY lead_stage", conn)
        stages_dict = {row['lead_stage']: row['count'] for _, row in stages.iterrows()}
        
        # Leads nach Quelle
        sources = pd.read_sql_query("SELECT source, COUNT(*) as count FROM leads GROUP BY source", conn)
        sources_dict = {row['source']: row['count'] for _, row in sources.iterrows()}
        
        # Leads nach Datum
        dates = pd.read_sql_query("SELECT created_date, COUNT(*) as count FROM leads GROUP BY created_date ORDER BY created_date DESC LIMIT 30", conn)
        dates_dict = {row['created_date']: row['count'] for _, row in dates.iterrows()}
        
        conn.close()
        
        return {
            "total": total,
            "stages": stages_dict,
            "sources": sources_dict,
            "dates": dates_dict
        }
    except Exception as e:
        logger.error(f"Fehler beim Abrufen der Statistiken: {e}")
        raise HTTPException(status_code=500, detail=f"Fehler beim Abrufen der Statistiken: {str(e)}")

# Gradio-Funktionen aus viewer.py
def load_leads(status_filter="Alle", limit=100):
    """Lädt Leads aus der Datenbank für das Gradio-Interface."""
    conn = sqlite3.connect(DB_PATH)
    query = "SELECT * FROM leads"
    
    if status_filter != "Alle":
        query += f" WHERE lead_stage = '{status_filter}'"
    
    query += f" ORDER BY id DESC LIMIT {limit}"
    
    df = pd.read_sql_query(query, conn)
    conn.close()
    
    return df

def get_statistics():
    """Ruft Statistiken für das Gradio-Interface ab."""
    conn = sqlite3.connect(DB_PATH)
    total = pd.read_sql_query("SELECT COUNT(*) as count FROM leads", conn).iloc[0]['count']
    stages = pd.read_sql_query("SELECT lead_stage, COUNT(*) as count FROM leads GROUP BY lead_stage", conn)
    sources = pd.read_sql_query("SELECT source, COUNT(*) as count FROM leads GROUP BY source", conn)
    conn.close()
    
    stats = f"LEADHUB STATISTIKEN\n\nGesamt: {total} Leads\n\nStatus:\n"
    for _, row in stages.iterrows():
        stats += f"- {row['lead_stage']}: {row['count']}\n"
    stats += "\nQuellen:\n"
    for _, row in sources.iterrows():
        stats += f"- {row['source']}: {row['count']}\n"
    return stats

def system_info():
    """Ruft System-Informationen für das Gradio-Interface ab."""
    import subprocess
    
    def safe_command(cmd):
        try:
            return subprocess.getoutput(cmd)
        except:
            return "Fehler beim Ausführen"
    
    info = f"""SYSTEM-INFO

Server: {safe_command('/bin/hostname')}
OS: {safe_command('/usr/bin/lsb_release -d | /usr/bin/cut -f2')}
Uptime: {safe_command('/usr/bin/uptime')}
Speicher: {safe_command('/usr/bin/free -h | /bin/grep Mem')}
Festplatte: {safe_command('/bin/df -h / | /usr/bin/tail -1')}

API-Status: Online
API-URL: http://3.77.229.60:{API_PORT}/
Gradio-URL: http://3.77.229.60:{GRADIO_PORT}/
"""
    return info

# Gradio-Interface erstellen
def create_gradio_interface():
    """Erstellt das Gradio-Interface."""
    with gr.Blocks(title="LeadHub Professional") as demo:
        gr.Markdown("# LeadHub Professional")
        
        with gr.Tabs():
            with gr.TabItem("Lead-Management"):
                with gr.Row():
                    status_filter = gr.Dropdown(
                        ["Alle", "New", "Contacted", "Qualified", "Proposal", "Closed Won", "Closed Lost"], 
                        value="Alle", 
                        label="Status Filter"
                    )
                    limit = gr.Slider(10, 250, value=100, label="Anzahl Leads")
                    load_btn = gr.Button("Leads laden", variant="primary")
                
                leads_table = gr.Dataframe(value=load_leads())
                load_btn.click(load_leads, inputs=[status_filter, limit], outputs=[leads_table])
            
            with gr.TabItem("Statistiken"):
                stats_btn = gr.Button("Statistiken laden", variant="primary")
                stats_output = gr.Markdown(value=get_statistics())
                stats_btn.click(get_statistics, outputs=[stats_output])
            
            with gr.TabItem("System"):
                info_btn = gr.Button("System-Info", variant="primary")
                info_output = gr.Markdown()
                info_btn.click(system_info, outputs=[info_output])
    
    return demo

# Hauptfunktion
def main():
    """Hauptfunktion zum Starten der API und des Gradio-Interfaces."""
    # Prüfen, ob die Datenbank existiert
    if not ensure_db_exists():
        logger.error("Datenbank nicht gefunden. Bitte erstellen Sie die Datenbank mit create_db.py")
        sys.exit(1)
    
    # Gradio-Interface erstellen
    demo = create_gradio_interface()
    
    # FastAPI und Gradio parallel starten
    def start_fastapi():
        uvicorn.run(app, host=SERVER_HOST, port=API_PORT)
    
    # FastAPI in einem separaten Thread starten
    threading.Thread(target=start_fastapi, daemon=True).start()
    
    # Gradio starten
    demo.launch(server_name=SERVER_HOST, server_port=GRADIO_PORT, share=False)

if __name__ == "__main__":
    main()

