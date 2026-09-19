<div align="center">

# Codex-Relay

**Linux / SSH 上的 OpenAI Codex CLI 路由切换与运维工具**

Keep the official `codex` binary. Switch providers, keys, models, network routes, and local history safely.

[![Shell syntax check](https://github.com/heu-gj/Codex-Relay/actions/workflows/shell-syntax.yml/badge.svg)](https://github.com/heu-gj/Codex-Relay/actions/workflows/shell-syntax.yml)
![Linux](https://img.shields.io/badge/platform-Linux-1793D1?logo=linux&logoColor=white)
![Bash](https://img.shields.io/badge/shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![Codex CLI](https://img.shields.io/badge/Codex_CLI-native-111827)

[简体中文](./README.md) · [English](./README_EN.md)

</div>

---

Codex-Relay 是一个面向 **Linux / SSH / 多用户服务器** 的 Bash 工具，用来管理 OpenAI Codex CLI 的 provider、API Key、模型、网络直连与本地聊天历史。

它**不是代理服务器，也不会替换 OpenAI 官方 Codex CLI**。它做的事情很简单：在启动官方 `codex` 前，为当前 Linux 用户安全地准备好 `~/.codex/config.toml`、`~/.codex/auth.json` 和必要的网络环境。

> [!NOTE]
> 项目内置的 Nova / baibai 只是便捷 profile。第三方服务的可用性、价格、模型和服务条款由对应服务商决定；Codex-Relay 与 OpenAI 或这些第三方服务商均无隶属关系。

## 为什么需要 Codex-Relay

如果你在一台服务器上经常遇到这些情况：

- 需要在 **官方 OpenAI / Nova / baibai / 自定义中转站**之间切换；
- 不想改动或包装官方 `codex` 可执行文件；
- 多个 Linux 用户共用服务器，但 **API Key、认证和聊天必须彼此隔离**；
- Shell 里残留了 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY`，导致 Codex 错走本地代理；
- 想先读取中转站可用模型，再选择默认模型；
- DNS / HTTPS 直连异常，希望有诊断与可验证的 `/etc/hosts` 修复流程；
- 切换 provider 后，仍希望保留、搜索、恢复原来的 Codex 聊天；

那么 Codex-Relay 就是为这种环境设计的。

## 功能一览

| 能力 | 说明 |
| --- | --- |
| 🚦 Route Switcher | 卡片式切换官方 OpenAI、内置或自定义 provider |
| 🔐 每用户独立凭据 | API Key 存在当前用户自己的 `~/.codex-relay/secrets/` |
| 🧠 模型发现 | 自动尝试 `/models` / `/v1/models`，可直接编号选择 |
| ⚡ 原生 Codex | 不替换 `codex`，只切换官方配置和认证文件 |
| 🌐 无代理启动 | 启动 Codex 时清除 HTTP/HTTPS/ALL proxy |
| 🩺 网络诊断 | System DNS、TCP DNS、HTTPS 与直连测速 |
| 🧭 Direct 修复 | 验证候选 IP 后才允许写入 `/etc/hosts` |
| 💬 聊天管理 | 最近聊天、搜索、单条恢复、全部历史恢复 |
| 🧰 历史修复 | 备份、SQLite 修复、索引重建、健康检查 |
| 👥 多用户隔离 | 主程序可全局共用，用户配置 / Key / 聊天互不共享 |
| 🌏 中英文 UI | 中文默认，可切换 English |
| 🎨 NO_COLOR | 支持无彩色终端 |

## 30 秒上手

### 管理员：安装主程序

推荐通过 GitHub 主站安装，避免部分网络无法访问 `raw.githubusercontent.com`：

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

验证：

```bash
/usr/local/bin/codex-relay help
```

### 普通用户：配置快捷命令

服务器已经安装 `/usr/local/bin/codex-relay` 后，普通用户**不需要再访问 GitHub**：

```bash
cat >> ~/.bashrc <<'EOF'

alias cr='/usr/local/bin/codex-relay'
alias cx='/usr/local/bin/codex-relay run'
EOF

source ~/.bashrc
```

第一次为需要使用的中转站保存当前用户自己的 Key：

```bash
cr key set nova
cr key set baibai
```

然后直接：

```bash
cr
```

或：

```bash
cr switch nova
cr switch baibai
```

## 界面预览

### Route Switcher

直接执行 `cr`：

```text
CODEX RELAY // 路由切换器

◆ 当前路由
  ● BAIBAI
    gpt-5.6-sol · xhigh  →  api.sharesai.xyz  →  NET ✓ Direct · 168 ms

◆ 可用中转站

  [1]  BAIBAI   ● ACTIVE   BUILT-IN
       ├─ model    gpt-5.6-sol · xhigh
       └─ route    api.sharesai.xyz   ✓ KEY   NET ✓ Direct · 168 ms

  [2]  NOVA     ○ STANDBY  BUILT-IN
       ├─ model    gpt-5.5
       └─ route    ai.novacode.top    ✓ KEY   NET 未检测

────────────────────────────────────────────────
  [Enter] 启动当前 Codex
  [A]     添加中转站
  [R]     刷新当前路由网络
  [M]     打开完整控制中心
  [0]     退出
```

菜单重绘只读取本地状态和缓存，**不会为了展示页面自动发网络请求**。网络刷新由用户主动按 `R` 触发。

### Control Center

```bash
cr menu
```

```text
CODEX RELAY // 控制中心

◆ 当前状态
  中转站       ● baibai
  model        gpt-5.6-sol · xhigh
  endpoint     api.sharesai.xyz
  API Key      ✓ 已设置
  网络         ✓ Direct · 168 ms
  Codex CLI    0.x.x
  daemon       0.x.x
  Codex 进程   2

◆ 功能
  [1] 中转站
  [2] 聊天历史
  [3] 网络与服务
  [4] 设置

  [Enter] 启动当前 Codex
  [R]     刷新状态
  [Q]     退出
```

## 安装与升级

### 推荐：Git Clone 安装

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

以后升级时重复执行即可。因为主程序位于 `/usr/local/bin/codex-relay`，服务器所有用户会使用同一份最新版；每个人的个人配置仍保持独立。

### 可选：Raw 安装

当服务器能访问 `raw.githubusercontent.com` 时：

```bash
curl -fsSL https://raw.githubusercontent.com/heu-gj/Codex-Relay/main/install.sh \
  | sudo bash -s -- --global
```

如果看到：

```text
curl: (7) Failed to connect to raw.githubusercontent.com port 443
```

直接改用上面的 `git clone` 方式。

### 从旧的用户级版本迁移

如果以前有：

```text
~/bin/codex-relay
```

建议先备份：

```bash
mv ~/bin/codex-relay \
  ~/bin/codex-relay.user-backup.$(date +%Y%m%d-%H%M%S) \
  2>/dev/null || true

hash -r
```

然后让 `cr` / `cx` 明确指向 `/usr/local/bin/codex-relay`。

## Provider 与模型

### 切换 Provider

只切换配置，不启动：

```bash
cr use nova
cr use baibai
```

切换并启动官方 Codex：

```bash
cr switch nova
cr switch baibai
```

使用当前 profile 启动：

```bash
cx
```

### 读取并选择可用模型

进入：

```text
cr
→ 选择一个 relay provider
→ [2] 选择 / 修改默认模型
```

Relay 会使用当前用户保存的 API Key 尝试读取：

```text
<Base URL>/models
<Base URL>/v1/models
```

读取成功后可以直接按编号选择：

```text
CODEX RELAY // MODEL // BAIBAI

当前模型     gpt-5.6-sol

◆ 可用模型
 [1] gpt-5.5
 [2] gpt-5.6
 [3] gpt-5.6-sol      ● 当前
 [4] ...

 [R] 重新读取模型列表
 [M] 手动输入模型 ID
 [0] 返回
```

选择模型后，Relay 会继续进入 **Reasoning Effort / 推理强度** 页面，再一次性保存模型与推理配置：

```text
REASONING // BAIBAI

◆ 即将应用
  模型           gpt-5.6-sol
  当前推理强度   xhigh

◆ 推理强度
  [Enter] Auto      推荐 · 不写 model_reasoning_effort
  [K]     保持当前  xhigh
  [N]     None
  [1]     Minimal
  [2]     Low
  [3]     Medium
  [4]     High
  [5]     XHigh
  [M]     手动填写
  [0]     取消，不修改模型
```

不同模型支持的 reasoning effort 不完全一致，因此对未知或自定义模型，默认推荐 **Auto**。Auto 的含义是清除旧的 `model_reasoning_effort`，让 Codex / 模型使用自己的默认行为，而不是写入字符串 `"auto"`。

如果在推理强度页面取消，模型也不会被修改，不会出现“模型已经换了但 reasoning 还没选完”的半状态。

如果服务商不提供模型枚举接口，仍可以手动输入。CLI 也支持同时指定推理强度：

```bash
cr model PROFILE MODEL               # 默认 Auto：清除旧 reasoning
cr model PROFILE MODEL high          # 明确使用 high
cr model PROFILE MODEL xhigh         # 明确使用 xhigh
cr model PROFILE MODEL keep          # 保留当前 reasoning
```

内置 baibai 的初始默认仍然是 `gpt-5.6-sol + xhigh`；只有用户主动修改模型时，才应用上述新规则。

### 添加自定义中转站

在 Route Switcher 中按 `A` 进入 4 步向导：

1. 中转站名称
2. API Base URL
3. 默认模型
4. Provider ID

保存前会显示完整配置预览，只有输入 `YES` / `确认` 后才写入。

> [!IMPORTANT]
> 自定义中转站使用 Codex 的 `wire_api = "responses"`。服务商必须支持 **OpenAI Responses API**。如果只支持 `/chat/completions` 而不支持 `/responses`，不能直接使用当前向导。

Base URL **不会自动补 `/v1`**。是否包含 `/v1` 必须以服务商文档为准。

## API Key 与认证

每个 relay provider 的 Key 都保存在当前用户自己的：

```text
~/.codex-relay/secrets/<profile>.key
```

权限：

```text
~/.codex-relay/          700
*.key                    600
```

常用命令：

```bash
cr key
cr key set PROFILE
cr key remove PROFILE
```

激活 relay provider 时，Codex-Relay 会按 Codex 原生 API-key 结构写入当前用户的：

```text
~/.codex/auth.json
```

真实 Key **不会写进 `config.toml`**。

如果检测到原来的官方 ChatGPT/Codex 登录，Relay 会保存快照：

```text
~/.codex-relay/auth/official.json
```

之后切回：

```bash
cr use official
```

即可恢复官方认证。

> [!WARNING]
> 更新或删除**当前正在使用的** relay Key 时，Codex-Relay 会停止当前 Linux 用户的 Codex 服务/进程，使新认证确定生效。这可能中断该用户正在运行或排队的任务。修改非当前 provider 的 Key 不会停止正在运行的 Codex。

## 网络与 Direct 模式

Codex-Relay 启动 Codex 时会清理：

```text
http_proxy
https_proxy
HTTP_PROXY
HTTPS_PROXY
all_proxy
ALL_PROXY
```

因此不会因为当前 Shell 遗留的 `127.0.0.1:7897` 等代理而自动走 VPN/代理。

### 网络诊断

```bash
cr check nova
cr check baibai
```

诊断包括：

- System DNS
- TCP DNS
- HTTPS 直连
- Shell proxy 状态

只要能够收到有效 HTTP 状态码，就说明 DNS/TCP/TLS/HTTP 链路已经到达服务端。比如 `401` / `403` 可能是认证问题，但不等同于网络不可达。

### Direct 修复

```bash
cr direct PROFILE
```

流程：

```text
普通直连
   │
   ├─ 成功 → 不修改系统
   │
   └─ 失败
        ↓
TCP DNS 查询
        ↓
获取候选 IPv4
        ↓
curl --resolve 验证 TLS / HTTPS
        ↓
验证成功后才写 /etc/hosts
```

修改前会备份 `/etc/hosts`。

> [!CAUTION]
> `/etc/hosts` 是系统级配置，需要 sudo 权限。Codex-Relay 不会为官方 OpenAI 固定 CDN/IP 映射。

## 聊天历史与恢复

聊天记录始终属于**当前 Linux 用户的 Codex 数据目录**，不是某个 relay provider：

```text
~/.codex/sessions/
~/.codex/archived_sessions/
~/.codex/state_5.sqlite
~/.codex/session_index.jsonl
```

所以从 baibai 切到 Nova，并不会把 baibai 时期的聊天“搬走”。

### 查看与搜索

```bash
cr history 100
cr search 关键词
```

### 继续一条旧聊天

```bash
cr recover-menu
```

Session Picker 会展示时间、原 provider、model 和标题，并允许选择后续使用原 provider、Nova、baibai、official 或当前路由。

### 一键恢复全部聊天记录

如果你的目标是“把当前用户所有还能找到的历史聊天都恢复回来，并马上进入全部聊天列表”，直接使用：

```bash
cr restore-all
```

或者：

```text
cr menu
→ [2] 聊天历史
→ [8] 一键恢复全部聊天记录
```

确认后会执行完整恢复链路：

```text
确认没有重要运行/排队任务
        ↓
停止当前用户 Codex
        ↓
备份 SQLite / index / rollout
        ↓
扫描 sessions / archived_sessions
        ↓
补回 SQLite 缺失 thread / 修复安全元数据
        ↓
读取当前 profile 的 P_PROVIDER
        ↓
把全部历史 thread 的 model_provider
迁移到当前 provider
        ↓
同步修改 rollout 的 session_meta.model_provider
        ↓
重建 / 检查 session_index 与 SQLite
        ↓
自动打开全部聊天
```

它不写死 baibai、Nova 或任何自定义中转站。目标 provider 始终取**当前激活 profile 的 `P_PROVIDER`**；来源 provider 则直接从 SQLite / rollout 的真实历史中扫描。因此即使某个旧自定义中转站已经从 `relays.tsv` 删除，只要聊天 rollout 仍存在，也可以迁移到当前中转站继续使用。

例如当前路由是 Nova，历史里同时存在 `baibai`、旧 Nova provider、自定义 provider 或其他 provider，`restore-all` 会在完整备份后把这些历史的 `model_provider` 统一迁移到 Nova 当前的 provider。切到 baibai、official 或任意自定义 profile 后执行同一命令，则自动迁移到对应当前 provider。

迁移只修改 provider 元数据，不修改消息正文、标题或工具记录。不同后端对旧会话中 provider-specific 状态的兼容性仍取决于目标服务。

如果聊天库本身是健康的、只是想查看当前 Codex 能列出的全部聊天而**不修改 provider 元数据**，可以直接：

```bash
cr all-history
```

这只打开全部聊天，不修改数据库。

命令行保守修复模式仍然保留：

```bash
cr stop
cr repair-history
```

## 多用户服务器设计

推荐结构：

```text
/usr/local/bin/codex-relay        # 所有人共用一份程序

/home/userA/.codex/               # userA 的 Codex 数据
/home/userA/.codex-relay/         # userA 的 Relay 状态 / Key / 备份

/home/userB/.codex/
/home/userB/.codex-relay/
```

设计原则：

- 主程序全局共用；
- `~/.codex/` 仍完全属于当前用户；
- `~/.codex-relay/` 也完全属于当前用户；
- API Key 不跨用户共享；
- `auth.json` 不跨用户共享；
- 聊天数据库不跨用户共享；
- 模型 / endpoint override 不影响其他用户；
- `cr stop` 只处理当前 Linux 用户，不 sudo 停止其他用户进程。

## 数据目录

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

Codex 原生数据与 Relay 管理状态分开，升级主程序不会覆盖个人聊天和凭据。

## 内置 Profiles

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

Nova 的 Base URL 故意不自动追加 `/v1`。Relay 也不会写入不存在的 `model_catalog_json`。

</details>

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `cr` | 打开 Route Switcher |
| `cr menu` | 打开完整 Control Center |
| `cr list` | 查看所有 profile |
| `cr status` | 查看当前状态 |
| `cr use NAME` | 切换 config/auth，不启动 |
| `cr switch NAME` | 切换 config/auth 并启动 Codex |
| `cx` | 使用当前 profile 启动官方 Codex |
| `cr model PROFILE MODEL [REASONING\|auto\|keep]` | 修改模型；省略第三参数时使用 Auto，避免继承旧模型 reasoning |
| `cr endpoint PROFILE URL` | 修改当前用户 endpoint |
| `cr speed [PROFILE]` | 无代理 HTTPS 测速 |
| `cr key` | 查看 Key 状态 |
| `cr key set PROFILE` | 保存 / 更新 Key |
| `cr key remove PROFILE` | 删除 Key |
| `cr add ...` | 命令行添加自定义 provider |
| `cr delete PROFILE` | 删除自定义 provider |
| `cr check [PROFILE]` | 网络诊断 |
| `cr direct [PROFILE]` | Direct 修复 |
| `cr services` | 查看当前用户 Codex 进程 |
| `cr stop` | 停止当前用户全部 Codex |
| `cr history [N]` | 最近聊天 |
| `cr search KEYWORD` | 搜索聊天 |
| `cr recover-menu` | 交互式恢复一条聊天 |
| `cr resume THREAD_ID [PROFILE]` | 按 ID 恢复 |
| `cr resume-all [PROFILE]` | 打开全部可恢复聊天 |
| `cr health` | 历史健康检查 |
| `cr backup` | 备份聊天历史 |
| `cr reindex` | 重建索引，要求先停止 Codex |
| `cr repair-history` | 备份 + 修复 + 重建索引 |\n| `cr restore-all` | 停止 Codex、备份、修复历史并迁移全部聊天到当前 provider 后打开列表 |\n| `cr all-history` | 不修数据库，直接打开当前用户全部 provider 聊天 |
| `cr language zh/en` | 切换界面语言 |

完整帮助：

```bash
cr help
```

## 依赖

基础功能：

- Linux
- Bash
- Python 3
- curl
- OpenAI Codex CLI

高级网络 / 历史功能：

- `dig`（Ubuntu/Debian: `dnsutils`）
- `sqlite3`

Ubuntu / Debian：

```bash
sudo apt update
sudo apt install -y curl dnsutils sqlite3 python3
```

## 无彩色模式

```bash
NO_COLOR=1 cr
NO_COLOR=1 cr menu
```

## 安全说明

请**不要**提交这些内容：

```text
~/.codex/auth.json
~/.codex/sessions/
~/.codex/state_5.sqlite
~/.codex-relay/secrets/
.env
任何 API Key / Token
```

项目会尽量做到：

- Key 输入不回显；
- Key 文件权限为 `600`；
- Secret 目录权限为 `700`；
- 覆盖 `auth.json` 前先备份；
- 历史修复前先备份；
- 危险操作要求明确确认；
- 停止 Codex 时只影响当前 Linux 用户。

## 常见问题

<details>
<summary><strong>Codex-Relay 会替换官方 Codex CLI 吗？</strong></summary>

不会。最终启动的仍然是系统中的官方 `codex` 命令。Relay 只负责准备当前用户的配置、认证和启动环境。

</details>

<details>
<summary><strong>从 baibai 切到 Nova 后，为什么以前的聊天看起来不见了？</strong></summary>

通常不是数据丢失，而是 Codex 的历史列表按当前 `model_provider` 过滤。请先用 `cr recover-menu` 或 `cr menu → 聊天历史 → [3] 跨中转恢复聊天` 查看全部 provider 的本地会话。

只有 `cr health` 显示 SQLite / index 与 rollout 不一致时，才需要使用 `[8] 修复聊天库 / 索引`。不要为了“让列表显示”而批量把旧线程的 `model_provider` 改成当前 provider。

</details>

<details>
<summary><strong>为什么网络诊断出现 HTTP 401，但 Codex 服务器其实能访问？</strong></summary>

401 表示请求已经到达服务端，只是认证未通过。网络诊断关注的是 DNS / TCP / TLS / HTTP 链路是否可达；API Key 是否有效是另一层问题。

</details>

<details>
<summary><strong>为什么不用 raw.githubusercontent.com 安装？</strong></summary>

部分校园网、机房或服务器 DNS 环境可以访问 github.com，但会阻断 raw.githubusercontent.com。因此 README 默认推荐 `git clone`。

</details>

<details>
<summary><strong>自定义服务只支持 /chat/completions 可以吗？</strong></summary>

当前自定义 provider 写入 `wire_api = "responses"`，因此需要服务商支持 OpenAI Responses API。

</details>

<details>
<summary><strong>修改 API Key 会不会中断正在运行的任务？</strong></summary>

只有修改当前激活 provider 的 Key 时，Relay 才会停止当前 Linux 用户的 Codex 进程以确保新认证生效。修改非当前 provider 的 Key 不会打断当前 Codex。

</details>

## CI

每次 push / pull request 都会执行：

```bash
bash -n codex-relay
bash -n install.sh
```

工作流：

```text
.github/workflows/shell-syntax.yml
```

## Contributing

Issues 和 Pull Requests 都欢迎。

提交前建议至少运行：

```bash
bash -n codex-relay
bash -n install.sh
```

涉及认证、历史数据库、进程管理时，请特别注意：

- 不要提交真实 Key / Token；
- 不要复制其他 Linux 用户的 `auth.json`；
- 不要用 sudo 批量停止其他用户的 Codex；
- 历史修复应优先采用“备份 + 保守修改”，不要无条件删除原始 rollout。

## License

> [!IMPORTANT]
> 当前仓库还没有添加 `LICENSE` 文件。**在法律意义上，这意味着代码公开可见，但尚未授予他人明确的复制、修改和分发许可。**
>
> 如果准备正式作为开源项目发布，建议在第一个正式 Release 前选择并添加合适的许可证，例如 MIT、Apache-2.0 或 GPL-3.0。

## Acknowledgements

Codex-Relay 围绕 OpenAI Codex CLI 的原生配置和本地数据工作。感谢所有愿意测试不同 Linux、SSH、多用户和网络环境的使用者与贡献者。

---

<div align="center">

如果 Codex-Relay 对你有帮助，欢迎 Star、Issue 或 PR。

**One binary. Per-user isolation. Native Codex.**

</div>
