<#
.SYNOPSIS
    Instala el plugin MSSQL para Zabbix Agent 2, lo configura
    y crea el usuario de SQL Server para monitoreo.
.NOTES
    Requiere que Zabbix Agent 2 ya esté instalado.
    Ejecutar como Administrador.
.Autor
    - Andrés Felipe Bernal
.Fecha
    - Agosto del 2026
#>

# ============================================================
# PARÁMETROS
# ============================================================
$ZabbixVersion   = "7.4.5"
$MSSQLHost       = "192.168.10.3"
$MSSQLPort       = "1433"
$MSSQLUser       = " zbx_monitor"
$MSSQLPassword   = "'zbx.SQLAudicon#2023$'"
$AgentInstallDir = "C:\Program Files\Zabbix Agent 2"
$PluginMsiPath   = "S:\Options\Zabbix v8.0\zabbix_agent2-7.4.14-windows-amd64-openssl.msi" #"\\fileserver\zabbix\zabbix_agent2_plugins-$ZabbixVersion-windows-amd64.msi"

# ============================================================
# 1. VERIFICAR QUE EL AGENTE ESTÁ INSTALADO
# ============================================================
$agentService = Get-Service -Name "Zabbix Agent 2" -ErrorAction SilentlyContinue
if (-not $agentService) {
    Write-Error "Zabbix Agent 2 no está instalado. Ejecuta primero el script del agente."
    exit 1
}

# ============================================================
# 2. INSTALAR PLUGIN MSSQL
# ============================================================
Write-Host "=== Instalando Plugin MSSQL ===" -ForegroundColor Cyan

Start-Process msiexec.exe -ArgumentList @(
    "/qn",
    "/i `"$PluginMsiPath`"",
    "ADDLOCAL=MssqlPlugin"
) -NoNewWindow -Wait
Write-Host "Plugin MSSQL instalado." -ForegroundColor Green

# ============================================================
# 3. CONFIGURAR mssql.conf
# ============================================================
Write-Host "`n=== Configurando mssql.conf ===" -ForegroundColor Cyan

$PluginsDir = Join-Path $AgentInstallDir "zabbix_agent2.d\plugins.d"
if (-not (Test-Path $PluginsDir)) {
    New-Item -Path $PluginsDir -ItemType Directory -Force | Out-Null
}

# Asegurar Include en zabbix_agent2.conf
$AgentConf = Join-Path $AgentInstallDir "zabbix_agent2.conf"
$includeLine = "Include=$AgentInstallDir\zabbix_agent2.d\plugins.d\*.conf"
if ((Get-Content $AgentConf) -notmatch [regex]::Escape("plugins.d")) {
    Add-Content -Path $AgentConf -Value $includeLine
    Write-Host "Agregada línea Include en zabbix_agent2.conf"
}

$MssqlConfPath = Join-Path $PluginsDir "mssql.conf"
$MssqlConfContent = @"
Plugins.MSSQL.System.Path=$AgentInstallDir\zabbix-agent2-plugin-mssql.exe
Plugins.MSSQL.KeepAlive=300
Plugins.MSSQL.Default.Uri=sqlserver://${MSSQLHost}:$MSSQLPort
Plugins.MSSQL.Default.User=$MSSQLUser
Plugins.MSSQL.Default.Password=$MSSQLPassword
"@
Set-Content -Path $MssqlConfPath -Value $MssqlConfContent -Encoding UTF8
Write-Host "mssql.conf creado en: $MssqlConfPath" -ForegroundColor Green

# ============================================================
# 4. REINICIAR SERVICIO
# ============================================================
Write-Host "`n=== Reiniciando servicio ===" -ForegroundColor Cyan
Restart-Service -Name "Zabbix Agent 2" -Force
Write-Host "Servicio reiniciado." -ForegroundColor Green

# ============================================================
# 5. CREAR USUARIO EN SQL SERVER (OPCIONAL)
# ============================================================
Write-Host "`n=== Creando usuario MSSQL para monitoreo ===" -ForegroundColor Cyan

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
    Write-Host "AVISO: No se pudo crear el usuario. Revisa manualmente." -ForegroundColor Yellow
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
Write-Host "Asignar plantilla 'MSSQL by Zabbix agent 2' al host en Zabbix."   
