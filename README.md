# 🧹 Remove Sleev (sleev.ai) from your system

**A community uninstall guide for the Sleev AI gateway — because Sleev.ai doesn't ship one.**

Sleev installs itself on your machine with a single `curl | bash` one-liner, runs a background
gateway service at every login, and stores your AI session data locally. But **there is no
uninstall command, no uninstall page, and no uninstall instructions anywhere on sleev.ai** —
checked on **5 October 2026** (see [§ 7](#7--the-shady-part-install-is-one-command-uninstall-is-a-secret)).

This repository fixes that:

| What you get | Where |
| --- | --- |
| 🤖 Copy-paste prompt for AI coding agents | [§ 1](#1--copy-paste-this-into-your-ai-coding-agent) |
| ⚡ 60-second removal | [§ 2](#2--quick-start-60-second-removal) |
| 📜 A reviewed one-script cleanup (Linux) | [`uninstall-sleev.sh`](./uninstall-sleev.sh) — [§ 3](#3--option-a--run-the-uninstall-script) |
| 📋 Full manual step-by-step removal | [§ 4](#4--option-b--manual-step-by-step-no-script) |
| ✅ Verification checklist | [§ 6](#6--verify-sleev-is-gone) |
| 🔍 Field notes from a real installation | [§ 9](#9--field-notes-from-a-real-installation-september-2026) |

> [!IMPORTANT]
> **Everyone deserves the right to remove software from their own computer — easily, and without
> technical knowledge.** A product that installs in one command must uninstall in one command.
> When the developer won't provide that, this guide does.

---

## 📑 Table of Contents

1. [Copy-paste this into your AI coding agent](#1--copy-paste-this-into-your-ai-coding-agent)
2. [Quick start (60-second removal)](#2--quick-start-60-second-removal)
3. [Option A — Run the uninstall script](#3--option-a--run-the-uninstall-script)
4. [Option B — Manual step-by-step (no script)](#4--option-b--manual-step-by-step-no-script)
5. [Option C — What Sleev officially tells you to do (and why it isn't an uninstall)](#5--option-c--what-sleev-officially-tells-you-to-do-and-why-it-isnt-an-uninstall)
6. [Verify Sleev is gone](#6--verify-sleev-is-gone)
7. [The shady part: install is one command, uninstall is a secret](#7--the-shady-part-install-is-one-command-uninstall-is-a-secret)
8. [What Sleev leaves on your system](#8--what-sleev-leaves-on-your-system)
9. [Field notes from a real installation (September 2026)](#9--field-notes-from-a-real-installation-september-2026)
10. [Safety notes & limitations](#10--safety-notes--limitations)
11. [FAQ](#11--faq)

---

## 1. 🤖 Copy-paste this into your AI coding agent

Using **Claude Code, Cursor, OpenCode, Codex, Windsurf, or any other AI coder?**
Copy the block below and paste it as your prompt. The agent will read this guide and remove
Sleev completely — even though Sleev provides no uninstaller.

````text
TASK: Completely remove the "Sleev" / "sleev.ai" AI gateway software from this computer.

First, read the removal guide:
- If this repository is cloned locally, read its README.md.
- Otherwise fetch https://raw.githubusercontent.com/administrakt0r/sleev-ai-uninstall/main/README.md
  (repo: https://github.com/administrakt0r/sleev-ai-uninstall) and follow it.

Then remove Sleev. It installs per-user on Linux (no sudo needed). In short:

1. Close all browsers (Chrome/Chromium/Brave/Firefox) before touching browser data.

2. If the CLI still exists, try the official deconfigure first:
     ~/.local/bin/sleev auth logout    # stops gateway, deconfigures AI harnesses
   (If the binary is missing or errors, continue anyway.)

3. Stop and delete the background service:
     systemctl --user disable --now sleeve-gateway.service 2>/dev/null
     rm -f ~/.config/systemd/user/sleeve-gateway.service
     rm -f ~/.config/systemd/user/default.target.wants/sleeve-gateway.service
     systemctl --user daemon-reload 2>/dev/null

4. Delete Sleev's files (delete ONLY these Sleev-named paths):
     rm -f ~/.local/bin/sleev
     rm -rf ~/.config/sleev ~/.local/share/sleev ~/.local/state/sleev ~/.cache/sleev-gateway
   If installed via npm instead: npm uninstall -g sleev

5. Remove Sleev browser site data: any directory/file whose name contains "sleev"
   under the Chrome, Chromium, Brave and Firefox profile dirs, e.g.
     ~/.config/google-chrome/Default/IndexedDB/https_sleev.ai_0.indexeddb.leveldb
   Find them with:
     find ~/.config/google-chrome ~/.config/chromium ~/.config/BraveSoftware ~/.mozilla/firefox \
       -depth -iname '*sleev*' 2>/dev/null

6. Remove Sleev entries from AI harness configs (Claude Code, OpenCode, Codex, etc.) so
   requests go straight to the providers again. Locate them with:
     grep -rIl -e sleev -e 17321 ~/.claude ~/.claude.json ~/.config/opencode ~/.codex 2>/dev/null
   then delete only the Sleev-related entries (base URL / proxy pointing at 127.0.0.1:17321).

7. Verify removal:
     command -v sleev                      # must print nothing
     systemctl --user status sleeve-gateway.service   # must be not-found/inactive
     find ~ -maxdepth 5 -iname '*sleev*' 2>/dev/null  # must print nothing

SAFETY RULES:
- Scope: only files named sleev / sleeve-gateway. Do NOT delete anything else.
- No sudo and no system-wide changes — Sleev installs per user.
- Deletion is permanent; no backup is made. Ask the user first if anything is unclear.
- Sleev ships no official uninstaller — deleting these files IS the removal. This is expected.
````

---

## 2. ⚡ Quick start (60-second removal)

> [!WARNING]
> Cleanup **permanently deletes** Sleev's local session/message database, logs, credentials and
> browser data. **No backup is made.** If in doubt, run the dry-run first.

Close Chrome / Chromium / Brave / Firefox, open a terminal in this folder, and run:

```sh
./uninstall-sleev.sh --dry-run   # 1. preview what will be removed (changes nothing)
./uninstall-sleev.sh             # 2. do it (asks you to type: REMOVE SLEEV)
```

That's it. Details, manual alternatives and verification below.

---

## 3. 📜 Option A — Run the uninstall script

The script [`uninstall-sleev.sh`](./uninstall-sleev.sh) is plain bash you can read before running.
It is deliberately scoped and safe:

- ✅ **No `sudo`** — touches only your own home directory, refuses any path outside `$HOME`
- ✅ **No network** — never contacts Sleev or any remote service
- ✅ **Dry-run mode** — shows every target before deleting anything
- ✅ **Typed confirmation** — won't delete anything until you type `REMOVE SLEEV` (or pass `--yes`)
- ✅ **Self-verifies** — re-checks all known paths afterwards and reports leftovers

```sh
# Not cloned yet? Get it and run it:
curl -fsSL https://raw.githubusercontent.com/administrakt0r/sleev-ai-uninstall/main/uninstall-sleev.sh -o uninstall-sleev.sh
chmod +x uninstall-sleev.sh
./uninstall-sleev.sh --dry-run
./uninstall-sleev.sh
```

| Flag | Effect |
| --- | --- |
| `--dry-run` | List all cleanup targets and exit without changing anything |
| `--yes` | Skip the interactive confirmation (for unattended runs) |
| `--help` | Show usage |

**What it removes:** the `sleev` CLI, the `sleeve-gateway.service` systemd *user* unit and its
enablement link, `~/.config/sleev`, `~/.local/share/sleev`, `~/.local/state/sleev`,
`~/.cache/sleev-gateway`, and Sleev-named site data in common Chrome/Chromium/Brave/Firefox
profile directories (including Flatpak variants). Afterwards it verifies each known location.

**Not covered by the script:** npm-installed copies (`npm uninstall -g sleev`), harness config
edits (see [§ 4](#4--option-b--manual-step-by-step-no-script) step 6), and files Sleev may have
written to arbitrary/renamed locations — see [§ 10](#10--safety-notes--limitations).

---

## 4. 📋 Option B — Manual step-by-step (no script)

Everything below is copy-paste. Linux, per-user install. No `sudo` required at any point.

**1 — Deconfigure the official way (optional first step)**

```sh
~/.local/bin/sleev auth logout
```

This stops the gateway service and removes Sleev's routing entries from supported AI harnesses
(Claude Code, OpenCode, Codex, Pi, Grok Build, Hermes Agent). It is *not* an uninstall —
the binary, database, logs and browser data survive it (see [§ 5](#5--option-c--what-sleev-officially-tells-you-to-do-and-why-it-isnt-an-uninstall)).

**2 — Close your browsers**

Chrome, Chromium, Brave and Firefox must be closed so their site-data databases aren't in use.

**3 — Kill the background service**

```sh
systemctl --user disable --now sleeve-gateway.service 2>/dev/null
rm -f ~/.config/systemd/user/sleeve-gateway.service
rm -f ~/.config/systemd/user/default.target.wants/sleeve-gateway.service
systemctl --user daemon-reload 2>/dev/null
```

**4 — Remove the CLI**

```sh
rm -f ~/.local/bin/sleev
# If you installed it via npm instead:
npm uninstall -g sleev
```

**5 — Remove config, data, logs and cache**

```sh
rm -rf ~/.config/sleev ~/.local/share/sleev ~/.local/state/sleev ~/.cache/sleev-gateway
```

**6 — Clean the AI harness configs (so your tools work again without Sleev)**

Sleev edits your coding-agent config files to route requests through its gateway on
`127.0.0.1:17321`. Find and delete those Sleev-specific entries (base URL / proxy overrides):

```sh
grep -rIl -e sleev -e 17321 ~/.claude ~/.claude.json ~/.config/opencode ~/.codex 2>/dev/null
```

**7 — Remove Sleev browser site data**

```sh
find ~/.config/google-chrome ~/.config/chromium ~/.config/BraveSoftware \
     ~/.var/app/org.chromium.Chromium ~/.var/app/com.google.Chrome \
     ~/.var/app/com.brave.Browser ~/.mozilla/firefox \
     -depth -iname '*sleev*' -print 2>/dev/null
```

Review the output, then delete the listed paths (`rm -rf` each one). Example of what it finds:
`~/.config/google-chrome/Default/IndexedDB/https_sleev.ai_0.indexeddb.leveldb`.
Also check browser **extensions** manually and remove any Sleev-related one.

**8 — Verify** → [§ 6](#6--verify-sleev-is-gone)

---

## 5. 🔗 Option C — What Sleev officially tells you to do (and why it isn't an uninstall)

As of **5 October 2026**, the *entire* official removal surface of sleev.ai is:

| Officially documented | What it actually does | What it leaves behind |
| --- | --- | --- |
| FAQ *"How do I stop using Sleev?"* → "remove the Sleev-specific entries from your harness's config file… open the sleev TUI and sign out" ([sleev.ai/docs/faq](https://sleev.ai/docs/faq)) | Hand-edit your own tool configs, then sign out | Binary, service unit, database, logs, browser data |
| Docs › Deconfigure → `sleev auth logout` ([sleev.ai/docs/config/deconfigure](https://sleev.ai/docs/config/deconfigure)) | "Signing out removes local auth state and gateway config, deconfigures supported harnesses, and stops the local gateway service" | Binary, service unit file, session/message database, logs, cache, browser data |
| `sleev harness <harness> disable` ([sleev.ai/docs/cli-reference](https://sleev.ai/docs/cli-reference)) | Removes one harness's Sleev routing entry | Everything else |

> [!NOTE]
> To be fair: Sleev is not invisible — it documents a gateway, a service and a "deconfigure"
> step, and its sign-out does stop the gateway. But **signing out is not uninstalling**: the docs
> never tell you how to delete the program, its service, or the data it collected about your
> sessions. And their Terms/EULA say *"you must stop using and uninstall Sleev"* — an obligation
> to perform an action they never explain how to perform.

**Bottom line:** for a complete removal you must do what this guide describes — and no one should
need a detective's guide to delete software they installed.

---

## 6. ✅ Verify Sleev is gone

Run these after cleanup — each should come back empty / not-found:

```sh
command -v sleev                                   # nothing
systemctl --user status sleeve-gateway.service      # "Unit ... not-found"
systemctl --user is-enabled sleeve-gateway.service  # "not-found"
find ~ -maxdepth 5 -iname '*sleev*' 2>/dev/null     # nothing
```

If Sleev reappears after a reboot, check for things this guide can't see from here:

- Browser extensions (chrome://extensions, about:addments) — remove anything Sleev-related
- AI harness configs re-pointing to `127.0.0.1:17321` (step 6 of [§ 4](#4--option-b--manual-step-by-step-no-script))
- System-wide files outside your home directory (this guide and script are deliberately per-user;
  use your distribution's file search and inspect results before deleting)

---

## 7. 🕵 The shady part: install is one command, uninstall is a secret

**Installing Sleev** — from [sleev.ai](https://sleev.ai/) front and center:

```sh
curl -fsSL https://sleev.ai/install.sh | bash      # or PowerShell installer, or: npm install -g sleev
```

**Uninstalling Sleev** — as of **5 October 2026**, after checking
[the docs](https://sleev.ai/docs/quickstart), the [CLI reference](https://sleev.ai/docs/cli-reference),
the [FAQ](https://sleev.ai/docs/faq), the [Deconfigure page](https://sleev.ai/docs/config/deconfigure),
the [Terms](https://sleev.ai/terms) and the [EULA](https://sleev.ai/eula):

- ❌ No `sleev uninstall` / `sleev remove` command exists (the CLI reference lists every command — uninstall is not among them)
- ❌ No uninstall or removal page exists in the docs
- ❌ The install script has no `--uninstall` option
- ❌ The FAQ's answer to *"How do I stop using Sleev?"* is to **manually edit your tool's config files** and "open the sleev TUI and sign out" — advice that assumes you know what a TUI and a harness config are
- ❌ Their own Terms/EULA tell you that you **"must stop using and uninstall Sleev"** … and never say how

What that means in practice:

1. **Install takes one pasted command and zero knowledge. Removal takes research.** Asymmetry like
   that is not an accident — it's a design choice that favors retention over your control.
2. **"Sign out" quietly keeps your data.** The official sign-out stops the gateway but leaves the
   local SQLite database of your sessions, messages and usage tracking, tens of megabytes of
   HTTP/debug logs, cached credential helpers and browser site data on your disk.
3. **A background service that starts at every login and holds credentials for your AI providers
   should ship a one-word remover.** Package managers have `apt remove` / `npm uninstall` / `flatpak
   uninstall`; even browser toolbars have an "Uninstall" button. Sleev has none of these.
4. **This shouldn't be allowed to be normal.** Everyone deserves the right to remove software from
   their own system **easily and without technical knowledge** — especially when the developer
   refuses to provide uninstall instructions. If a vendor won't document removal, the community
   has to. That's this repository.

> [!TIP]
> Want to hold vendors to it? The standard is simple: **if you can install it with one command,
> you must be able to remove it with one command — and say so in your docs.**

---

## 8. 📦 What Sleev leaves on your system

Observed on a real Linux install (`curl | bash` layout). This is the full footprint the cleanup
targets:

| Path | What it is |
| --- | --- |
| `~/.local/bin/sleev` | The Sleev CLI binary |
| `~/.config/systemd/user/sleeve-gateway.service` | Systemd **user** service — starts with your login session |
| `~/.config/systemd/user/default.target.wants/sleeve-gateway.service` | The "start at login" enablement link |
| `~/.config/sleev/` | Config: mode, install ID, credentials, management token, control URL `https://api.sleev.ai` |
| `~/.local/share/sleev/` | App data incl. the SQLite database (sessions, messages, tracking, tool usage) |
| `~/.local/state/sleev/` | State + logs (e.g. `total-saved-tokens.json`, debug/HTTP logs, credential helper) |
| `~/.cache/sleev-gateway/` | Gateway cache |
| Browser profile dirs (`*sleev*`) | e.g. `https_sleev.ai_0.indexeddb.leveldb` IndexedDB data in Chrome/Chromium/Brave/Firefox |
| AI harness config files | Entries routing your coder's API traffic via `127.0.0.1:17321` |

**npm installs** add the CLI package (`npm uninstall -g sleev`) and create the same per-user
service/config/data paths above.

---

## 9. 🔍 Field notes from a real installation (September 2026)

Findings from inspecting one Linux laptop where Sleev had been installed. Kept factual:
these are observations, not accusations.

### Installation & persistence

- Sleev installed a systemd **user** unit `~/.config/systemd/user/sleeve-gateway.service`, enabled
  via `default.target.wants`. `WantedBy=default.target` means it starts with the user session.
- The unit had `Restart=on-failure` with a 2-second delay; journals showed starts on several days
  between 23–27 September 2026.
- The gateway was configured to bind `127.0.0.1:17321` — a loopback address, per this unit's config.
- The unit passed `--config`, `--db-path`, `--debug-log-dir`, `--request-log-dir`,
  `--auto-clear-logs`, `--redact-logs`, an uninstall-sentinel path and cleanup paths to its binary —
  i.e. built-in cleanup/logging mechanisms exist inside the installed invocation (not executed or
  reverse-engineered here).

### Remote configuration & local data retention

- `~/.config/sleev/gateway.json` contained `mode: guest`, an installation ID, credential and
  management-token fields, and the control URL `https://api.sleev.ai`. (Secrets not reproduced.)
- The gateway error log was ~14.4 MB / ~205,000 lines, referencing `api.sleev.ai`, `chatgpt.com`,
  `opencode.ai`, `openrouter.ai` and others. String counts are not packet captures — they show what
  was logged, not what was transmitted.
- `debug-logs/http` held **784 JSON files** (~**66.4 MB**) despite the unit passing both
  `--redact-logs` and `--auto-clear-logs`. Payload contents were not inspected or published.
- The SQLite database contained tables for sessions, messages, tracking, tool observations/usage and
  rollups: **119 sessions, 18,554 messages, 6,305 tracking rows** plus aggregates — retained local
  records of AI-assisted work.
- Also present: `total-saved-tokens.json`, a `claude-desktop-cred` helper binary, and Sleev-named
  Chrome IndexedDB site data. Binaries were ELF executables; a printable-string scan showed nothing
  conclusive (this is not a malware analysis).
- No matching Debian, Flatpak or Snap package; no desktop launcher.

### Assessment limits

The persistent user service, remote control URL with stored management credentials, substantial
HTTP/debug logs and local session/tracking data are legitimate **privacy and persistence concerns**.
They do **not** establish malicious intent or covert exfiltration. The binaries were not executed,
message/HTTP payloads were not read, no traffic was captured, and no full reverse-engineering audit
was performed. Decide for yourself — and remove it if you don't want it running (which should have
been easy in the first place).

---

## 10. ⚠ Safety notes & limitations

> [!WARNING]
> - **Destructive, no backup.** Cleanup permanently deletes Sleev's local session/message database,
>   token/credential files, logs, config and matching browser data. If you need any of it, copy it
>   elsewhere first.
> - **Rotate your credentials.** Deleting local copies does not revoke remote credentials. If you
>   pasted provider API keys into Sleev, revoke/rotate them with the provider (OpenRouter, Anthropic,
>   OpenAI, …).
> - **Close browsers first**, or their site-data databases may be in use and partially cleaned.
> - **Scope.** The script does not use `sudo`, touch system-wide files, or delete unrelated browser
>   profile data. It cannot prove that no renamed/copied Sleev files exist elsewhere.
> - **Harness configs.** The script does not edit your AI tool configs; do step 6 of
>   [§ 4](#4--option-b--manual-step-by-step-no-script) or the tools may keep trying to reach the
>   removed gateway.

---

## 11. ❓ FAQ

<details>
<summary><b>Does Sleev have an official uninstall command?</b></summary>

No. As of 5 October 2026 there is no <code>sleev uninstall</code>, no uninstall docs page, and no
uninstall option in the installer. The closest official actions are <code>sleev auth logout</code>
(sign out + stop gateway + deconfigure harnesses) and <code>sleev harness &lt;harness&gt; disable</code>.
Neither deletes the binary, service unit, database or logs.
</details>

<details>
<summary><b>Is signing out (<code>sleev auth logout</code>) enough?</b></summary>

It stops the gateway and deconfigures harnesses — good first step — but leaves the program, the
systemd unit file, the local session/message database, logs, cache and browser data on disk.
Follow this guide for a full removal.
</details>

<details>
<summary><b>I installed with <code>npm install -g sleev</code> — is it different?</b></summary>

Only the CLI location changes. Run <code>npm uninstall -g sleev</code> instead of deleting
<code>~/.local/bin/sleev</code>, then do the rest of
<a href="#4--option-b--manual-step-by-step-no-script">§ 4</a> (service, config, data, browser, harness).
</details>

<details>
<summary><b>Is Sleev malware?</b></summary>

This guide does not claim that. It documents verified facts: a login-started background service, a
remote control endpoint with stored credentials, and large amounts of retained local session data —
and the absence of any documented uninstall. Whether to run it is your call; removing it is your
right either way. See <a href="#9--field-notes-from-a-real-installation-september-2026">§ 9</a> for
the evidence and its limits.
</details>

<details>
<summary><b>Will it come back after I remove it?</b></summary>

Not on its own — Sleev has no system package or launcher that would reinstall it. If it reappears,
check browser extensions, harness configs, and whether another tool reinstalled it.
</details>

<details>
<summary><b>Can I use this to uninstall other software?</b></summary>

No. Every path is hard-coded to Sleev's footprint and the script refuses to touch anything outside
your home directory or not named Sleev. Don't adapt it blindly — find a dedicated guide instead.
</details>

---

<div align="center">

**Software you can't remove is software you don't control.**

*Not affiliated with Sleev. Verified against sleev.ai on 5 October 2026 — if Sleev ships a real
uninstaller later, open an issue/PR and this guide will link to it.*

</div>
