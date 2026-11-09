# 🧹 Remove Sleev (sleev.ai) from your system

**A community uninstall guide and automated cleanup tools for the Sleev AI gateway — because [Sleev.ai](https://sleev.ai) doesn't ship one.**

Sleev installs itself on your machine with a single `curl | bash` or PowerShell one-liner, quietly sets up a background gateway service at every login, intercepts your AI traffic, and records all your prompts, completions, and session data locally.

Yet, despite charging users paid subscription fees on their [pricing page](https://sleev.ai/pricing), **there is no uninstall command, no uninstaller executable, no entry in Windows "Installed apps" / "Add or Remove Programs", no package manager uninstall, and no uninstall instructions anywhere on [sleev.ai](https://sleev.ai)**.

This repository fixes that for both **Linux** and **Windows**:

| What you get | Where |
| --- | --- |
| 🤖 Copy-paste prompt for AI coding agents (Windows & Linux) | [§ 1](#1--copy-paste-this-into-your-ai-coding-agent) |
| ⚡ 60-second quick removal | [§ 2](#2--quick-start-60-second-removal) |
| 📜 One-script automated cleanup (Linux bash & Windows PowerShell) | [`uninstall-sleev.sh`](./uninstall-sleev.sh) & [`uninstall-sleev.ps1`](./uninstall-sleev.ps1) — [§ 3](#3--option-a--run-the-uninstall-script) |
| 📋 Full manual step-by-step removal (Linux & Windows) | [§ 4](#4--option-b--manual-step-by-step-no-script) |
| 🔗 What Sleev claims vs. what actually happens | [§ 5](#5--option-c--what-sleev-officially-tells-you-to-do-and-why-it-isnt-an-uninstall) |
| ✅ Verification checklists | [§ 6](#6--verify-sleev-is-gone) |
| 🚨 The hard questions: Why does Sleev charge money for software you can't uninstall? | [§ 7](#7--the-shady-reality-charging-for-software-you-cant-uninstall) |
| 🌱 Free & transparent alternative to Sleev | [§ 8](#8--free-alternative-cmx-compressius-maximus) |
| 📦 What Sleev leaves behind (Linux & Windows tables) | [§ 9](#9--what-sleev-leaves-on-your-system) |
| 🔍 Real-world field notes (Linux & Windows audits) | [§ 10](#10--field-notes-from-real-installations-linux--windows) |

> [!IMPORTANT]
> **Everyone has the fundamental right to remove software from their own computer — easily, completely, and without reverse-engineering detective work.**
> A product that installs in a single command must provide a clean uninstall in a single command. When a vendor charges for software yet deliberately refuses to provide an exit door, this community guide provides it.

---

## 📑 Table of Contents

1. [Copy-paste this into your AI coding agent](#1--copy-paste-this-into-your-ai-coding-agent)
2. [Quick start (60-second removal)](#2--quick-start-60-second-removal)
3. [Option A — Run the uninstall script (Linux & Windows)](#3--option-a--run-the-uninstall-script)
4. [Option B — Manual step-by-step removal](#4--option-b--manual-step-by-step-no-script)
   - [Windows Manual Removal](#windows-powershell-step-by-step)
   - [Linux Manual Removal](#linux-bash-step-by-step)
5. [Option C — What Sleev officially tells you to do (and why it fails)](#5--option-c--what-sleev-officially-tells-you-to-do-and-why-it-isnt-an-uninstall)
6. [Verify Sleev is gone](#6--verify-sleev-is-gone)
7. [The shady reality: Charging for software you can't uninstall](#7--the-shady-reality-charging-for-software-you-cant-uninstall)
8. [Free alternative: CMX (Compressius Maximus)](#8--free-alternative-cmx-compressius-maximus)
9. [What Sleev leaves on your system (Filesystem footprint)](#9--what-sleev-leaves-on-your-system)
10. [Field notes from real installations (Linux & Windows)](#10--field-notes-from-real-installations-linux--windows)
11. [Safety notes & limitations](#11--safety-notes--limitations)
12. [FAQ](#12--faq)

---

## 1. 🤖 Copy-paste this into your AI coding agent

Using **Claude Code, Cursor, Codex, OpenCode, Antigravity, Windsurf, or any other AI coder?**
Copy the relevant block below and paste it as your prompt. Your AI agent will execute the removal cleanly and repair your development environment.

### 🪟 For Windows (PowerShell)

````text
TASK: Completely remove the "Sleev" / "sleev.ai" software, its background gateway, and all remnants from this Windows PC.

First, read the removal guide:
- If this repository is cloned locally, read README.md and run .\uninstall-sleev.ps1 -Yes.
- Otherwise fetch https://raw.githubusercontent.com/administrakt0r/sleev-ai-uninstall/main/README.md and follow it.

Execute the cleanup steps in PowerShell:
1. Close all browsers (Chrome, Edge, Brave, Firefox) so site data is unlocked.
2. Terminate all Sleev processes:
     Get-Process | Where-Object { $_.ProcessName -match "sleev|sleeve" } | Stop-Process -Force -ErrorAction SilentlyContinue
3. Delete the Windows Scheduled Task:
     Unregister-ScheduledTask -TaskName "SleeveGateway" -Confirm:$false -ErrorAction SilentlyContinue
   (If this fails due to admin privileges, instruct the user to run: Unregister-ScheduledTask -TaskName "SleeveGateway" -Confirm:$false in an elevated terminal).
4. If installed globally via npm, remove the npm package:
     npm uninstall -g sleev
5. Permanently remove all Sleev application files, multi-version gateway binaries, SQLite databases, and logs:
     Remove-Item -Path "$env:USERPROFILE\.local\bin\sleev.exe", "$env:USERPROFILE\.local\state\sleev", "$env:LOCALAPPDATA\sleev", "$env:LOCALAPPDATA\sleev-gateway", "$env:APPDATA\sleev", "$env:APPDATA\ai.opencode.desktop\sleev" -Recurse -Force -ErrorAction SilentlyContinue
     Get-ChildItem -Path "$env:LOCALAPPDATA\Temp" -Filter "_MEI*" -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName "*sleeve*") } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
6. Delete browser IndexedDB site data containing "sleev" under Google Chrome, Microsoft Edge, Brave, and Mozilla Firefox:
     Get-ChildItem -Path "$env:LOCALAPPDATA\Google\Chrome\User Data", "$env:LOCALAPPDATA\Microsoft\Edge\User Data", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data", "$env:APPDATA\Mozilla\Firefox\Profiles" -Recurse -Filter "*sleev*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
7. REPAIR AI HARNESS CONFIGS (CRITICAL):
   Sleev rewrites coding tool configs to route through 127.0.0.1:17321. Revert them so tools don't fail:
   - Check and clean ~/.codex/config.toml: delete [model_providers.sleev] and its headers.
   - Check and clean ~/.config/opencode/opencode.jsonc: remove Sleev proxy baseURL (127.0.0.1:17321) and sleev-provider headers.
   - Check Claude Code (~/.claude.json, ~/.claude) or other agents for references to 17321 or sleev.
8. Verify removal:
     Get-Command sleev -ErrorAction SilentlyContinue          # must return nothing
     Get-NetTCPConnection -LocalPort 17321 -ErrorAction SilentlyContinue # must return nothing
     Get-ChildItem -Path "$env:LOCALAPPDATA", "$env:APPDATA" -Filter "*sleev*" -Recurse -Depth 2 -ErrorAction SilentlyContinue # must return nothing
````

### 🐧 For Linux (Bash)

````text
TASK: Completely remove the "Sleev" / "sleev.ai" software, its background gateway service, and all remnants from this Linux computer.

First, read the removal guide:
- If this repository is cloned locally, run ./uninstall-sleev.sh --yes.
- Otherwise fetch https://raw.githubusercontent.com/administrakt0r/sleev-ai-uninstall/main/README.md and follow it.

Execute the cleanup steps in Bash:
1. Close all browsers (Chrome, Chromium, Brave, Firefox).
2. Stop and disable the background user service:
     systemctl --user disable --now sleeve-gateway.service 2>/dev/null
     rm -f ~/.config/systemd/user/sleeve-gateway.service ~/.config/systemd/user/default.target.wants/sleeve-gateway.service
     systemctl --user daemon-reload 2>/dev/null
3. Remove CLI binary and npm package:
     rm -f ~/.local/bin/sleev
     npm uninstall -g sleev 2>/dev/null || true
4. Remove data directories, SQLite databases, logs, and cache:
     rm -rf ~/.config/sleev ~/.local/share/sleev ~/.local/state/sleev ~/.cache/sleev-gateway
5. Remove browser IndexedDB site data:
     find ~/.config/google-chrome ~/.config/chromium ~/.config/BraveSoftware ~/.mozilla/firefox -depth -iname '*sleev*' -exec rm -rf {} + 2>/dev/null
6. Repair AI harness configs (Claude Code, OpenCode, Codex):
     Find any configs pointing to 127.0.0.1:17321 using:
       grep -rIl -e sleev -e 17321 ~/.claude ~/.claude.json ~/.config/opencode ~/.codex 2>/dev/null
     and remove the Sleev proxy entries so traffic goes directly to upstream model providers.
7. Verify removal:
     command -v sleev                                         # must return nothing
     systemctl --user status sleeve-gateway.service 2>&1      # must show not-found
     find ~ -maxdepth 4 -iname '*sleev*' 2>/dev/null          # must return nothing
````

---

## 2. ⚡ Quick start (60-second removal)

> [!WARNING]
> Cleanup **permanently deletes** Sleev's local SQLite session/message database, tokens, logs, multi-version binaries, and browser storage. **No backup is made.**

### Windows

Close your browsers, open **PowerShell**, navigate to this repo folder, and run:

```powershell
.\uninstall-sleev.ps1 -DryRun   # 1. Preview what will be removed
.\uninstall-sleev.ps1           # 2. Delete everything (prompts: REMOVE SLEEV)
```

*(Or pass `-Yes` to run unattended).*

### Linux

Close your browsers, open a terminal, and run:

```bash
./uninstall-sleev.sh --dry-run   # 1. Preview what will be removed
./uninstall-sleev.sh             # 2. Delete everything (prompts: REMOVE SLEEV)
```

---

## 3. 📜 Option A — Run the uninstall script

We provide reviewed, open scripts for both operating systems:
- **Windows:** [`uninstall-sleev.ps1`](./uninstall-sleev.ps1) (PowerShell)
- **Linux:** [`uninstall-sleev.sh`](./uninstall-sleev.sh) (Bash)

Both scripts are safe, transparent, and non-destructive to unrelated files:
- ✅ **No network access** — never phones home to Sleev or any external server
- ✅ **Dry-run mode** — lets you inspect every targeted file before anything is touched
- ✅ **Scoped** — only targets directories, files, tasks, and packages explicitly identified as Sleev
- ✅ **Self-verifying** — performs an immediate post-removal audit to ensure nothing survived

```powershell
# Windows: download and run directly
Invoke-WebRequest -Uri https://raw.githubusercontent.com/administrakt0r/sleev-ai-uninstall/main/uninstall-sleev.ps1 -OutFile uninstall-sleev.ps1
powershell -ExecutionPolicy Bypass -File .\uninstall-sleev.ps1
```

```bash
# Linux: download and run directly
curl -fsSL https://raw.githubusercontent.com/administrakt0r/sleev-ai-uninstall/main/uninstall-sleev.sh -o uninstall-sleev.sh
chmod +x uninstall-sleev.sh
./uninstall-sleev.sh
```

---

## 4. 📋 Option B — Manual step-by-step (no script)

If you prefer to run commands manually one by one without executing scripts, use the instructions below for your platform.

### Windows PowerShell (Step-by-Step)

#### 1. Terminate all Sleev processes
```powershell
Get-Process | Where-Object { $_.ProcessName -match "sleev|sleeve" } | Stop-Process -Force -ErrorAction SilentlyContinue
```

#### 2. Close Web Browsers
Close Google Chrome, Microsoft Edge, Brave, and Mozilla Firefox so that their LevelDB/IndexedDB site databases are unlocked.

#### 3. Delete the Windows Logon Scheduled Task
Sleev installs a task called `SleeveGateway` set to run silently at every user logon:
```powershell
Unregister-ScheduledTask -TaskName "SleeveGateway" -Confirm:$false
```
*(Note: If Sleev created this task during an elevated setup, running this command in an Administrator PowerShell window or running `schtasks /Delete /TN "SleeveGateway" /F` may be required).*

#### 4. Uninstall global npm package (if present)
```powershell
npm uninstall -g sleev
```

#### 5. Delete Sleev application directories, SQLite databases, and executables
Sleev scatters multi-version gateway binaries, logs, and session databases across your profile:
```powershell
Remove-Item -Path "$env:USERPROFILE\.local\bin\sleev.exe" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\.local\state\sleev" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\sleev" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\sleev-gateway" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\sleev" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\ai.opencode.desktop\sleev" -Recurse -Force -ErrorAction SilentlyContinue
```

#### 6. Delete temporary distribution folders
```powershell
Get-ChildItem -Path "$env:LOCALAPPDATA\Temp" -Filter "_MEI*" -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName "*sleeve*") } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
```

#### 7. Remove Sleev browser site data
```powershell
Get-ChildItem -Path "$env:LOCALAPPDATA\Google\Chrome\User Data", "$env:LOCALAPPDATA\Microsoft\Edge\User Data", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data", "$env:APPDATA\Mozilla\Firefox\Profiles" -Recurse -Filter "*sleev*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
```

#### 8. Repair AI coding agent configurations (CRITICAL)
Sleev silently modifies your AI coding assistants to route API calls into its local port `17321`. When you remove Sleev, these tools will fail to connect until restored:
- **Codex (`~/.codex/config.toml`):** Delete the `[model_providers.sleev]` block and its `[model_providers.sleev.http_headers]`.
- **OpenCode (`~/.config/opencode/opencode.jsonc`):** Remove any provider configuration blocks where `baseURL` is set to `http://127.0.0.1:17321` and remove the `sleev-provider` headers so OpenCode speaks directly to upstream providers.
- **Claude Code (`~/.claude.json` / `~/.claude`):** Inspect for any base URL pointing to `127.0.0.1:17321` and remove it.

---

### Linux Bash (Step-by-Step)

#### 1. Close your browsers
Close Chrome, Chromium, Brave, and Firefox so local databases are not locked.

#### 2. Stop and delete the systemd user service
```bash
systemctl --user disable --now sleeve-gateway.service 2>/dev/null
rm -f ~/.config/systemd/user/sleeve-gateway.service
rm -f ~/.config/systemd/user/default.target.wants/sleeve-gateway.service
systemctl --user daemon-reload 2>/dev/null
```

#### 3. Remove the CLI binary and npm packages
```bash
rm -f ~/.local/bin/sleev
npm uninstall -g sleev 2>/dev/null || true
```

#### 4. Delete config, session databases, state, and logs
```bash
rm -rf ~/.config/sleev ~/.local/share/sleev ~/.local/state/sleev ~/.cache/sleev-gateway
```

#### 5. Repair AI coding agent configurations
Search for remaining proxy overrides:
```bash
grep -rIl -e sleev -e 17321 ~/.claude ~/.claude.json ~/.config/opencode ~/.codex 2>/dev/null
```
Edit the reported files and remove the `127.0.0.1:17321` proxy overrides and `sleev-` headers.

#### 6. Delete browser IndexedDB site data
```bash
find ~/.config/google-chrome ~/.config/chromium ~/.config/BraveSoftware \
     ~/.var/app/org.chromium.Chromium ~/.var/app/com.google.Chrome \
     ~/.var/app/com.brave.Browser ~/.mozilla/firefox \
     -depth -iname '*sleev*' -exec rm -rf {} + 2>/dev/null
```

---

## 5. 🔗 Option C — What Sleev officially tells you to do (and why it isn't an uninstall)

As verified across [sleev.ai/docs](https://sleev.ai/docs), [sleev.ai/docs/faq](https://sleev.ai/docs/faq), and [sleev.ai/docs/config/deconfigure](https://sleev.ai/docs/config/deconfigure), the entirety of Sleev's official "exit strategy" is:

| Officially Documented by Sleev | What it Actually Does | What it Leaves Behind on Disk |
| --- | --- | --- |
| **FAQ:** *"How do I stop using Sleev?"* → "remove the Sleev-specific entries from your harness's config file… open the sleev TUI and sign out" | Asks the user to manually edit raw JSON/TOML files and interact with a terminal UI | Everything: binary, background services/tasks, SQLite database, HTTP logs, browser caches |
| **Deconfigure:** `sleev auth logout` | Attempts to invalidate remote auth token and stop local service | **Fails completely on Windows** if run unelevated (crashes with Task Scheduler access denied). On all platforms, leaves executables, local session databases, HTTP request dumps, and browser site data completely intact. |
| **Harness Disable:** `sleev harness <name> disable` | Removes routing entry from one single tool | All background software, scheduled tasks, databases, and other harnesses remain untouched |
| **Actual Uninstaller:** — | **DOES NOT EXIST.** | The entire software suite |

> [!CAUTION]
> **Signing out is NOT uninstalling.**
> Sleev's documentation conflates "signing out of an account" with "removing software". When you sign out, the multi-megabyte binaries remain, the logon startup persistence remains, the unencrypted local database of your conversations remains, and hundreds of JSON logs of your source code and API exchanges remain on your hard drive.

---

## 6. ✅ Verify Sleev is gone

Run these checks after performing the cleanup. Each check should return empty or confirm the resource is absent.

### On Windows (PowerShell)
```powershell
Get-Command sleev -ErrorAction SilentlyContinue             # Must output nothing
Get-ScheduledTask -TaskName "SleeveGateway" -ErrorAction SilentlyContinue # Must output nothing
Get-NetTCPConnection -LocalPort 17321 -ErrorAction SilentlyContinue       # Must output nothing
Get-ChildItem "$env:LOCALAPPDATA\sleev", "$env:APPDATA\sleev" -ErrorAction SilentlyContinue # Must output nothing
```

### On Linux (Bash)
```bash
command -v sleev                                     # Must output nothing
systemctl --user status sleeve-gateway.service 2>&1  # Must say "Unit sleeve-gateway.service could not be found."
systemctl --user is-enabled sleeve-gateway.service   # Must say "not-found"
find ~ -maxdepth 4 -iname '*sleev*' 2>/dev/null      # Must output nothing
```

---

## 7. 🚨 The shady reality: Charging for software you can't uninstall

Why does this repository exist? Why did the community have to write removal scripts and reverse-engineer directory structures for a commercial AI developer tool?

Because **[Sleev.ai](https://sleev.ai)** built a commercial product that aggressively inserts itself into developer workflows, charges users via subscription billing, yet **deliberately omits any mechanism to uninstall it**.

### 1. The Blatant Asymmetry: 1-Second Install vs. Impossible Uninstall

- **To install Sleev:** [sleev.ai](https://sleev.ai) provides a frictionless one-line command (`curl -fsSL https://sleev.ai/install.sh | bash` or a PowerShell equivalent or `npm install -g sleev`). A novice can install it in five seconds without typing a password.
- **To uninstall Sleev:** There is **no command**. There is no `--uninstall` flag. There is no `sleev uninstall`. There is no uninstaller binary. There is no documentation page. There is no entry in Windows Settings > Installed Apps.

This asymmetry is not an oversight. In modern software engineering, nobody accidentally forgets to write an uninstaller while simultaneously building cross-platform daemon management, multi-version update pipelines, WorkOS enterprise authentication, SQLite schema migrations, and a Stripe payment integration. **Omitting the uninstaller is a dark pattern designed to prevent churn through artificial friction.**

### 2. You Want to Charge People Money, But Won't Let Them Uninstall?

Look at [sleev.ai/pricing](https://sleev.ai/pricing). Sleev is not a freeware hobby script; it is a venture-backed commercial product charging users monthly fees for context compression on Pro models.

How can a company take credit card payments for software that:
- Cannot be uninstalled natively through the user's operating system?
- Cannot be uninstalled via any option in its own settings or CLI?
- Does not even provide a guide on its website explaining what files it created?

Selling commercial software without an uninstallation path is unacceptable in enterprise and consumer software alike. It violates basic software hygiene and resembles Potentially Unwanted Programs (PUPs) from the adware era.

### 3. A Massive Security Concern & Corporate Liability

Sleev is not an isolated utility; it operates as a **local shadow proxy**:
1. **Plaintext Interception of Intellectual Property:** Sleev sits between your IDE (OpenCode, Codex, Claude Code) and your LLM provider, listening on port `17321`. Every line of proprietary source code, every API key, every database credential, and every architectural plan you send to an AI model flows through Sleev's gateway.
2. **Gigabytes of Unencrypted Session Dumps:** In real-world installations, Sleev's `debug-logs/http` directory accumulates **thousands of unencrypted JSON files** containing the exact payloads of your prompts and model responses. Even when Sleev's command passes `--redact-logs` and `--auto-clear-logs`, raw request bodies are stored in plaintext on disk.
3. **Local SQLite Surveillance Database:** Sleev stores your session history, message transcripts, token counts, and tool invocations in a local SQLite database (`sleeve.sqlite`).
4. **Environment Sabotage (Hostage Architecture):** When Sleev installs, it silently rewrites your developer tool configs (`opencode.jsonc`, `config.toml`) to route all AI traffic to `127.0.0.1:17321`. If a user attempts to delete the Sleev executable or stop the service, their entire AI coding environment immediately stops working with network failure errors. Users who don't know how to hand-edit internal agent configs are forced to keep Sleev running just so their tools work.
5. **Enterprise Compliance Nightmare:** If you operate under **SOC 2, ISO 27001, HIPAA, or GDPR** (e.g. the Right to Erasure / Right to be Forgotten), installing Sleev is an immediate compliance violation. You cannot certify data hygiene or clean offboarding on employee workstations when third-party software persists background services that record prompt history with zero supported decommissioning mechanism.

### 4. The Legal Hypocrisy: Demanding You Do What They Won't Let You Do

Read Sleev's own legal documents:
- [Sleev Terms of Service](https://sleev.ai/terms)
- [Sleev End User License Agreement (EULA)](https://sleev.ai/eula)

Their legal agreements explicitly state that upon termination of your account or subscription, **"you must immediately stop using and uninstall Sleev from all devices."**

**How can you legally demand that a customer uninstall your software when you refuse to provide an uninstaller or instructions on how to do so?**
You are imposing a contractual obligation on your users that you have deliberately engineered to be impossible without community-authored guides.

---

## 8. 🌱 Free alternative: CMX (Compressius Maximus)

If you need AI-context token compression to cut your API costs, you do not need to tolerate dark patterns or closed traps. **[CMX (Compressius Maximus)](https://compressi.us)** is a free, transparent alternative:

> *"CMX compresses repeated context on your machine before your coding agent sends it to your model provider. Use fewer input tokens and reduce API costs when compression is worthwhile. Free to use with Codex, OpenCode, and other supported agents."* — [compressi.us](https://compressi.us)

| Feature | **Sleev** (sleev.ai) | **CMX (Compressius Maximus)** |
| --- | --- | --- |
| **Pricing** | Paid tier on [sleev.ai/pricing](https://sleev.ai/pricing) when using Pro models | **Free to use** — *"No subscriptions, no paid plans."* |
| **Account Required** | Yes (WorkOS / Sleev account) | **No** — works completely locally without an account |
| **Data Retention** | Heavy unencrypted HTTP request dumps, SQLite database, tracking logs | Local gateway (`127.0.0.1:17322`), credentials and prompts stay in your control |
| **Uninstaller** | ❌ **NONE** (No command, no docs, no OS integration) | ✅ **[Documented Uninstall Page](https://docs.compressi.us)** and CLI removal commands |
| **Integrity** | Locks AI tool configs to its port; breaks tools on exit | Documents exactly how configurations work and how to revert them |

**A product that openly documents how to uninstall itself is a product that respects you as the owner of your computer.**

Website: [compressi.us](https://compressi.us) · Documentation: [docs.compressi.us](https://docs.compressi.us)

---

## 9. 📦 What Sleev leaves on your system

When Sleev installs, it creates files across several hidden paths. Below is the complete footprint our cleanup tools target:

### Windows Paths

| Path | Description |
| --- | --- |
| `Task Scheduler: \SleeveGateway` | Background task configured to launch `sleeve-gateway.exe` at every user logon |
| `%LOCALAPPDATA%\sleev\` | SQLite database (`sleeve.sqlite`), Task definition (`sleeve-gateway-task.xml`), models cache (`models.dev.json`), tracking data |
| `%LOCALAPPDATA%\sleev-gateway\` | Multi-version binary cache (`1.7.7`, `1.7.9`, `1.8.3`, `1.8.10`...) containing ~75 MB `sleeve-gateway.exe` copies (>300 MB of duplicate executables) |
| `%APPDATA%\sleev\` | Gateway configuration (`gateway.json`), authentication tokens (`cli-auth.json`, `workos.json`, `config.json`) |
| `%APPDATA%\ai.opencode.desktop\sleev\` | CLI lifecycle and debug logs |
| `%USERPROFILE%\.local\bin\sleev.exe` | Main Sleev CLI binary |
| `%USERPROFILE%\.local\state\sleev\` | Runtime state containing active daemon PID and port (`gateway-runtime.json`) |
| `%APPDATA%\npm\sleev*` | Global npm executable wrappers (`sleev`, `sleev.cmd`, `sleev.ps1`) |
| `%LOCALAPPDATA%\Google\Chrome\...\IndexedDB\` | `https_sleev.ai_0.indexeddb.leveldb` browser storage |
| AI tool configurations | `~/.codex/config.toml` (`[model_providers.sleev]`) and `~/.config/opencode/opencode.jsonc` (proxy rewrites to `127.0.0.1:17321`) |

### Linux Paths

| Path | Description |
| --- | --- |
| `~/.config/systemd/user/sleeve-gateway.service` | Systemd user service unit running the background gateway |
| `~/.config/systemd/user/default.target.wants/` | Enablement symlink ensuring the service launches at login |
| `~/.local/bin/sleev` | Sleev CLI binary |
| `~/.config/sleev/` | Configuration, WorkOS credentials, install ID, control endpoint URL |
| `~/.local/share/sleev/` | Session and message SQLite database (`sleeve.sqlite`) |
| `~/.local/state/sleev/` | Runtime state, credential helpers, token records, debug HTTP logs |
| `~/.cache/sleev-gateway/` | Gateway cache |
| Browser profile directories | Sleev-named IndexedDB site databases under Chrome, Chromium, Brave, and Firefox |
| AI tool configurations | Proxy redirections in `~/.claude.json`, `~/.config/opencode`, `~/.codex` |

---

## 10. 🔍 Field notes from real installations (Linux & Windows)

These notes reflect direct technical findings from inspecting real-world developer workstations where Sleev was installed.

### Windows 10/11 Audit (November 2026)

- **Uninstaller Status:** Complete absence in Windows Settings (`ms-settings:appsfeatures`) and Registry uninstall keys (`HKCU` and `HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall`). No `uninstall.exe` or `unins000.exe` exists in any Sleev directory.
- **Logon Persistence via Task Scheduler:** Sleev registers a scheduled task named `SleeveGateway` set to run with `LogonTrigger` on the user account. The action launches `sleeve-gateway.exe` with arguments specifying local binding on `127.0.0.1:17321` and pointing to SQLite databases in `AppData\Local\sleev`.
- **Admin Lock on Task Deletion:** The scheduled task was written to the root Task Scheduler folder with permissions that prevent unprivileged removal; executing `sleev auth logout` as a standard user fails with `ERROR: Access is denied` because Sleev's own CLI fails to deregister its task!
- **Bloated Gateway Versions:** Sleev's auto-updater downloads whole ~75 MB executables for each version into separate subfolders (`AppData\Local\sleev-gateway\1.7.7`, `1.7.9`, `1.8.3`, `1.8.10`) without purging older builds, silently consuming hundreds of megabytes.
- **Aggressive Config Hijacking:** Sleev modified `~/.config/opencode/opencode.jsonc` by wrapping **11 different AI model providers** (`opencode-go`, `openrouter`, `anthropic`, `openai`, `google`, `copilot`, `mimo`, `moonshotai`, etc.) with proxy headers and redirecting their `baseURL` to `http://127.0.0.1:17321`. In `~/.codex/config.toml`, it added custom model providers pointing to its local port.
- **Plaintext Payload Dumps:** Sleev stored hundreds of full HTTP conversations under `AppData\Local\sleev\gateway\1.8.10\debug-logs\http\...` formatted as canonical request/response JSON files detailing full developer prompts and code generation completions.

### Linux Audit (September 2026)

- **Systemd User Daemon:** Created `sleeve-gateway.service` enabled via `default.target.wants` with `Restart=on-failure` and a 2-second restart delay.
- **Local SQLite Data:** `sleeve.sqlite` retained over 119 sessions, 18,554 message records, and 6,305 tracking rows.
- **HTTP Debug Logs:** `debug-logs/http` contained 784 JSON files totaling ~66.4 MB of recorded traffic despite `--redact-logs` and `--auto-clear-logs` arguments being passed to the daemon.
- **No Package Manager Registration:** No `.deb`, `.rpm`, Flatpak, or Snap registration; purely loose binaries in `~/.local/bin`.

---

## 11. ⚠ Safety notes & limitations

- **Destructive Deletion:** Running these scripts permanently removes Sleev's local SQLite database, tokens, logs, and cache. No backup is made.
- **API Key Revocation:** If you entered private API keys into Sleev's interface or CLI, deleting the local software does not invalidate those keys on the provider's servers. Log in to Anthropic, OpenAI, OpenRouter, or Google AI Studio and rotate your API keys.
- **Close Browsers First:** Chrome, Edge, and Firefox lock their IndexedDB database files while running. Close your browsers before running the cleanup scripts so site data can be unlocked and deleted.
- **Repair Your Tool Configs:** If your coding assistant (OpenCode, Codex, Claude Code) gives network errors after uninstalling Sleev, check its config file (e.g. `~/.config/opencode/opencode.jsonc` or `~/.codex/config.toml`) and remove the Sleev proxy (`127.0.0.1:17321`) entries.

---

## 12. ❓ FAQ

<details>
<summary><b>Why doesn't Sleev show up in Windows "Add or Remove Programs"?</b></summary>
Because Sleev does not register with Windows Installer or the Windows Registry uninstall keys (<code>HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall</code>). It simply unpacks binaries into AppData, registers a Scheduled Task, and leaves no native operating system uninstall hook.
</details>

<details>
<summary><b>Why does <code>sleev auth logout</code> fail on Windows?</b></summary>
When Sleev registers its <code>SleeveGateway</code> task, it often does so in a way that requires Administrator elevation to modify. When you run <code>sleev auth logout</code> as a normal user, Sleev attempts to reconfigure Task Scheduler and crashes with <code>ERROR: Access is denied</code>.
</details>

<details>
<summary><b>Does Sleev have an official uninstall command?</b></summary>
No. As of late 2026, there is no <code>sleev uninstall</code> command in their CLI, no uninstall script, and no removal guide anywhere on <a href="https://sleev.ai">sleev.ai</a>.
</details>

<details>
<summary><b>Is signing out enough?</b></summary>
No. Signing out leaves the background binaries, the logon service/task, the multi-megabyte SQLite database containing your past sessions, and all HTTP debug logs on your system.
</details>

<details>
<summary><b>Why did my AI coding tools break after deleting Sleev?</b></summary>
Because Sleev rewrote your AI tool configuration files (such as <code>~/.config/opencode/opencode.jsonc</code> or <code>~/.codex/config.toml</code>) to route all requests to Sleev's local port (<code>127.0.0.1:17321</code>). Once Sleev is gone, the proxy is dead. Follow Step 8 in the manual instructions or use our scripts to clean those config files.
</details>

<details>
<summary><b>Is Sleev malware?</b></summary>
We do not label it malware, but it exhibits classic Potentially Unwanted Program (PUP) behaviors: unannounced background persistence, intercepting network traffic on local ports, logging sensitive developer code to unencrypted local files, hijacking tool configurations, and providing zero uninstallation mechanism while charging subscription fees.
</details>

---

## 🔗 Share this guide

If Sleev's lack of an uninstaller frustrated you, help other developers find this solution:
- **Star ⭐ this repository** on GitHub so it ranks at the top of search results.
- Share the link with developers who value control over their machines:
  `https://github.com/administrakt0r/sleev-ai-uninstall`

---

<div align="center">

**Software you can't remove is software you don't control.**

*Independent community project. Not affiliated with [Sleev.ai](https://sleev.ai). If Sleev ever builds a proper, native uninstaller, open an issue and we will gladly link to it.*

</div>
