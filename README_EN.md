<div align="center">

# Codex-Relay

**A route switcher and operations toolkit for OpenAI Codex CLI on Linux / SSH**

Keep the official `codex` binary. Switch providers, credentials, models, network routes, and local history safely.

[![Shell syntax check](https://github.com/heu-gj/Codex-Relay/actions/workflows/shell-syntax.yml/badge.svg)](https://github.com/heu-gj/Codex-Relay/actions/workflows/shell-syntax.yml)
![Linux](https://img.shields.io/badge/platform-Linux-1793D1?logo=linux&logoColor=white)
![Bash](https://img.shields.io/badge/shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![Codex CLI](https://img.shields.io/badge/Codex_CLI-native-111827)

[简体中文](./README.md) · [English](./README_EN.md)

</div>

---

Codex-Relay is a Bash utility designed for **Linux, SSH, and shared multi-user servers**. It manages provider routing, API keys, model selection, direct-network diagnostics, and local Codex history.

It is **not a proxy server and does not replace the official OpenAI Codex CLI**. It prepares the current Linux user's native `~/.codex/config.toml`, `~/.codex/auth.json`, and launch environment before executing the regular `codex` command.

> [!NOTE]
> The built-in Nova and baibai entries are convenience profiles only. Their availability, pricing, models, and terms are controlled by the corresponding third-party providers. Codex-Relay is not affiliated with OpenAI or those providers.

## Why Codex-Relay

Codex-Relay is useful when you need to:

- switch between **official OpenAI, Nova, baibai, and custom compatible providers**;
- keep the official `codex` executable untouched;
- share one server while keeping each Linux user's **keys, auth, and chats isolated**;
- prevent stale `HTTP_PROXY`, `HTTPS_PROXY`, or `ALL_PROXY` variables from hijacking Codex traffic;
- discover a relay's available models before selecting one;
- diagnose DNS / HTTPS connectivity and safely repair direct routing when needed;
- keep and restore local Codex history even after switching providers.

## Features

| Feature | What it does |
| --- | --- |
| 🚦 Route Switcher | Card-style provider selection |
| 🔐 Per-user credentials | Keys live under each user's `~/.codex-relay/secrets/` |
| 🧠 Model discovery | Tries `/models` and `/v1/models` before manual entry |
| ⚡ Native Codex | Keeps the official `codex` executable unchanged |
| 🌐 No-proxy launch | Clears HTTP/HTTPS/ALL proxy variables before launch |
| 🩺 Network diagnostics | System DNS, TCP DNS, HTTPS, latency |
| 🧭 Direct repair | Verifies candidate IPs before touching `/etc/hosts` |
| 💬 History tools | List, search, resume, repair, and rebuild local history |
| 👥 Multi-user isolation | One shared binary, separate user data |
| 🌏 Bilingual UI | Chinese by default, English available |
| 🎨 NO_COLOR | Works cleanly in non-color terminals |

## 30-second Quick Start

### Administrator: install the shared binary

The recommended method uses regular GitHub access instead of `raw.githubusercontent.com`, which may be blocked on some networks:

```bash
rm -rf /tmp/Codex-Relay

git clone --depth=1 \
  https://github.com/heu-gj/Codex-Relay.git \
  /tmp/Codex-Relay

bash -n /tmp/Codex-Relay/codex-relay

sudo install -o root -g root -m 755 \
  /tmp/Codex-Relay/codex-relay \
  /usr/local/bin/codex-relay
```

Verify:

```bash
/usr/local/bin/codex-relay help
```

### User: add shortcuts

Once `/usr/local/bin/codex-relay` exists, regular users do **not** need to clone the repository:

```bash
cat >> ~/.bashrc <<'EOF'

alias cr='/usr/local/bin/codex-relay'
alias cx='/usr/local/bin/codex-relay run'
EOF

source ~/.bashrc
```

Store your own API keys:

```bash
cr key set nova
cr key set baibai
```

Then open the switcher:

```bash
cr
```

or switch and launch directly:

```bash
cr switch nova
cr switch baibai
```

## UI Preview

### Route Switcher

```text
CODEX RELAY // ROUTE SWITCHER

◆ ACTIVE ROUTE
  ● BAIBAI
    gpt-5.6-sol · xhigh  →  api.sharesai.xyz  →  NET ✓ Direct · 168 ms

◆ PROVIDERS

  [1]  BAIBAI   ● ACTIVE   BUILT-IN
       ├─ model    gpt-5.6-sol · xhigh
       └─ route    api.sharesai.xyz   ✓ KEY   NET ✓ Direct · 168 ms

  [2]  NOVA     ○ STANDBY  BUILT-IN
       ├─ model    gpt-5.5
       └─ route    ai.novacode.top    ✓ KEY   NET not checked

────────────────────────────────────────────────
  [Enter] Launch current Codex
  [A]     Add provider
  [R]     Refresh active route network
  [M]     Open control center
  [0]     Exit
```

The provider list reads cached network state only. It does not perform network requests on every redraw.

### Control Center

```bash
cr menu
```

The dashboard exposes providers, history, network/services, and settings from one place.

## Installation and Upgrades

### Recommended installation

```bash
rm -rf /tmp/Codex-Relay

git clone --depth=1 \
  https://github.com/heu-gj/Codex-Relay.git \
  /tmp/Codex-Relay

bash -n /tmp/Codex-Relay/codex-relay
bash -n /tmp/Codex-Relay/install.sh

sudo install -o root -g root -m 755 \
  /tmp/Codex-Relay/codex-relay \
  /usr/local/bin/codex-relay

hash -r
```

Run the same sequence again to upgrade.

### Optional raw installer

If your server can access `raw.githubusercontent.com`:

```bash
curl -fsSL https://raw.githubusercontent.com/heu-gj/Codex-Relay/main/install.sh \
  | sudo bash -s -- --global
```

If raw GitHub is blocked, use the Git clone method above.

### Migrating from an old per-user installation

If `~/bin/codex-relay` exists:

```bash
mv ~/bin/codex-relay \
  ~/bin/codex-relay.user-backup.$(date +%Y%m%d-%H%M%S) \
  2>/dev/null || true

hash -r
```

Point your aliases to `/usr/local/bin/codex-relay`.

## Providers and Models

### Switch providers

Switch config/auth without launching:

```bash
cr use nova
cr use baibai
```

Switch and launch:

```bash
cr switch nova
cr switch baibai
```

Launch the current profile:

```bash
cx
```

### Discover available models

Open a relay provider and choose:

```text
[2] Choose / edit default model
```

Codex-Relay uses the current user's saved key and tries:

```text
<Base URL>/models
<Base URL>/v1/models
```

If a model list is returned, select one by number. After choosing a relay model, Codex-Relay opens a **Reasoning Effort** picker and saves the model + reasoning choice atomically:

```text
REASONING // BAIBAI

◆ PENDING MODEL
  model               gpt-5.6-sol
  current reasoning   xhigh

◆ REASONING EFFORT
  [Enter] Auto          recommended · leave model_reasoning_effort unset
  [K]     Keep current  xhigh
  [N]     None
  [1]     Minimal
  [2]     Low
  [3]     Medium
  [4]     High
  [5]     XHigh
  [M]     Manual value
  [0]     Cancel without changing model
```

Reasoning-effort support varies by model. **Auto** is the safe default for unknown or custom models: it removes the previous `model_reasoning_effort` instead of writing an `"auto"` string, allowing Codex/the model to use its own default behavior.

If you cancel from the reasoning picker, neither the model nor reasoning setting is changed.

If the provider does not expose a model-list endpoint, manual entry remains available. The CLI can also set both values:

```bash
cr model PROFILE MODEL               # Auto: clear old reasoning
cr model PROFILE MODEL high          # explicitly use high
cr model PROFILE MODEL xhigh         # explicitly use xhigh
cr model PROFILE MODEL keep          # preserve current reasoning
```

The built-in baibai profile still starts with `gpt-5.6-sol + xhigh`; the new Auto behavior applies when the user actively changes the model.

### Add a custom provider

Press `A` in the Route Switcher. The wizard walks through:

1. local profile name;
2. API Base URL;
3. default model;
4. Provider ID.

The configuration is previewed before it is written.

> [!IMPORTANT]
> Custom providers use Codex with `wire_api = "responses"`. The provider must support the **OpenAI Responses API**. A service that only implements `/chat/completions` is not compatible with this custom-provider path.

Codex-Relay does **not** automatically append `/v1`. Follow the provider's documentation.

## API Keys and Native Auth

Relay-managed keys are stored per user:

```text
~/.codex-relay/secrets/<profile>.key
```

Typical permissions:

```text
~/.codex-relay/          700
*.key                    600
```

Commands:

```bash
cr key
cr key set PROFILE
cr key remove PROFILE
```

When a relay provider is active, Codex-Relay writes the current user's native Codex `auth.json` in API-key mode. The key is **not** written into `config.toml`.

If an official ChatGPT/Codex login is detected, a private snapshot is preserved under:

```text
~/.codex-relay/auth/official.json
```

Switching back to `official` restores the native login.

> [!WARNING]
> Changing or removing the key for the **currently active** relay stops Codex processes owned by the current Linux user so the new auth is guaranteed to take effect. This can interrupt running or queued work. Updating an inactive provider does not stop the current session.

## Network and Direct Mode

Before launching Codex, Codex-Relay clears:

```text
http_proxy
https_proxy
HTTP_PROXY
HTTPS_PROXY
all_proxy
ALL_PROXY
```

### Diagnostics

```bash
cr check nova
cr check baibai
```

The diagnostic panel checks DNS, TCP DNS, HTTPS, and proxy state.

Any valid HTTP response proves that DNS/TCP/TLS/HTTP reached the server. For example, `401` or `403` may indicate an authentication problem, not a network failure.

### Direct repair

```bash
cr direct PROFILE
```

Flow:

```text
normal direct connection
        │
        ├─ works → no system changes
        │
        └─ fails
             ↓
TCP DNS lookup
             ↓
candidate IPv4 addresses
             ↓
curl --resolve TLS / HTTPS verification
             ↓
verified address only → /etc/hosts
```

`/etc/hosts` is backed up before modification.

> [!CAUTION]
> `/etc/hosts` is system-wide and requires sudo access. Codex-Relay intentionally does not pin official OpenAI/CDN addresses.

## Chat History and Recovery

Codex history belongs to the current Linux user's Codex data directory, not to a relay provider:

```text
~/.codex/sessions/
~/.codex/archived_sessions/
~/.codex/state_5.sqlite
~/.codex/session_index.jsonl
```

Switching from baibai to Nova does not move or delete old chats.

### Browse and search

```bash
cr history 100
cr search KEYWORD
```

### Resume one chat

```bash
cr recover-menu
```

The Session Picker shows timestamp, original provider, model, and title. A resumed chat can continue on its original provider or another selected route.

### Cross-provider history recovery

Codex currently has an upstream behavior where switching `model_provider` can make the normal history view show only threads for the active provider. The old threads usually still exist under `~/.codex/`.

Use the Relay picker for cross-provider recovery:

```bash
cr recover-menu
```

or:

```text
cr menu
→ Chat / History
→ Cross-provider recovery
```

This view reads the current user's SQLite history directly without filtering to the active provider. When a thread is selected, Relay switches to the appropriate provider/auth before resuming it.

`Codex native all sessions` uses `codex resume --all --include-non-interactive`. It is useful for native browsing, but cross-provider resume is still subject to Codex's own provider-definition and authentication rules.

### Restore all chat history

To restore every recoverable chat for the current Linux user and immediately open the all-session picker, run:

```bash
cr restore-all
```

or use:

```text
cr menu
→ Chat / History
→ Restore all chat history
```

After confirmation, Codex-Relay runs the full workflow:

```text
confirm no important work is running/queued
        ↓
stop current-user Codex
        ↓
back up SQLite / index / rollout
        ↓
scan sessions / archived_sessions
        ↓
restore missing SQLite threads / safe metadata
        ↓
read P_PROVIDER from the active profile
        ↓
migrate every historical thread's model_provider
to the active provider
        ↓
rewrite matching rollout session_meta.model_provider
        ↓
rebuild / verify session_index and SQLite
        ↓
open all chats
```

The migration is provider-agnostic. The target is always the active profile's `P_PROVIDER`; source providers are discovered directly from SQLite and rollout history. This means chats from an old custom relay can still be migrated even if that relay has already been removed from `relays.tsv`, as long as its rollout still exists.

For example, when Nova is active, histories tagged with baibai, a legacy Nova provider ID, a custom provider, or another provider are migrated to Nova's current provider after a full backup. If baibai, official OpenAI, or any custom profile is active instead, the same command automatically targets that provider.

Only provider metadata is rewritten; message bodies, titles, and tool records are left untouched. Compatibility of provider-specific session state still depends on the destination backend.

If the database is already healthy and you only want to open the chats Codex can currently list **without rewriting provider metadata**, use:

```bash
cr all-history
```

This opens all chats without modifying the database.

Conservative repair mode remains available:

```bash
cr stop
cr repair-history
```

## Multi-user Design

Recommended layout:

```text
/usr/local/bin/codex-relay        # one shared program

/home/userA/.codex/               # userA Codex data
/home/userA/.codex-relay/         # userA relay state / keys / backups

/home/userB/.codex/
/home/userB/.codex-relay/
```

Key guarantees:

- the executable may be shared globally;
- `~/.codex/` stays per-user;
- `~/.codex-relay/` stays per-user;
- API keys are not shared between Linux users;
- `auth.json` is not shared;
- history databases are not shared;
- model/endpoint overrides do not affect other users;
- `cr stop` targets only the current user's Codex processes.

## Data Layout

```text
~/.codex/
├── config.toml
├── auth.json
├── sessions/
├── archived_sessions/
├── state_5.sqlite
└── session_index.jsonl

~/.codex-relay/
├── current
├── relays.tsv
├── official-model
├── language
├── secrets/
├── auth/
├── cache/
├── overrides/
└── backups/
```

## Built-in Profiles

<details>
<summary><strong>baibai</strong></summary>

```toml
model_provider = "baibai"
model = "gpt-5.6-sol"
model_reasoning_effort = "xhigh"
network_access = "enabled"
disable_response_storage = true

[model_providers.baibai]
name = "OpenAI"
base_url = "https://api.sharesai.xyz/v1"
wire_api = "responses"
requires_openai_auth = true
```

</details>

<details>
<summary><strong>Nova</strong></summary>

```toml
model_provider = "OpenAI"
model = "gpt-5.5"
review_model = "gpt-5.5"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true

[model_providers.OpenAI]
name = "OpenAI"
base_url = "https://ai.novacode.top"
wire_api = "responses"
requires_openai_auth = true

[features]
goals = true
```

Nova intentionally keeps its Base URL without automatically appending `/v1`. Codex-Relay also avoids writing an invalid `model_catalog_json` path.

</details>

## Command Reference

| Command | Purpose |
| --- | --- |
| `cr` | Open Route Switcher |
| `cr menu` | Open Control Center |
| `cr list` | List profiles |
| `cr status` | Show current state |
| `cr use NAME` | Switch config/auth only |
| `cr switch NAME` | Switch and launch Codex |
| `cx` | Launch Codex with the active profile |
| `cr model PROFILE MODEL [REASONING\|auto\|keep]` | Set model; omitted third arg uses Auto instead of inheriting old reasoning |
| `cr endpoint PROFILE URL` | Set per-user endpoint |
| `cr speed [PROFILE]` | Direct HTTPS speed test |
| `cr key` | Show key status |
| `cr key set PROFILE` | Save/update key |
| `cr key remove PROFILE` | Remove key |
| `cr check [PROFILE]` | Network diagnostics |
| `cr direct [PROFILE]` | Direct-route repair |
| `cr services` | Show current-user Codex processes |
| `cr stop` | Stop current-user Codex processes |
| `cr history [N]` | Recent chats |
| `cr search KEYWORD` | Search chats |
| `cr recover-menu` | Interactive single-chat recovery |
| `cr resume THREAD_ID [PROFILE]` | Resume by thread ID |
| `cr resume-all [PROFILE]` | Open all resumable chats |
| `cr health` | History health check |
| `cr backup` | Back up history |
| `cr reindex` | Rebuild history index |
| `cr repair-history` | Backup + repair + reindex |\n| `cr restore-all` | Stop current-user Codex, back up, restore all history, then open all chats |\n| `cr all-history` | Open all provider chats without repairing the database |
| `cr language zh/en` | Change UI language |

Full help:

```bash
cr help
```

## Requirements

Core:

- Linux
- Bash
- Python 3
- curl
- OpenAI Codex CLI

Optional advanced features:

- `dig` / `dnsutils`
- `sqlite3`

Ubuntu / Debian:

```bash
sudo apt update
sudo apt install -y curl dnsutils sqlite3 python3
```

## NO_COLOR

```bash
NO_COLOR=1 cr
NO_COLOR=1 cr menu
```

## Security Notes

Never commit:

```text
~/.codex/auth.json
~/.codex/sessions/
~/.codex/state_5.sqlite
~/.codex-relay/secrets/
.env
API keys or tokens
```

Codex-Relay is designed to:

- hide key input;
- use restrictive key-file permissions;
- back up `auth.json` before replacement;
- back up history before repair;
- require explicit confirmation for destructive operations;
- stop only the current Linux user's Codex processes.

## FAQ

<details>
<summary><strong>Does Codex-Relay replace the official Codex CLI?</strong></summary>

No. It launches the normal system `codex` executable after preparing the current user's native config/auth state.

</details>

<details>
<summary><strong>Why do old chats appear to disappear after switching providers?</strong></summary>

Usually the data is still present. Codex may filter the normal history view by the active `model_provider`. Use `cr recover-menu` for an all-provider Relay view.

Use the database/index repair action only when `cr health` shows that rollout, SQLite, or index data is actually inconsistent. Do not bulk-rewrite old thread `model_provider` values merely to make them visible.

</details>

<details>
<summary><strong>Why can a network check return HTTP 401 and still be considered reachable?</strong></summary>

Because 401 proves the request reached the remote HTTP service. Authentication validity and network reachability are separate concerns.

</details>

<details>
<summary><strong>Why recommend Git clone instead of a one-line raw installer?</strong></summary>

Some campus, datacenter, and server networks allow `github.com` while blocking `raw.githubusercontent.com`. Git clone is therefore the more robust default.

</details>

<details>
<summary><strong>Can I use a provider that only supports /chat/completions?</strong></summary>

Not through the current custom-provider flow. It configures Codex with `wire_api = "responses"`, so OpenAI Responses API compatibility is required.

</details>

## CI

Every push and pull request runs:

```bash
bash -n codex-relay
bash -n install.sh
```

Workflow:

```text
.github/workflows/shell-syntax.yml
```

## Contributing

Issues and pull requests are welcome.

Before submitting:

```bash
bash -n codex-relay
bash -n install.sh
```

For changes touching auth, history databases, or process management:

- never include real keys or tokens;
- never copy another Linux user's `auth.json`;
- never use sudo to kill unrelated users' Codex processes;
- prefer backup + conservative repair over destructive history changes.

## License

> [!IMPORTANT]
> This repository currently does not contain a `LICENSE` file. That means the source is publicly visible, but explicit permission to copy, modify, and redistribute has not yet been granted.
>
> Before the first formal open-source release, choose and add a license such as MIT, Apache-2.0, or GPL-3.0.

## Acknowledgements

Codex-Relay works around the native configuration and local data model of OpenAI Codex CLI. Thanks to everyone testing it across Linux, SSH, multi-user servers, and unusual network environments.

---

<div align="center">

If Codex-Relay is useful to you, Stars, Issues, and Pull Requests are welcome.

**One binary. Per-user isolation. Native Codex.**

</div>
