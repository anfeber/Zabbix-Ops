<#
.SYNOPSIS
    Instala Zabbix Agent 2 + Plugin MSSQL y configura el monitoreo.
.DESCRIPTION
    - Instala Zabbix Agent 2 desde un MSI local o red
    - Instala SOLO el plugin MSSQL (ADDLOCAL=MssqlPlugin)
    - Configura mssql.conf con credenciales
    - (Opcional) Crea el usuario de SQL Server
.NOTES
    Ejecutar como Administrador
.Autor
    - Andrés Felipe Bernal
.Fecha
    - Agosto 29 del 2026
#>

# ============================================================
# PARÁMETROS - EDITAR SEGÚN TU ENTORNO
# ============================================================
$ZabbixVersion      = "7.4.5"                          # Versión del agente
$ZabbixServer       = "192.168.10.81"     # IP/DNS del servidor Zabbix
$ZabbixServerActive = "192.168.10.81"    # Para agente activo
$MSSQLHost          = "localhost"                      # Host del SQL Server
$MSSQLPort          = "1433"                           # Puerto MSSQL
$MSSQLUser          = "zbx_monitor"                    # Usuario de SQL para monitoreo
$MSSQLPassword      = "CambiaEstaPassword123!"         # Contraseña del usuario
$AgentInstallDir    = "C:\Program Files\Zabbix Agent 2"
$MsiPath            = "\\fileserver\zabbix\zabbix_agent2-$ZabbixVersion-windows-amd64-openssl.msi"
$PluginMsiPath      = "\\fileserver\zabbix\zabbix_agent2_plugins-$ZabbixVersion-windows-amd64.msi"

# ============================================================
# 1. INSTALAR ZABBIX AGENT 2
# ============================================================
Write-Host "=== Instalando Zabbix Agent 2 ===" -ForegroundColor Cyan

$agentService = Get-Service -Name "Zabbix Agent 2" -ErrorAction SilentlyContinue
if ($agentService) {
    Write-Host "El agente ya está instalado. Saltando instalación." -ForegroundColor Yellow
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
# 2. INSTALAR PLUGIN MSSQL (SOLO MSSQL)
# ============================================================
Write-Host "`n=== Instalando Plugin MSSQL ===" -ForegroundColor Cyan

Start-Process msiexec.exe -ArgumentList @(
    "/qn",
    "/i `"$PluginMsiPath`"",
    "ADDLOCAL=MssqlPlugin"
) -NoNewWindow -Wait
Write-Host "Plugin MSSQL instalado." -ForegroundColor Green

# ============================================================
# 3. CONFIGURAR EL PLUGIN (mssql.conf)
# ============================================================
Write-Host "`n=== Configurando mssql.conf ===" -ForegroundColor Cyan

# El plugin instala su conf en:
# C:\Program Files\Zabbix Agent 2 Plugins\zabbix_agent2.d\
# Pero el agente lo lee de:
# C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\plugins.d\

$PluginsDir = Join-Path $AgentInstallDir "zabbix_agent2.d\plugins.d"
if (-not (Test-Path $PluginsDir)) {
    New-Item -Path $PluginsDir -ItemType Directory -Force | Out-Null
}

# Verificar que el agente incluye la carpeta plugins.d
$AgentConf = Join-Path $AgentInstallDir "zabbix_agent2.conf"
$includeLine = "Include=$AgentInstallDir\zabbix_agent2.d\plugins.d\*.conf"
if ((Get-Content $AgentConf) -notmatch [regex]::Escape("plugins.d")) {
    Add-Content -Path $AgentConf -Value $includeLine
    Write-Host "Agregada línea Include en zabbix_agent2.conf"
}

# Escribir mssql.conf
$MssqlConfPath = Join-Path $PluginsDir "mssql.conf"
$MssqlConfContent = @"
Plugins.MSSQL.System.Path=$AgentInstallDir\zabbix-agent2-plugin-mssql.exe
Plugins.MSSQL.KeepAlive=300
Plugins.MSSQL.Default.Uri=sqlserver://$MSSQLHost:$MSSQLPort
Plugins.MSSQL.Default.User=$MSSQLUser
Plugins.MSSQL.Default.Password=$MSSQLPassword
"@
Set-Content -Path $MssqlConfPath -Value $MssqlConfContent -Encoding UTF8
Write-Host "mssql.conf creado en: $MssqlConfPath" -ForegroundColor Green

# ============================================================
# 4. REINICIAR SERVICIO DEL AGENTE
# ============================================================
Write-Host "`n=== Reiniciando servicio Zabbix Agent 2 ===" -ForegroundColor Cyan
Restart-Service -Name "Zabbix Agent 2" -Force
Write-Host "Servicio reiniciado." -ForegroundColor Green

# ============================================================
# 5. (OPCIONAL) CREAR USUARIO EN SQL SERVER
# ============================================================
Write-Host "`n=== Creando usuario MSSQL para monitoreo ===" -ForegroundColor Cyan

# Requiere módulo SqlServer: Install-Module SqlServer -Force -AllowClobber
try {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$MSSQLHost,$MSSQLPort;User Id=sa;Password=$MSSQLPassword"
    $conn.Open()

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = @"
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '$MSSQLUser')
    CREATE LOGIN $MSSQLUser WITH PASSWORD = '$MSSQLPassword';

GRANT VIEW SERVER PERFORMANCE STATE TO $MSSQLUser;
GRANT VIEW ANY DEFINITION TO $MSSQLUser;

USE msdb;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$MSSQLUser')
    CREATE USER $MSSQLUser FOR LOGIN $MSSQLUser;
GRANT EXECUTE ON msdb.dbo.agent_datetime TO $MSSQLUser;
GRANT SELECT ON msdb.dbo.sysjobactivity TO $MSSQLUser;
GRANT SELECT ON msdb.dbo.sysjobservers TO $MSSQLUser;
GRANT SELECT ON msdb.dbo.sysjobs TO $MSSQLUser;
"@
    $cmd.ExecuteNonQuery()
    $conn.Close()
    Write-Host "Usuario '$MSSQLUser' creado con permisos." -ForegroundColor Green
}
catch {
    Write-Host "AVISO: No se pudo crear el usuario en SQL. Revisa manualmente." -ForegroundColor Yellow
    Write-Host $_.Exception.Message
}

# ============================================================
# 6. VERIFICAR
# ============================================================
Write-Host "`n=== Verificación ===" -ForegroundColor Cyan
$pluginPath = Join-Path $AgentInstallDir "zabbix-agent2-plugin-mssql.exe"
if (Test-Path $pluginPath) {
    $ver = (Get-Item $pluginPath).VersionInfo.FileVersion
    Write-Host "Plugin MSSQL: v$ver" -ForegroundColor Green
} else {
    Write-Host "ERROR: No se encuentra el binario del plugin." -ForegroundColor Red
}

Write-Host "`n=== LISTO ===" -ForegroundColor Cyan
Write-Host "Recuerda asignar la plantilla 'MSSQL by Zabbix agent 2' al host en el servidor Zabbix."   
