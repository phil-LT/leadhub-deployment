
# -*- coding: utf-8 -*-

import gradio as gr

import sqlite3

import pandas as pd

import subprocess

from datetime import datetime



def load_leads(status_filter="Alle", limit=100):

    conn = sqlite3.connect('leads.db')

    query = "SELECT * FROM leads"

    if status_filter != "Alle":

        query += f" WHERE lead_stage = '{status_filter}'"

    query += f" ORDER BY id DESC LIMIT {limit}"

    

    df = pd.read_sql_query(query, conn)

    conn.close()

    return df



def get_statistics():

    conn = sqlite3.connect('leads.db')

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

"""

    return info



with gr.Blocks(title="LeadHub Professional") as demo:

    gr.Markdown("# LeadHub Professional")

    

    with gr.Tabs():

        with gr.TabItem("Lead-Management"):

            with gr.Row():

                status_filter = gr.Dropdown(["Alle", "New", "Contacted", "Qualified", "Proposal", "Closed Won", "Closed Lost"], 

                                          value="Alle", label="Status Filter")

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



if __name__ == "__main__":

    demo.launch(server_name="0.0.0.0", server_port=7860, share=False)

