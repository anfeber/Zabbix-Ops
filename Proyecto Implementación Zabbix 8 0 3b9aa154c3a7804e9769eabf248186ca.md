# Proyecto Implementación Zabbix 8.0

- Arquitectura
    - 
    
    ![image.png](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/image.png)
    
- SERVIDOR 1: zbx-db
    
    1. Instalar PostgreSQL 16
    
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    
    dnf -qy module disable postgresql
    
    dnf install -y postgresql16-server
    
    Show more lines
    
    Inicializar: /usr/pgsql-16/bin/postgresql-16-setup initdb
    
    Iniciar: systemctl enable postgresql-16 --now
    
    ---
    
    ## 2. Configurar PostgreSQL para acceso remoto
    
    Editar: 
    
    vi /var/lib/pgsql/16/data/postgresql.conf
    
    Show more lines
    
    Cambiar:
    
    INI
    
    1
    
    listen_addresses='*'
    
    Show more lines
    
    ---
    
    ## 3. Autorizar servidor Zabbix
    
    Editar:
    
    Shell
    
    1
    
    vi /var/lib/pgsql/16/data/pg_hba.conf
    
    Show more lines
    
    Agregar:
    
    INI
    
    1
    
    host    zabbix    zabbix    192.168.1.10/32    scram-sha-256
    
    Show more lines
    
    Donde:
    
    Plain Text
    
    1
    
    192.168.1.10 = IP de zbx-srv
    
    Show more lines
    
    ---
    
    ## 4. Reiniciar PostgreSQL
    
    Shell
    
    1
    
    systemctl restart postgresql-16
    
    Show more lines
    
    ---
    
    ## 5. Crear Base de Datos
    
    Shell
    
    1
    
    sudo -u postgres psql
    
    Show more lines
    
    Crear usuario:
    
    SQL
    
    1
    
    CREATE USER zabbix
    
    2
    
    WITH PASSWORD 'PasswordSeguro';
    
    Show more lines
    
    Crear BD:
    
    SQL
    
    1
    
    CREATE DATABASE zabbix
    
    2
    
    OWNER zabbix;
    
    Show more lines
    
    Permisos:
    
    SQL
    
    1
    
    GRANT ALL PRIVILEGES ON DATABASE zabbix TO zabbix;
    
    Show more lines
    
    Salir:
    
    SQL
    
    1
    
    \q
    
    Show more lines
    
    ---
    
    ## 6. Abrir Firewall
    
    Shell
    
    1
    
    firewall-cmd --permanent --add-port=5432/tcp
    
    2
    
    firewall-cmd --reload
    
    Show more lines
    
    ---
    
    ## 7. Validar escucha
    
    Shell
    
    1
    
    ss -ntlp | grep 5432
    
    Show more lines
    
    Debe mostrar:
    
    Plain Text
    
    1
    
    0.0.0.0:5432
    
    [Guía Definitiva: Instalación de Zabbix 8.0 en Ubuntu Server 22.04 LTS](https://www.linkedin.com/pulse/gu%C3%ADa-definitiva-instalaci%C3%B3n-de-zabbix-80-en-ubuntu-rodr%C3%ADguez-v%C3%A1squez-jb3qe/)
    

[Instalar RockyLinux ](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/Instalar%20RockyLinux%203c1aa154c3a78071a921c40e1c78133f.md)

[Instalar Servidor #1 - DB Postgress](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/Instalar%20Servidor%20#1%20-%20DB%20Postgress%203c2aa154c3a780649129c50695ec9e60.md)

[Instalar Servidor #2 - Frontend y Agent](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/Instalar%20Servidor%20#2%20-%20Frontend%20y%20Agent%203c2aa154c3a780f29e22d4b5e38802f7.md)

[Troubleshoting](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/Troubleshoting%203c3aa154c3a78000b5aee40d131b1ebd.md)

[Instalar Agente Zabbix](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/Instalar%20Agente%20Zabbix%203c3aa154c3a780cd929dcb140d1899b0.md)

[Configuraciones en Zabbix](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/Configuraciones%20en%20Zabbix%203c4aa154c3a7801ba750f64a3fb66838.md)

[Monitoreo MSSQL Server](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/Monitoreo%20MSSQL%20Server%203c8aa154c3a7808e990af2d4cc21106c.md)

[Crear Template, Item y Trigguer](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/Crear%20Template,%20Item%20y%20Trigguer%203c9aa154c3a780c0b535e3105b07b259.md)

[Crear Mapas - Network Maps](Proyecto%20Implementaci%C3%B3n%20Zabbix%208%200/Crear%20Mapas%20-%20Network%20Maps%203caaa154c3a780c8b404dff8c91a1830.md)