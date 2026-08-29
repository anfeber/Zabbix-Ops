
# ============================================================
# Zabbix Agent - Windows Firewall Rules
# Ejecutar como Administrador
# Autor - Andres Felipe Bernal
# Fecha - Agosto 2026
# ============================================================

# --- Parámetros ---
$ZabbixServerIP = "192.168.10.81"   # ← IP de tu Zabbix Server
$Profile = "Domain,Private"          # Ajusta si usas Public

# --- 1. Passive checks: Zabbix Server → Agent (inbound TCP 10050) ---
New-NetFirewallRule `
    -DisplayName "Zabbix Agent - Passive Inbound (TCP 10050)" `
    -Description "Permite al Zabbix Server hacer passive checks al agente" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 10050,10051 `
    -RemoteAddress $ZabbixServerIP `
    -Action Allow `
    -Profile $Profile `
    -Enabled True

# --- 2. Active checks: Agent → Zabbix Server (outbound TCP 10051) ---
New-NetFirewallRule `
    -DisplayName "Zabbix Agent - Active Outbound (TCP 10051)" `
    -Description "Permite al agente enviar active checks al Zabbix Server" `
    -Direction Outbound `
    -Protocol TCP `
    -RemotePort 10050,10051 `
    -RemoteAddress $ZabbixServerIP `
    -Action Allow `
    -Profile $Profile `
    -Enabled True

# --- 3. (Opcional) ICMP para ping/availability ---
New-NetFirewallRule `
    -DisplayName "Zabbix Agent - ICMP Echo (Ping)" `
    -Description "Permite ping desde el Zabbix Server para availability" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -RemoteAddress $ZabbixServerIP `
    -Action Allow `
    -Profile $Profile `
    -Enabled True

# --- Verificación ---
Write-Host "`n=== Reglas creadas ===" -ForegroundColor Green
Get-NetFirewallRule -DisplayName "Zabbix Agent*" |
    Select-Object DisplayName, Direction, Action, Enabled |
    Format-Table -AutoSize

# --- Test de conectividad ---
Write-Host "`n=== Test: Puerto 10050 local ===" -ForegroundColor Cyan
Test-NetConnection -ComputerName localhost -Port 10050 |
    Select-Object ComputerName, RemotePort, TcpTestSucceeded |
    Format-Table -AutoSize

Write-Host "=== Test: Conectividad a Zabbix Server (10051) ===" -ForegroundColor Cyan
Test-NetConnection -ComputerName $ZabbixServerIP -Port 10051 |
    Select-Object ComputerName, RemotePort, TcpTestSucceeded |
    Format-Table -AutoSize   
