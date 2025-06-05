import sqlite3
import random
from datetime import datetime, timedelta

conn = sqlite3.connect('leads.db')
cursor = conn.cursor()

cursor.execute('''CREATE TABLE leads (
    id INTEGER PRIMARY KEY,
    name TEXT, email TEXT, phone TEXT, source TEXT,
    lead_stage TEXT, lead_score INTEGER, company TEXT,
    industry TEXT, budget REAL, created_date TEXT, notes TEXT
)''')

sources = ['Website', 'Social Media', 'Email', 'Referral', 'Cold Call', 'LinkedIn']
stages = ['New', 'Contacted', 'Qualified', 'Proposal', 'Closed Won', 'Closed Lost']
companies = ['TechCorp', 'DataSoft', 'CloudSys', 'InnovateLab', 'DigitalPro']
industries = ['Technology', 'Healthcare', 'Finance', 'Manufacturing', 'Retail']

for i in range(1, 251):
    name = f"Lead {i:03d}"
    email = f"lead{i:03d}@example.com"
    phone = f"+49 {random.randint(100,999)} {random.randint(1000000,9999999)}"
    source = random.choice(sources)
    stage = random.choice(stages)
    company = random.choice(companies)
    industry = random.choice(industries)
    budget = round(random.uniform(1000, 50000), 2)
    created = (datetime.now() - timedelta(days=random.randint(0,90))).strftime('%Y-%m-%d')
    notes = f"Interessiert an {industry} Lösungen"
    
    cursor.execute('''INSERT INTO leads VALUES (?,?,?,?,?,?,?,?,?,?,?,?)''',
                   (i, name, email, phone, source, stage, random.randint(1,100), 
                    company, industry, budget, created, notes))

conn.commit()
conn.close()

print("✅ Datenbank mit 250 Leads erstellt")

