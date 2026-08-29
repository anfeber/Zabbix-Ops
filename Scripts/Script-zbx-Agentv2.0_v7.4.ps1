<#
.SYNOPSIS
    Instala y configura Zabbix Agent 2 en modo activo.
.NOTES
    Ejecutar como Administrador.
.Autor
    - Andrés Felipe Bernal
.Fecha
    - Agosto 29 del 2026
#>

# ============================================================
# PARÁMETROS
# ============================================================
$ZabbixVersion      = "7.4.14"
$ZabbixServer       = "192.168.10.81"
$ZabbixServerActive = "192.168.10.81"
$AgentInstallDir    = "C:\Program Files\Zabbix Agent 2"
$MsiPath            = "S:\Options\Zabbix v8.0\zabbix_agent2-7.4.14-windows-amd64-openssl.msi" #"\\fileserver\zabbix\zabbix_agent2-$ZabbixVersion-windows-amd64-openssl.msi"

# ============================================================
# INSTALAR
# ============================================================
Write-Host "=== Instalando Zabbix Agent 2 ===" -ForegroundColor Cyan

$agentService = Get-Service -Name "Zabbix Agent 2" -ErrorAction SilentlyContinue
if ($agentService) {
    Write-Host "El agente ya está instalado. Saltando." -ForegroundColor Yellow
} else {
    Start-Process msiexec.exe -ArgumentList @(
        "/qn",
        "/i `"$MsiPath`"",
        "SERVER=$ZabbixServer",
        "SERVERACTIVE=$ZabbixServerActive"
    ) -NoNewWindow -Wait
    Write-Host "Zabbix Agent 2 instalado." -ForegroundColor Green
}

# ============================================================
# VERIFICAR
# ============================================================
Write-Host "`n=== Verificación ===" -ForegroundColor Cyan
$svc = Get-Service -Name "Zabbix Agent 2" -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Host "Servicio en ejecución. OK." -ForegroundColor Green
} else {
    Write-Host "ERROR: El servicio no está corriendo." -ForegroundColor Red
}

Write-Host "`n=== LISTO ===" -ForegroundColor Cyan   
