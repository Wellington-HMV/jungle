# 🌴 Jungle

[![Website](https://img.shields.io/badge/🌐_Website-jungle-3ddc84?style=flat-square)](https://wellington-hmv.github.io/jungle/)
[![Release](https://img.shields.io/github/v/release/Wellington-HMV/jungle?style=flat-square&color=2bb673)](https://github.com/Wellington-HMV/jungle/releases/latest)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=flat-square&logo=powershell&logoColor=white)](https://github.com/Wellington-HMV/jungle)
[![Platform](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=flat-square&logo=windows&logoColor=white)](https://github.com/Wellington-HMV/jungle)
[![License](https://img.shields.io/github/license/Wellington-HMV/jungle?style=flat-square&color=lightgrey)](LICENSE)

> Mantenha seu Windows **ativo** e seu status do Teams/Slack **verde** — sem mover o cursor, sem instalar nada, direto da bandeja.

**Jungle** é um *keep-alive* / *jiggler* leve escrito em PowerShell puro. Ele emite um pulso de atividade de input em intervalos configuráveis, impedindo o computador de ficar ocioso, a tela de apagar e o seu status de presença de virar "Ausente" — tudo dentro de uma janela de horário que você define (ex.: dias úteis, das 9h às 18h).

Sem `.exe`, sem dependências, sem direitos de administrador.

---

## ✨ Recursos

- 🟢 **Mantém o status verde** (Teams, Slack, etc.) — reseta o *idle timer* do Windows de verdade.
- 🖱️ **Não move o cursor** — usa um pulso relativo `(0,0)`, então seu mouse fica 100% livre.
- 💤 **Impede sleep / tela apagar** via `SetThreadExecutionState` (API oficial de energia).
- 🕘 **Janela de horário** — pulsa só nos dias e horas que você quiser (padrão: Seg–Sex, 9h–18h).
- 📌 **Ícone na bandeja** com status colorido e ligar/desligar em um clique.
- 🚀 **Inicia com o Windows** (opcional, marcável pela interface).
- 🪶 **Leve e transparente** — um único script `.ps1`, fácil de auditar.

---

## 🖼️ Como funciona

| Estado | Quando | Ícone |
|--------|--------|:-----:|
| **ATIVO** | Dentro da janela de horário, pulsando | 🟢 |
| **AGUARDANDO** | Fora do horário / fim de semana | 🟡 |
| **PARADO** | Desativado manualmente | ⚪ |

O app fica **residente** na bandeja o tempo todo, mas só emite pulsos dentro da janela configurada. Ele entra e sai do horário sozinho (checa a cada 20s).

### Por baixo do capô

A presença do Teams/Slack e o bloqueio de tela do Windows são governados pelo **idle timer** do sistema (`GetLastInputInfo`). O detalhe importante:

```text
SetCursorPos(x, y)              → move o cursor, mas NÃO reseta o idle timer  ❌
mouse_event(MOUSEEVENTF_MOVE,0,0) → registra input real, reseta o idle timer  ✅
```

O Jungle usa `mouse_event` com deslocamento `(0,0)`: o Windows contabiliza como atividade de input (status fica verde, tela não apaga), **mas o cursor não se move** — você continua trabalhando normalmente. Em paralelo, `SetThreadExecutionState` garante que o monitor não desligue nem a máquina durma.

---

## 📦 Requisitos

- Windows 10 / 11
- PowerShell 5.1 (Windows PowerShell) **ou** PowerShell 7+ (`pwsh`)
- Nenhum privilégio de administrador

---

## 🚀 Uso rápido

Clone ou baixe o repositório e rode:

```powershell
# na pasta do projeto
powershell -NoProfile -File .\jiggle-gui.ps1
```

A janela abre e o ícone aparece na bandeja (perto do relógio, talvez no menu “▲ mostrar ícones ocultos”).

- **Duplo-clique no ícone** → abre a janela
- **Fechar a janela (X)** → minimiza para a bandeja (não encerra)
- **Botão direito no ícone → Sair** → encerra de vez

### Iniciar minimizado direto na bandeja

```powershell
powershell -NoProfile -WindowStyle Minimized -File .\jiggle-gui.ps1 -Tray
```

---

## ⚙️ Parâmetros

| Parâmetro | Padrão | Descrição |
|-----------|:------:|-----------|
| `-Seconds` | `60` | Intervalo entre pulsos (segundos) |
| `-StartHour` | `9` | Hora de início da janela (24h) |
| `-EndHour` | `18` | Hora de fim da janela (exclusiva) |
| `-AllDays` | *off* | Roda todos os dias (padrão é só Seg–Sex) |
| `-Tray` | *off* | Inicia minimizado na bandeja |

```powershell
# exemplos
.\jiggle-gui.ps1 -StartHour 8 -EndHour 17       # janela das 8h às 17h
.\jiggle-gui.ps1 -AllDays                        # todo dia, inclusive fds
.\jiggle-gui.ps1 -Seconds 30                     # pulso mais frequente
```

---

## 🔁 Iniciar com o Windows

Marque a caixa **“Iniciar com o Windows”** na interface. Ela cria um atalho em:

```
shell:startup
```

apontando direto para o `powershell.exe`/`pwsh.exe` minimizado (sem lançadores ocultos), e o app sobe automaticamente no login.

Para remover, basta desmarcar a caixa.

---

## 📁 Estrutura do projeto

```
jungle/
├── jiggle-gui.ps1      # App principal (GUI + bandeja + janela de horário)
├── watchdog.ps1        # Mantém o app vivo (self-heal sem admin)
├── jiggle.ps1          # Versão CLI mínima (anti-lock por linha de comando)
├── jiggle.bat          # Atalho 1-clique para a versão CLI
├── stop-jiggle.bat     # Encerra tudo (watchdog + app)
└── README.md
```

### 🩺 Auto-recuperação (watchdog)

Quando você marca **“Iniciar com o Windows”**, o atalho aponta para o `watchdog.ps1`, um laço leve que sobe no logon e, a cada 5 minutos, verifica se o app está vivo (via mutex nomeado) — relançando-o caso tenha sido encerrado ou travado. Útil em ambientes **sem permissão de administrador**, onde o Agendador de Tarefas é bloqueado.

Para parar tudo de uma vez (watchdog **e** app), use `stop-jiggle.bat` — senão o watchdog reabre o app.

---

## ❓ FAQ

**O cursor vai ficar pulando na minha tela?**
Não. O pulso é relativo `(0,0)` — registra input sem mover nada.

**Funciona com a tela bloqueada?**
O pulso mantém a sessão ativa antes do bloqueio. Se uma **política corporativa (GPO)** força o bloqueio após X minutos, isso é imposto pelo sistema e foge do escopo da ferramenta.

**Preciso ser administrador?**
Não. Tudo roda no nível do usuário.

**Posso mudar o horário?**
Sim, via `-StartHour` / `-EndHour` / `-AllDays` (veja Parâmetros).

---

## 🛡️ Antivírus / EDR

Ferramentas que **sintetizam input** (mouse/teclado) acionam heurísticas de antivírus e EDR — é o comportamento esperado, pois muitos malwares fazem o mesmo. O Jungle foi escrito de forma transparente (um único `.ps1` auditável, sem lançadores ocultos, sem `-ExecutionPolicy Bypass`), mas, dependendo da sua política de segurança, ele ainda pode ser sinalizado.

Em ambientes **gerenciados/corporativos**, não tente burlar o antivírus — converse com seu time de TI/Segurança sobre uma exceção, ou use um *jiggler de hardware*.

---

## ⚠️ Aviso

Esta ferramenta é fornecida para fins legítimos como **impedir o monitor de apagar**, **manter sessões/downloads ativos** e **evitar bloqueios por ociosidade** durante uso real do computador.

Usar para **simular presença/atividade quando você não está de fato trabalhando** pode violar a política de conduta da sua empresa. Use por sua conta e risco. Os autores não se responsabilizam por uso indevido.

---

## 🤝 Contribuindo

Issues e pull requests são bem-vindos! Ideias: ícone customizado, múltiplas janelas de horário, suporte a teclado (F15) como método alternativo, instalador.

---

## 📄 Licença

[MIT](LICENSE) — faça o que quiser, sem garantias.
