@echo off
chcp 65001 > nul
cls
color 0A

:: Obter data e hora no padrao ISO 8601 via PowerShell
for /f "tokens=*" %%a in ('powershell.exe -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"') do set TIMESTAMP=%%a
set LOG_FILE=WinLocalRecon_%TIMESTAMP%.log

echo [i] Iniciando a coleta de dados do host...
echo [i] O relatorio sera gerado em: %LOG_FILE%
echo.

:: Cabeçalho do arquivo
echo ============================================================= > %LOG_FILE%
echo        RELATORIO DE AUDITORIA E SISTEMA        >> %LOG_FILE%
echo ============================================================= >> %LOG_FILE%
echo.>> %LOG_FILE%
echo Hostname: %COMPUTERNAME% >> %LOG_FILE%
echo Data: %DATE% >> %LOG_FILE%
echo Hora: %TIME% >> %LOG_FILE%

:: Etapa 2: SO e Processador
echo [+] Coletando informacoes do Sistema Operacional...
echo.>> %LOG_FILE%
echo ============================================================= >> %LOG_FILE%
echo        SISTEMA OPERACIONAL E PROCESSADOR        >> %LOG_FILE%
echo ============================================================= >> %LOG_FILE%
echo.>> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, InstallDate, LastBootUpTime | Format-List" >> %LOG_FILE%

echo [+] Coletando especificacoes do Processador...
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Processor | Select-Object Name, SocketDesignation, NumberOfCores, NumberOfLogicalProcessors | Format-List" >> %LOG_FILE%

echo [V] Etapa 1 e 2 concluidas com sucesso!

:: Etapa 3: Memória RAM e Discos
echo.
echo [+] Coletando informacoes de memoria RAM...
echo.>> %LOG_FILE%
echo ============================================================= >> %LOG_FILE%
echo        MEMÓRIA RAM E ARMAZENAMENTO        >> %LOG_FILE%
echo ============================================================= >> %LOG_FILE%
echo.>> %LOG_FILE%

echo        --- Modulos de Memória RAM --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Capacity, Speed, Manufacturer, PartNumber | Format-Table -AutoSize" >> %LOG_FILE%

echo [+] Coletando discos fisicos e particoes logicas...
echo.>> %LOG_FILE%
echo        --- Discos Físicos --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-CimInstance Win32_DiskDrive | Select-Object Index, Model, Size, InterfaceType | Format-Table -AutoSize" >> %LOG_FILE%

echo.>> %LOG_FILE%
echo        --- Partições Lógicas --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 3' | Select-Object DeviceID, Size, FreeSpace | Format-Table -AutoSize" >> %LOG_FILE%

echo [V] Etapa 3 concluida com sucesso!

:: Etapa 4: Processos e Servicos
echo.
echo [+] Coletando processos em execucao...
echo.>> %LOG_FILE%
echo ============================================================= >> %LOG_FILE%
echo        PROCESSOS E SERVIÇOS        >> %LOG_FILE%
echo ============================================================= >> %LOG_FILE%
echo.>> %LOG_FILE%

echo        --- Processos em Execução --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Process | Select-Object Name, ProcessId, WorkingSetSize | Sort-Object WorkingSetSize -Descending | Format-Table -AutoSize" >> %LOG_FILE%

echo [+] Coletando servicos em execucao no sistema...
echo.>> %LOG_FILE%
echo        --- Serviços Ativos --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Service -Filter \"State = 'Running'\" | Select-Object Name, DisplayName, StartMode | Sort-Object Name | Format-Table -AutoSize" >> %LOG_FILE%

echo [V] Etapa 4 concluida com sucesso!

:: Etapa 5: Softwares Instalados via Registro
echo.
echo [+] Coletando softwares instalados no sistema...
echo.>> %LOG_FILE%
echo ============================================================= >> %LOG_FILE%
echo        SOFTWARES INSTALADOS        >> %LOG_FILE%
echo ============================================================= >> %LOG_FILE%
echo.>> %LOG_FILE%

powershell.exe -NoProfile -Command "$paths = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'; Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName} | Select-Object DisplayName, DisplayVersion, Publisher | Sort-Object DisplayName | Format-Table -AutoSize" >> %LOG_FILE%

echo [V] Etapa 5 concluida com sucesso!

:: Etapa 6: Inicialização e Patches (KBs)
echo.
echo [+] Coletando programas configurados na inicializacao...
echo. >> %LOG_FILE%
echo =================================================== >> %LOG_FILE%
echo              INICIALIZAÇAO E PATCHES                >> %LOG_FILE%
echo =================================================== >> %LOG_FILE%
echo. >> %LOG_FILE%

echo --- Programas na Inicialização --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User | Format-Table -AutoSize" >> %LOG_FILE%

echo [+] Coletando pacotes de atualizacao de seguranca (KBs)...
echo. >> %LOG_FILE%
echo --- Patches e Hotfixes Instalados --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-CimInstance Win32_QuickFixEngineering | Select-Object HotFixID, Description, InstalledOn | Sort-Object InstalledOn -Descending | Format-Table -AutoSize" >> %LOG_FILE%

echo [V] Etapa 6 concluida com sucesso!

:: Etapa 7: Auditoria de Eventos do Sistema
echo.
echo [+] Coletando historico de logs do Event Viewer...
echo. >> %LOG_FILE%
echo =================================================== >> %LOG_FILE%
echo              LOGS E AUDITORIA DE EVENTOS            >> %LOG_FILE%
echo =================================================== >> %LOG_FILE%
echo. >> %LOG_FILE%

echo --- Histórico de Inicialização e Desligamento Limpo --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Id=6005,6006,1074} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName | Format-Table -AutoSize" >> %LOG_FILE%

echo. >> %LOG_FILE%
echo --- Histórico de Desligamentos Inesperados (Quedas/BSOD) --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Id=6008} -MaxEvents 5 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message | Format-Table -AutoSize" >> %LOG_FILE%

echo. >> %LOG_FILE%
echo --- Alterações em Serviços do Sistema (Service Control Manager) --- >> %LOG_FILE%
powershell.exe -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Service Control Manager'; Id=7040} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message | Format-Table -AutoSize" >> %LOG_FILE%

:: Finalização do Script
color 07
echo.
echo ===================================================
echo [V] Coleta completa finalizada com sucesso!
echo [i] O relatorio foi salvo em: %LOG_FILE%
echo ===================================================
echo.
pause