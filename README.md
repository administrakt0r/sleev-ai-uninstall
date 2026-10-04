# Sleev removal and local findings

This folder contains a scoped Linux cleanup script and notes from an inspection of this laptop. The script is designed for the observed per-user installation; it does not use `sudo`, alter system-wide files, or contact Sleev or any remote service.

## Findings on this laptop

### Observed installation and persistence

- Sleev installed a systemd **user** unit at `~/.config/systemd/user/sleeve-gateway.service` and enabled it via `default.target.wants`. The unit description says “Sleev local gateway”; its `WantedBy=default.target` setting means it is configured to start with the user session.
- The unit has `Restart=on-failure` with a 2-second delay. The service journal shows it started on several dates between September 23 and September 27, 2026. At inspection time it was inactive, and no Sleev gateway process was running.
- The gateway command is configured to bind to `127.0.0.1:17321`. That is a loopback address, not a public listening interface in this unit configuration. This does not establish what other software or remote control paths may do.
- The unit passes `--config`, `--db-path`, `--debug-log-dir`, `--request-log-dir`, `--auto-clear-logs`, `--redact-logs`, an uninstall-sentinel path, and cleanup paths to its binary. Those options indicate built-in cleanup/logging mechanisms are present in the installed gateway invocation; I did not execute or reverse engineer them. Therefore, I cannot verify the claim that Sleev has no uninstall mechanism.
- The `~/.local/bin/sleev` executable exists, so there is also a Sleev-named CLI binary. I did not run it because its behavior was not independently verified.

### Remote configuration and local data retention

- `~/.config/sleev/gateway.json` contains a `mode` of `guest`, an installation ID, credential and management-token fields, and the HTTPS control URL `https://api.sleev.ai`. Secret values are intentionally not copied into this report. This shows the installation is configured with remote-service credentials and a Sleev control endpoint; it does not by itself prove what data was transmitted.
- The gateway error log was approximately 14.4 MB with about 205,000 lines. It contains references to `api.sleev.ai`, `chatgpt.com`, `opencode.ai`, and `openrouter.ai`, among other hostnames. The log also contains connection, request, and credential-related terms. String counts are not packet captures and do not establish the exact contents or direction of any transfer.
- The `debug-logs/http` tree contained **784 JSON files** totaling approximately **66.4 MB**. The service command has both `--redact-logs` and `--auto-clear-logs` options, but substantial HTTP-named log data was present at inspection. I did not inspect or publish request/response payloads, so I cannot determine whether sensitive values were redacted inside every file.
- The Sleev SQLite database contained tables for sessions, messages, tracking, tool observations/usage, and rollups. Schema-only counts were 119 session rows, 18,554 message rows, 6,305 tracking rows, and additional aggregated records. These counts describe retained local records, not what was sent remotely.
- Sleev state also included `total-saved-tokens.json` and a `claude-desktop-cred` helper binary. The config, database, state, and logs may contain sensitive material; values were not reproduced here.
- Sleev-named Chrome IndexedDB site data existed at `~/.config/google-chrome/Default/IndexedDB/https_sleev.ai_0.indexeddb.leveldb`.
- The Sleev binaries were ELF executables. A basic printable-string scan did not return useful behavior indicators; this is not a malware analysis and cannot establish that the binaries are safe or malicious.
- No matching Debian, Flatpak, or Snap package was found in the checks performed. No Sleev-named desktop launcher was found.

### Assessment limits

The repeated user-session service, remote control URL plus stored management credential, substantial HTTP/debug logs, and local session/tracking/token-related data are reasonable privacy and persistence concerns. The observed facts do **not** establish malicious intent, covert exfiltration, or the exact nature of remote processing. I did not execute the Sleev binaries, read database message contents or HTTP payloads, capture network traffic, or perform a full reverse-engineering/security audit. No process/network activity was present to inspect live at the time of review.

## Run the cleanup

Close Chrome/Chromium/Brave/Firefox before cleaning up so open browser databases are not in use. Then open a terminal in this folder and run:

```sh
./uninstall-sleev.sh --dry-run
./uninstall-sleev.sh
```

The second command asks for the exact confirmation `REMOVE SLEEV`. For an unattended run, use `./uninstall-sleev.sh --yes`.

The script disables/stops the Sleev user service, removes its user-level service and enablement link, CLI, config, app/database files, state/logs, cache, and Sleev-named data under common Chrome, Chromium, Brave, and Firefox profile directories. It verifies those known locations afterward. It does not delete unrelated browser profile data, inspect/delete system-wide files, revoke remote credentials, or prove that no arbitrarily renamed/copied files exist elsewhere on the computer.

**Data warning:** Cleanup permanently removes Sleev's local session/message database, token-related files, logs, configuration, and matching browser data. The script does not create a backup. If Sleev credentials may have been exposed, revoke or rotate them through the relevant provider/account separately; deleting local copies does not revoke remote credentials.

## Post-cleanup checks

The script checks its known paths and systemd enablement. To look for additional, renamed, or system-wide files beyond that scope, use your distribution's file search and inspect results before deleting them. Also review browser extensions and system service lists manually if Sleev reappears after reboot; this inspection found no Sleev-named system-wide unit or launcher.
