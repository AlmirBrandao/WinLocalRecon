@echo off
chcp 65001 > nul
cls
color 0A

echo [i] Iniciando a coleta de dados do host...
echo.

:: Cabeçalho do arquivo
echo ============================================================= > coleta.txt
echo        RELATORIO DE AUDITORIA E SISTEMA        >> coleta.txt
echo ============================================================= >> coleta.txt
echo.>> coleta.txt
echo Hostname: %COMPUTERNAME% >> coleta.txt
echo Data: %DATE% >> coleta.txt
echo Hora: %TIME% >> coleta.txt

:: Etapa 2: SO e Processador
echo [+] Coletando informacoes do Sistema Operacional...
echo.>> coleta.txt
echo ============================================================= >> coleta.txt
echo        SISTEMA OPERACIONAL E PROCESSADOR        >> coleta.txt
echo ============================================================= >> coleta.txt
echo.>> coleta.txt
powershell.exe -NoProfile -Command "Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, InstallDate, LastBootUpTime | Format-List" >> coleta.txt

echo [+] Coletando especificacoes do Processador...
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Processor | Select-Object Name, SocketDesignation, NumberOfCores, NumberOfLogicalProcessors | Format-List" >> coleta.txt

echo [V] Etapa 1 e 2 concluidas com sucesso!

:: Etapa 3: Memória RAM e Discos
echo.
echo [+] Coletando informacoes de memoria RAM...
echo.>> coleta.txt
echo ============================================================= >> coleta.txt
echo        MEMÓRIA RAM E ARMAZENAMENTO        >> coleta.txt
echo ============================================================= >> coleta.txt
echo.>> coleta.txt

echo        --- Modulos de Memória RAM --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Capacity, Speed, Manufacturer, PartNumber | Format-Table -AutoSize" >> coleta.txt

echo [+] Coletando discos fisicos e particoes logicas...
echo.>> coleta.txt
echo        --- Discos Físicos --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-CimInstance Win32_DiskDrive | Select-Object Index, Model, Size, InterfaceType | Format-Table -AutoSize" >> coleta.txt

echo.>> coleta.txt
echo        --- Partições Lógicas --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 3' | Select-Object DeviceID, Size, FreeSpace | Format-Table -AutoSize" >> coleta.txt

echo [V] Etapa 3 concluida com sucesso!

:: Etapa 4: Processos e Servicos
echo.
echo [+] Coletando processos em execucao...
echo.>> coleta.txt
echo ============================================================= >> coleta.txt
echo        PROCESSOS E SERVIÇOS        >> coleta.txt
echo ============================================================= >> coleta.txt
echo.>> coleta.txt

echo        --- Processos em Execução --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Process | Select-Object Name, ProcessId, WorkingSetSize | Sort-Object WorkingSetSize -Descending | Format-Table -AutoSize" >> coleta.txt

echo [+] Coletando servicos em execucao no sistema...
echo.>> coleta.txt
echo        --- Serviços Ativos --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Service -Filter \"State = 'Running'\" | Select-Object Name, DisplayName, StartMode | Sort-Object Name | Format-Table -AutoSize" >> coleta.txt

echo [V] Etapa 4 concluida com sucesso!

:: Etapa 5: Softwares Instalados via Registro
echo.
echo [+] Coletando softwares instalados no sistema...
echo.>> coleta.txt
echo ============================================================= >> coleta.txt
echo        SOFTWARES INSTALADOS        >> coleta.txt
echo ============================================================= >> coleta.txt
echo.>> coleta.txt

powershell.exe -NoProfile -Command "$paths = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'; Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName} | Select-Object DisplayName, DisplayVersion, Publisher | Sort-Object DisplayName | Format-Table -AutoSize" >> coleta.txt

echo [V] Etapa 5 concluida com sucesso!

:: Etapa 6: Inicialização e Patches (KBs)
echo.
echo [+] Coletando programas configurados na inicializacao...
echo. >> coleta.txt
echo =================================================== >> coleta.txt
echo              INICIALIZAÇAO E PATCHES                >> coleta.txt
echo =================================================== >> coleta.txt
echo. >> coleta.txt

echo --- Programas na Inicialização --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User | Format-Table -AutoSize" >> coleta.txt

echo [+] Coletando pacotes de atualizacao de seguranca (KBs)...
echo. >> coleta.txt
echo --- Patches e Hotfixes Instalados --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-CimInstance Win32_QuickFixEngineering | Select-Object HotFixID, Description, InstalledOn | Sort-Object InstalledOn -Descending | Format-Table -AutoSize" >> coleta.txt

echo [V] Etapa 6 concluida com sucesso!

:: Etapa 7: Auditoria de Eventos do Sistema
echo.
echo [+] Coletando historico de logs do Event Viewer...
echo. >> coleta.txt
echo =================================================== >> coleta.txt
echo              LOGS E AUDITORIA DE EVENTOS            >> coleta.txt
echo =================================================== >> coleta.txt
echo. >> coleta.txt

echo --- Histórico de Inicialização e Desligamento Limpo --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Id=6005,6006,1074} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName | Format-Table -AutoSize" >> coleta.txt

echo. >> coleta.txt
echo --- Histórico de Desligamentos Inesperados (Quedas/BSOD) --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Id=6008} -MaxEvents 5 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message | Format-Table -AutoSize" >> coleta.txt

echo. >> coleta.txt
echo --- Alterações em Serviços do Sistema (Service Control Manager) --- >> coleta.txt
powershell.exe -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Service Control Manager'; Id=7040} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message | Format-Table -AutoSize" >> coleta.txt

:: Finalização do Script
color 07
echo.
echo ===================================================
echo [V] Coleta completa finalizada com sucesso!
echo [i] O relatorio foi salvo em: coleta.txt
echo ===================================================
echo.
pause