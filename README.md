# WinLocalRecon - Automated Local Discovery & Host Triage Tool

## 1. Cabeçalho e Proposta de Valor
* **Nome do Projeto:** WinLocalRecon
* **Linguagem/Tecnologia:** PowerShell / Batch (Chaining híbrido via CMD)
* **Proposta:** Toolset leve e sem dependências externas para reconhecimento local pós-acesso em sistemas Windows. Coleta informações de ambiente, mapeia softwares de defesa (AV/EDR), analisa superfícies de elevação de privilégio (patches faltantes/serviços) e verifica logs de auditoria utilizando exclusivamente ferramentas nativas do sistema operacional (Living off the Land).

---

## 2. Matriz de Requisitos e Mapeamento de Cmdlets

| Módulo de Coleta | Dados Extraídos | Cmdlet / Comando Nativo | Utilidade Ofensiva (Red Team / MITRE ATT&CK) |
| :--- | :--- | :--- | :--- |
| **01. Host & OS Identification** | Nome da máquina, Usuário ativo, Versão e Build do SO | `hostname`, `Win32_OperatingSystem`, `Win32_ComputerSystem` | **T1082 (System Information Discovery):** Mapear a versão exata do sistema para busca de exploits e identificar o usuário em execução. |
| **02. Defensive Software Mapping** | Serviços e processos em execução | `Win32_Process`, `Win32_Service` (`State = 'Running'`) | **T1518.001 (Security Software Discovery):** Identificar antivírus (ex: Kaspersky `avp.exe`), EDRs, Firewalls e agentes de monitoramento antes de executar novas cargas. |
| **03. Environment & Sandbox Check** | CPU, Soquetes, Núcleos, RAM e Discos | `Win32_Processor`, `Win32_PhysicalMemory`, `Win32_DiskDrive`, `Win32_LogicalDisk` | **T1497.001 (Virtualization/Sandbox Evasion: System Checks):** Checar se o ambiente é uma máquina virtual ou Sandbox (pouca RAM, 1 núcleo de CPU, disco pequeno). |
| **04. Patch & PrivEsc Recon** | Pacotes de atualização (KBs) instalados | `Win32_QuickFixEngineering` | **T1082 / T1068 (Patch Discovery for PrivEsc):** Mapear KBs ausentes para identificar vulnerabilidades de elevação local de privilégios (LPE) para `SYSTEM`. |
| **05. Software Surface** | Programas instalados via Registro (32 e 64 bits) | `Get-ItemProperty` em `HKLM:\...\Uninstall\*` | **T1518 (Software Discovery):** Mapear aplicações de terceiros desatualizadas (ex: navegadores, VPNs, utilitários) com vulnerabilidades públicas. |
| **06. Persistence Audit** | Aplicações iniciadas automaticamente com o sistema | `Win32_StartupCommand` | **T1547.001 (Boot or Logon Autostart Execution):** Mapear os locais de inicialização atuais para planejar ou identificar mecanismos de persistência no host. |
| **07. Event Log & Operational Footprint** | Reboots, desligamentos anormais e logs de segurança | `Get-WinEvent` (IDs 6005, 1074, 6008, 7040 e Canais System) | **T1082 / T1562 (Audit & Defense Impairment Check):** Avaliar a atividade do Event Viewer, hábitos de uso da máquina e registros de alterações em serviços do Windows. |

---

## 3. Especificação do Fluxo de Execução (Pseudocódigo)

1. **Inicialização do Ambiente:**
   * Configurar a tabela de códigos do terminal para UTF-8 (`chcp 65001 > nul`) para preservar caracteres e acentuação no relatório gerado.
   * Limpar a tela (`cls`) e definir cores do terminal via `color` para indicação visual do progresso.

2. **Criação do Arquivo de Saída Dinâmico (Padrão Pericial ISO 8601):**
   * Capturar a data e hora em formato ordenável (`YYYY-MM-DD_HH-MM-SS`) invocando o PowerShell (`Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'`).
   * Definir a variável do arquivo de log (`LOG_FILE=WinLocalRecon_YYYY-MM-DD_HH-MM-SS.log`) para garantir a rastreabilidade e evitar a sobrescrita acidental de coletas em auditorias recorrentes no mesmo host.
   * Gravacao do cabeçalho inicial e metadados de execução utilizando o operador de gravação/sobrescrita (`>`).

3. Execução Modularizada do PowerShell:
   * Para cada módulo de coleta (Etapas 01 a 07):
     * Executar a chamada via `powershell.exe -NoProfile -Command "..."`.
     * Utilizar `-NoProfile` para evitar carregamento de perfis locais e acelerar a execução.
     * Redirecionar os dados estruturados de saída appendando no arquivo final (`>>`).

4. **Tratamento de Exceções e Formatação:**
   * Aplicar `-ErrorAction SilentlyContinue` na consulta de chaves do Registro para evitar estouro de erros em chaves inexistentes.
   * Utilizar `Format-Table -AutoSize` e `Format-List` para manter a legibilidade dos dados formatados.

5. **Encerramento:**
   * Restaurar as cores padrão do terminal, notificar o término da coleta e exibir o caminho onde o arquivo `coleta.txt` foi gerado.

   ---

## 4. Roadmap & Próximas Implementações

- [x] **v1.0 - Native Recon Engine:** Coleta autônoma e não invasiva via Batch/PowerShell e WMI/CIM.
- [x] **v1.1 - Dynamic Forensic Logging:** Geração dinâmica de relatório no padrão ISO 8601 (`WinLocalRecon_YYYY-MM-DD_HH-MM-SS.log`) para rastreabilidade forense e não sobrescrita de evidências.
- [ ] **v1.2 - Output Structuring:** Opção para exportar os dados brutos em formato JSON além do relatório TXT.
- [ ] **v2.0 - Offline Vulnerability Engine:**
  - Script parser para consumo do arquivo de log na máquina do analista.
  - Integração automatizada com **WES-NG (Windows Exploit Suggester)** para apontar CVEs de elevação local de privilégios (LPE) com base nas KBs ausentes.
  - Mapeamento automático de aplicações desatualizadas contra a base do **NVD (National Vulnerability Database)**.