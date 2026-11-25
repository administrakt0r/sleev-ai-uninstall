# Remove Sleev (sleev.ai) from your system

**Community cleanup tools and a manual guide for the Sleev AI gateway on Windows and Linux.**

In the installations documented by this repository, logging out or disabling a harness did not remove all local application files, logs, databases and background components. Check Sleev's current [documentation](https://sleev.ai/docs) and [deconfiguration guide](https://sleev.ai/docs/config/deconfigure) first: the supported removal options can change between versions.

This project is independent and is not affiliated with Sleev.ai.

## Contents

- [Quick start](#quick-start)
- [What is removed](#what-is-removed)
- [Using an AI coding agent](#using-an-ai-coding-agent)
- [Manual investigation and cleanup](#manual-investigation-and-cleanup)
- [Restore AI harness configurations](#restore-ai-harness-configurations)
- [Verify the result](#verify-the-result)
- [Filesystem footprint](#filesystem-footprint)
- [Field notes](#field-notes)
- [Safety and limitations](#safety-and-limitations)
- [Contributor checks](#contributor-checks)

## Quick start

> [!WARNING]
> Cleanup permanently deletes known local Sleev databases, logs, binaries, settings and credentials. No backup is made. Export anything you need before proceeding. Local deletion does not revoke remote credentials, delete your account or cancel a subscription.

Download or clone this repository and inspect the appropriate script before running it. Do not pipe an unreviewed remote script directly into a shell.

### Windows (PowerShell 5.1)

Close Sleev and any separately launched gateway. Open PowerShell under the affected Windows account and navigate to this repository:

```powershell
.\uninstall-sleev.ps1 -DryRun
.\uninstall-sleev.ps1
```

If scheduled-task permissions prevent cleanup, retry in an elevated PowerShell window **under the same Windows account**. Do not switch to a different administrator's profile.

### Linux (Bash)

Close Sleev and any separately launched gateway. Run as the affected user, not with `sudo`. Bash and GNU coreutils are required; systemd and npm are checked when available.

```bash
bash ./uninstall-sleev.sh --dry-run
bash ./uninstall-sleev.sh
```

On either platform, type `REMOVE SLEEV` when prompted. `-Yes` (Windows) or `--yes` (Linux) bypasses confirmation only, not the safety checks. Review the preview before authorizing deletion.

## What is removed

| Component | Windows | Linux |
| --- | --- | --- |
| Known application paths | Yes, with reparse-point checks | Yes, with symlink-ancestor checks |
| Background startup | Verified root `SleeveGateway` task | Known per-user `sleeve-gateway.service` |
| Running gateway | Known executable paths only | Verified systemd user service |
| Global npm package | Exact `sleev` package, if detected | Exact `sleev` package, if detected |
| Browser profiles and generic temporary folders | Manual review only | Manual review only |
| AI harness configuration | Read-only reference check | Manual review |
| Remote account, credentials and billing | Not changed | Not changed |

The scripts report incomplete cleanup rather than silently treating a failed operation as success. Exit code `0` means the checked application targets were cleared (or a dry run completed); a nonzero exit code means cleanup was incomplete, cancelled or encountered an error.

On Windows the script also measures the change in available disk space on the relevant volumes. This is not a sum of file sizes: hardlinks and concurrent activity can affect the result.

## Using an AI coding agent

Paste the following into your coding agent if you prefer assistance:

```text
TASK: Remove the known Sleev application components without touching unrelated software, browser profiles, model-provider settings or user data.

1. Identify the OS and affected user. Read this README and inspect the corresponding uninstall script.
2. Run the read-only preview (-DryRun on Windows, --dry-run on Linux).
3. Report the targets and any uncertain paths. Obtain approval before permanent deletion of local sessions, logs, settings and credentials.
4. Close Sleev and use the reviewed script. Do not bypass permissions, kill unrelated processes, follow filesystem links or recursively delete browser data by name.
5. Check the exit code and remaining items. Identify owners of locked files or occupied ports before retrying.
6. Review harness settings for confirmed Sleev proxy overrides. Preserve unrelated providers and restore only known original values. Never publish tokens, request payloads or private paths.
7. If requested, clear only the sleev.ai site's data via the browser settings.
```

## Manual investigation and cleanup

Use these steps when the script reports an unexpected layout or incomplete removal. A name match alone is not evidence that a process, file or service belongs to Sleev.

### Windows

Inspect the documented task and possible gateway executables:

```powershell
Get-ScheduledTask -TaskName 'SleeveGateway' -TaskPath '\' |
    Select-Object TaskName, State, Actions

Get-CimInstance Win32_Process |
    Where-Object { $_.Name -in @('sleev.exe', 'sleeve-gateway.exe', 'sleev-gateway.exe') } |
    Select-Object ProcessId, Name, ExecutablePath
```

If the task action points to a verified Sleev executable in the affected user's documented application paths, disable and stop it **before** unregistering it:

```powershell
Disable-ScheduledTask -TaskName 'SleeveGateway' -TaskPath '\'
Stop-ScheduledTask -TaskName 'SleeveGateway' -TaskPath '\'
Unregister-ScheduledTask -TaskName 'SleeveGateway' -TaskPath '\' -Confirm:$false
```

Stop only a specific process whose executable identity and ownership you have verified. Do not terminate all Python or Node.js processes. If a file remains locked, open Resource Monitor (`resmon.exe`), select CPU → Associated Handles, and search for the filename. Identify its owner before retrying.

Inspect `npm list -g --depth=0`. If the exact `sleev` package is present, remove it:

```powershell
npm uninstall -g sleev --ignore-scripts --offline --no-audit --no-fund
```

Review the six application paths in the filesystem footprint below. Prefer the script's per-item removal, which continues after a locked file and skips reparse points, rather than indiscriminate recursive deletion.

### Linux

Inspect the user service and its actual origin:

```bash
systemctl --user show -p LoadState -p FragmentPath -p ExecStart -p ActiveState sleeve-gateway.service
```

If the unit is confirmed to belong to Sleev, disable and stop it:

```bash
systemctl --user disable --now sleeve-gateway.service
systemctl --user show -p ActiveState --value sleeve-gateway.service
```

Verify the service has stopped before deleting its known unit file and enablement link. Reload the user manager with `systemctl --user daemon-reload`. An unexpected unit location or an inaccessible service manager requires manual review.

Inspect `npm list -g --depth=0` and remove the exact package if installed:

```bash
npm uninstall -g sleev --ignore-scripts --offline --no-audit --no-fund
```

Inspect the known paths below before removing them. Check ancestors for symlinks and ensure the locations are not mounted data directories. Do not use `sudo rm -rf` to bypass a failed check.

### Browser and temporary data (both platforms)

Neither script scans or deletes browser profiles or generic temporary directories. If you want to remove browser data, use your browser's site-data settings and select the exact `sleev.ai` site. This also avoids editing shared cookie and storage databases directly.

Directories named `_MEI*` may be temporary distributions of unrelated PyInstaller programs. Do not recursively delete them using a name wildcard; remove only a directory whose specific ownership has been established.

## Restore AI harness configurations

Removing the gateway may leave a harness pointing to the now-unavailable local proxy at `127.0.0.1:17321`. Consider using the vendor's supported logout or harness-disable commands before removal where appropriate.

Review the actual configurations afterward:

| Harness | Locations to inspect |
| --- | --- |
| Codex | `~/.codex/config.toml`, including `[model_providers.sleev]` and related headers |
| OpenCode | `~/.config/opencode/opencode.json` and `opencode.jsonc`, including provider base URLs and headers |
| Claude Code | `~/.claude.json` and relevant files under `~/.claude` |

Back up a configuration before editing it. Restore only confirmed Sleev overrides from known-good settings. A reference to port `17321` is not proof of Sleev ownership. Do not delete an entire provider block if it also contains independent settings. Do not guess upstream URLs or expose API keys.

The Windows script warns about potential references without changing these files. Linux users should inspect them manually.

## Verify the result

Check the script's exit code and warnings. The following are additional diagnostic commands, not a guarantee that every custom installation has been found.

### Windows

```powershell
Get-Command sleev -ErrorAction SilentlyContinue
Get-ScheduledTask -TaskName 'SleeveGateway' -TaskPath '\' -ErrorAction SilentlyContinue
Get-NetTCPConnection -State Listen -LocalPort 17321 -ErrorAction SilentlyContinue
@(
    "$env:USERPROFILE\.local\bin\sleev.exe"
    "$env:USERPROFILE\.local\state\sleev"
    "$env:LOCALAPPDATA\sleev"
    "$env:LOCALAPPDATA\sleev-gateway"
    "$env:APPDATA\sleev"
    "$env:APPDATA\ai.opencode.desktop\sleev"
) | ForEach-Object { if (Test-Path -LiteralPath $_) { $_ } }
npm list -g --depth=0
```

### Linux

```bash
command -v sleev
systemctl --user show -p LoadState -p ActiveState -p FragmentPath sleeve-gateway.service
npm list -g --depth=0
ss -ltn 'sport = :17321'
bash ./uninstall-sleev.sh --dry-run
```

Check that the known unit/task, application paths and package are absent. A listener on port 17321 may be unrelated; inspect its owner rather than stopping it automatically. A query or permission error means verification is incomplete, not that the target is absent.

## Filesystem footprint

These paths were observed in the installations documented by the original authors. Other versions and customized installations may differ.

### Windows

| Path | Observed purpose |
| --- | --- |
| Task Scheduler: `\SleeveGateway` | Background gateway startup |
| `%LOCALAPPDATA%\sleev\` | Local session database, gateway, logs, cache and task definition |
| `%LOCALAPPDATA%\sleev-gateway\` | Multi-version gateway binaries |
| `%APPDATA%\sleev\` | Gateway configuration and authentication data |
| `%APPDATA%\ai.opencode.desktop\sleev\` | Harness-related data and logs |
| `%USERPROFILE%\.local\bin\sleev.exe` | CLI executable |
| `%USERPROFILE%\.local\state\sleev\` | Runtime state |
| Global npm `sleev` | Package and CLI wrappers |
| Browser site data for `sleev.ai` | Optional manual cleanup |
| AI harness config files | Optional manual restoration |

### Linux

| Path | Observed purpose |
| --- | --- |
| `~/.config/systemd/user/sleeve-gateway.service` | User service |
| `~/.config/systemd/user/default.target.wants/sleeve-gateway.service` | Service enablement link |
| `~/.local/bin/sleev` | CLI |
| `~/.config/sleev` | Configuration and credentials |
| `~/.local/share/sleev` | Session and message database |
| `~/.local/state/sleev` | Runtime state and logs |
| `~/.cache/sleev-gateway` | Gateway cache |
| Global npm `sleev` | Package and CLI wrappers |
| Browser site data and AI harness settings | Optional manual cleanup/restoration |

## Field notes

The original authors documented the following installations; these are historical observations, not claims about every version or current vendor policy.

- Windows (November 2026): a scheduled task launched `sleeve-gateway.exe` at login; some task operations required elevation. Gateway versions accumulated in separate directories, and local request logs and SQLite databases survived logout. Several harness provider settings pointed to port 17321.
- Linux (September 2026): a systemd user unit restarted the gateway on failure; the authors observed 119 sessions, 18,554 message records, 6,305 tracking rows and 784 HTTP debug log files totaling about 66.4 MB.
- Additional Windows PowerShell 5.1 field report: an earlier removal attempt encountered locked gateway files. A path-scoped cleanup with task disable/stop/unregister and per-file deletion subsequently removed 68,598 files with no reported deletion failures, recovering 28.67 GiB of available space. A potential OpenCode proxy reference still required manual review. This report concerns the predecessor of the revised Windows script, not a full test of every change in this PR.

Local request logs and databases may contain private prompts, responses, source code or credentials. Avoid sharing raw logs. Rotate exposed API keys and revoke remote credentials separately.

The lack of a working uninstall route in the observed installations is a usability and data-retention concern; it does not establish the vendor's intent or prove a legal or compliance violation. Consult current vendor documentation and organizational policies where relevant.

The original repository also points to [CMX (Compressius Maximus)](https://compressi.us) and its [documentation](https://docs.compressi.us) as an alternative to investigate. Evaluate any alternative independently.

## Safety and limitations

- No backup is made. Ordinary file deletion is not guaranteed secure erasure.
- Dry runs do not stop services, uninstall packages or delete files.
- Windows skips reparse points and checks ancestors. Linux rejects symlinked ancestors, unlinks target symlinks and uses GNU `rm --one-file-system`. Neither script is hardened against concurrent malicious path replacement or every mount/bind-mount layout. Inspect unusual or mounted directories manually.
- Only documented task/unit locations and known Windows executable paths are handled automatically. Unknown wrappers, custom installs and unavailable service managers require manual review. Close separately launched Linux gateways before cleanup.
- Windows may need elevation under the same account. Linux is a per-user operation; do not use sudo to bypass safety checks.
- npm removal uses the exact package name, disables lifecycle scripts and requests offline operation. Custom installation scopes or other package managers may need manual review.
- Browser profiles, generic temporary directories and harness configuration are intentionally not deleted.
- Local cleanup does not revoke remote credentials, terminate an account or cancel billing. Check the relevant provider controls separately.
- A successful result covers checked targets only, not every possible installation or remote state.

## Contributor checks

These focused tests use disposable directories and do not invoke the real uninstall operation against your user installation.

```powershell
powershell.exe -NoProfile -File .\tests\windows-safety.ps1
```

```bash
bash -n uninstall-sleev.sh
bash tests/linux-safety.sh
```

The Windows fixture checks exact executable-path matching, junction handling, a locked file, sibling cleanup and retry. The Linux fixture checks dry-run behavior, preservation of unrelated browser data and refusal of symlinked ancestors. They are not substitutes for native integration tests of Task Scheduler, systemd, npm or custom installations.

Please report reproducible problems with the OS, script version, redacted error message and exit code. Do not post private file contents or authentication material.
