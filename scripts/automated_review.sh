
#!/bin/bash



# LeadHub Automated Review System

# Version: 1.0

# Erstellt für Sandbox-Diagnose



echo "���� LEADHUB AUTOMATED REVIEW SYSTEM"

echo "=================================="

echo "Timestamp: $(date)"

echo "Sandbox IP: 3.77.229.60 (intern: $(hostname -I | awk '{print $1}'))"

echo ""



# Exit codes f��r CI/CD Integration

EXIT_CODE=0



echo "=== 1. SYSTEM HEALTH CHECK ==="

echo "Hostname: $(hostname)"

echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"

echo "Uptime: $(uptime)"

echo "Load Average: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"



# Memory Check

MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')

echo "Memory Usage: ${MEMORY_USAGE}%"

if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then

    echo "ü⚠️  WARNING: High memory usage!"

    EXIT_CODE=1

fi



# Disk Check

DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

echo "Disk Usage: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -gt 85 ]; then

    echo "⚠️  WARNING: High disk usage!"

    EXIT_CODE=1

fi

echo ""



echo "=== 2. NETWORK & PORTS ==="

echo "Open Ports:"

netstat -tlnp | grep LISTEN | while read line; do

    echo "  $line"

done



echo ""

echo "LeadHub Port 7860 Check:"

if netstat -tlnp | grep -q ":7860"; then

    echo "✅ Port 7860 is OPEN and LISTENING"

    LEADHUB_PID=$(netstat -tlnp | grep ":7860" | awk '{print $7}' | cut -d'/' -f1)

    echo "   Process ID: $LEADHUB_PID"

else

    echo "❌ Port 7860 is NOT listening!"

    EXIT_CODE=2

fi

echo ""



echo "=== 3. LEADHUB SERVICE CHECK ==="

echo "Local HTTP Test:"

LOCAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7860 2>/dev/null )

if [ "$LOCAL_TEST" = "200" ]; then

    echo "✅ Local access: HTTP $LOCAL_TEST (OK)"

else

    echo "❌ Local access: HTTP $LOCAL_TEST (FAILED)"

    EXIT_CODE=3

fi



echo "External HTTP Test:"

EXTERNAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://3.77.229.60:7860 2>/dev/null )

if [ "$EXTERNAL_TEST" = "200" ]; then

    echo "✅ External access: HTTP $EXTERNAL_TEST (OK)"

else

    echo "❌ External access: HTTP $EXTERNAL_TEST (FAILED)"

    EXIT_CODE=4

fi

echo ""



echo "=== 4. LEADHUB PROCESSES ==="

PYTHON_PROCESSES=$(ps aux | grep -E "(python|gradio|uvicorn)" | grep -v grep | wc -l)

echo "Python/LeadHub processes: $PYTHON_PROCESSES"

if [ "$PYTHON_PROCESSES" -gt 0 ]; then

    echo "✅ LeadHub processes are running"

    ps aux | grep -E "(python|gradio|uvicorn)" | grep -v grep | head -5

else

    echo "❌ No LeadHub processes found!"

    EXIT_CODE=5

fi

echo ""



echo "=== 5. DATABASE CHECK ==="

if [ -f "/home/ubuntu/lead_hub/leads.db" ]; then

    echo "✅ Database file exists"

    DB_SIZE=$(du -h /home/ubuntu/lead_hub/leads.db | cut -f1)

    echo "   Database size: $DB_SIZE"

    

    LEAD_COUNT=$(sqlite3 /home/ubuntu/lead_hub/leads.db "SELECT COUNT(*) FROM leads;" 2>/dev/null || echo "0")

    echo "   Lead count: $LEAD_COUNT"

    

    if [ "$LEAD_COUNT" -gt 0 ]; then

        echo "✅ Database contains $LEAD_COUNT leads"

    else

        echo "⚠️  Database is empty or inaccessible"

    fi

else

    echo "❌ Database file not found!"

    EXIT_CODE=6

fi

echo ""



echo "=== 6. SYSTEM RESOURCES ==="

echo "CPU Info:"

echo "  Cores: $(nproc)"

echo "  Load: $(cat /proc/loadavg | awk '{print $1}')"



echo "Memory Info:"

free -h | grep -E "(Mem|Swap)"



echo "Disk Info:"

df -h / | tail -1

echo ""



echo "=== 7. RECENT LOGS ==="

echo "Last 5 system messages:"

journalctl -n 5 --no-pager 2>/dev/null | tail -5 || echo "Journal not accessible"

echo ""



echo "=== REVIEW SUMMARY ==="

if [ $EXIT_CODE -eq 0 ]; then

    echo "���� STATUS: ALL CHECKS PASSED"

    echo "��✅ LeadHub is running optimally"

    echo "✅ All services are healthy"

    echo "✅ System resources are adequate"

else

    echo "⚠️  STATUS: ISSUES DETECTED (Exit Code: $EXIT_CODE)"

    echo "❌ Some checks failed - review output above"

fi



echo ""

echo "Next steps:"

echo "- Test web interface: http://3.77.229.60:7860"

echo "- Check System tab functionality"

echo "- Run performance tests"

echo ""

echo "Review completed at: $(date )"



exit $EXIT_CODE

