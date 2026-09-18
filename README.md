# Codex-Relay

一个面向 Linux / SSH 服务器的 Codex CLI 中转站管理器。

它解决几类常见问题：

- 在 **Nova / baibai / 官方 OpenAI / 自定义中转站**之间快速切换
- 保持 OpenAI 官方 `codex` 可执行文件不变，只切换 `~/.codex/config.toml` 和 `~/.codex/auth.json`
- 启动 Codex 时清理 `HTTP_PROXY / HTTPS_PROXY / ALL_PROXY`，避免依赖本机 VPN/7897
- 检查 DNS、TCP DNS、HTTPS 直连
- 普通 DNS 异常时，验证候选 IP 后可选择写入 `/etc/hosts`
- 查看、搜索、恢复 Codex 本地聊天
- 一键检查/备份/修复 Codex 历史数据库与索引
- 支持多用户：脚本可以共用，每个用户仍使用自己的 `~/.codex`

> 适用于你有权使用的 API 服务和网络环境。请遵守所使用中转站、学校/单位网络和服务提供商的相关条款。

## 内置配置

### baibai

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

### nova

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

Nova 默认**不会**写入不存在的 `model_catalog_json`，避免 Codex 启动时报 `No such file or directory`。

## 推荐安装方式：全局程序 + 每用户独立配置

多人服务器推荐只维护一份主程序：

```text
/usr/local/bin/codex-relay
```

每个用户仍然使用自己的 Codex 数据目录：

```text
~/.codex/config.toml
~/.codex/auth.json
~/.codex/sessions/
~/.codex/state_5.sqlite
```

而 Codex-Relay 自己的状态独立放在：

```text
~/.codex-relay/current
~/.codex-relay/relays.tsv
~/.codex-relay/official-model
~/.codex-relay/language
~/.codex-relay/secrets/      # 当前用户保存的各中转站 API Key
~/.codex-relay/auth/          # 官方 Codex 登录快照 / daemon 刷新状态
~/.codex-relay/cache/         # Dashboard 的网络 / 额度短缓存
~/.codex-relay/overrides/    # 当前用户自己的模型 / endpoint 覆盖
~/.codex-relay/backups/      # config.toml / auth.json / history 备份
```

这样 `~/.codex` 只保留 Codex 本身的数据，relay 的 profile、语言、当前选择和备份不会再混进去。

### 1. 管理员：全局安装 / 更新

#### 推荐方式：通过 GitHub 主站 `git clone`

某些校园网、服务器网络或 DNS 环境可能无法连接 `raw.githubusercontent.com`，但仍然可以访问 `github.com`。这种情况下推荐：

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

以后 GitHub 有更新时，管理员重新执行上面这组命令即可。所有用户会立即使用新的全局版本。

#### 可选方式：`raw.githubusercontent.com` 可访问时

如果服务器能正常访问 `raw.githubusercontent.com`，也可以直接：

```bash
curl -fsSL https://raw.githubusercontent.com/heu-gj/Codex-Relay/main/install.sh \
  | sudo bash -s -- --global
```

如果看到：

```text
curl: (7) Failed to connect to raw.githubusercontent.com port 443
```

不要继续重试这条命令，改用上面的 `git clone` 安装方式。

### 2. 新用户：不需要访问 GitHub

只要管理员已经安装：

```text
/usr/local/bin/codex-relay
```

新用户第一次登录后**不需要下载或安装 codex-relay**。

配置快捷命令：

```bash
cat >> ~/.bashrc <<'EOF'

alias cr='/usr/local/bin/codex-relay'
alias cx='/usr/local/bin/codex-relay run'
EOF

source ~/.bashrc
```

第一次使用时，为每个中转站保存当前用户自己的 API Key（输入过程不会回显）：

```bash
cr key set nova
cr key set baibai
```

然后可以一条命令切换并启动：

```bash
cr switch nova
cr switch baibai
```

也可以继续使用两步方式：

```bash
cr use nova
cx
```

如果某个 profile 还没有保存 Key，第一次启动时会自动提示输入一次；以后在该用户下切换时会自动加载对应 Key。

确认当前使用的是全局程序：

```bash
type -a codex-relay
command -v codex-relay
alias cr
alias cx
```

推荐结果：

```text
/usr/local/bin/codex-relay
```

其中：

```bash
alias cr='/usr/local/bin/codex-relay'
alias cx='/usr/local/bin/codex-relay run'
```

### 3. 旧用户从用户级版本迁移到全局版本

如果之前存在：

```text
~/bin/codex-relay
```

建议先备份或删除它，避免 PATH 优先命中旧版本：

```bash
mv ~/bin/codex-relay \
  ~/bin/codex-relay.user-backup.$(date +%Y%m%d-%H%M%S) \
  2>/dev/null || true

hash -r
```

然后把 `cr` / `cx` 明确指向：

```text
/usr/local/bin/codex-relay
```

> 重点：程序全局共用，但每个用户的 `~/.codex` 仍然独立。因此不会共享 API Key，也不会串聊天记录。

旧版曾写在 `~/.codex` 里的 `.relay-current`、`relays.tsv`、`.official-model` 等管理器状态，新版第一次运行时会自动迁移到 `~/.codex-relay/`；不会移动或修改 Codex 的认证、session 和数据库。

## 快速开始

像 CC-Switch 一样，直接运行：

```bash
cr
```

会进入 **中转站管理器**。这里可以查看当前中转站、模型、Key 状态，并进行切换、编辑、测速、添加和删除。

完整控制中心使用：

```bash
cr menu
```

新版 `cr menu` 是 Dashboard，而不是 17 项长菜单。首页会显示：

```text
当前中转站
模型 / endpoint
API Key 状态
无代理直连状态与延迟
Codex CLI 版本
后台 daemon 版本（版本不一致会警告）
当前用户 Codex 进程数
Shell proxy 状态
官方 Codex 额度
```

下面只保留四个一级入口：

```text
[1] 中转站
[2] 聊天历史
[3] 网络与服务
[4] 设置

[Enter] 启动当前 Codex
[R] 刷新状态
[Q] 退出
```

切到 Nova：

```bash
cr use nova
cx
```

切到 baibai：

```bash
cr use baibai
cx
```

`cx` 等价于：

```bash
codex-relay run
```

启动时会清除：

```text
http_proxy
https_proxy
HTTP_PROXY
HTTPS_PROXY
all_proxy
ALL_PROXY
```

因此 Codex 不会因为当前 shell 残留 `127.0.0.1:7897` 而依赖 VPN。

## 每用户 / 每中转站独立 API Key

这是多人服务器模式下的核心设计：**同一个全局 `codex-relay`，每个 Linux 用户都有自己的 Key，而且 Nova、baibai、自定义中转站之间互不共用。Codex 本身仍然是 OpenAI 官方版本。**

每个中转站的 Key 长期保存在当前用户自己的：

```text
~/.codex-relay/secrets/nova.key
~/.codex-relay/secrets/baibai.key
```

目录权限为 `700`，Key 文件权限为 `600`。

设置或更新 Key：

```bash
cr key set nova
cr key set baibai
```

查看是否已设置（不会显示 Key 内容）：

```bash
cr key
```

切换到中转站时，Codex-Relay 会同时处理两份 **Codex 原生文件**：

```text
~/.codex/config.toml
~/.codex/auth.json
```

例如 Nova 激活后，`config.toml` 保持标准 provider 写法：

```toml
[model_providers.OpenAI]
name = "OpenAI"
base_url = "https://ai.novacode.top"
wire_api = "responses"
requires_openai_auth = true
```

而当前激活 Key 使用 Codex 官方 API-key 登录结构写入 `auth.json`：

```json
{
  "auth_mode": "apikey",
  "OPENAI_API_KEY": "<当前 Nova Key>"
}
```

真实 Key 不会写进 `config.toml`。每次覆盖 `auth.json` 前都会备份到：

```text
~/.codex-relay/backups/auth/
```

如果检测到原来的 ChatGPT 官方登录，Relay 会保存完整快照：

```text
~/.codex-relay/auth/official.json
```

之后 `cr use official` / `cr switch official` 会恢复这份官方认证，因此可以在：

```text
Nova → baibai → 官方 ChatGPT → Nova
```

之间切换而不反复登录。

切换并直接启动：

```bash
cr switch nova
cr switch baibai
```

如果通过 `cr key set PROFILE` 更新的是**当前正在使用的中转站**，Relay 会立即同步 `~/.codex/auth.json`，然后自动执行当前用户级的 Codex 停止流程，让新 Key 在下次启动时确定生效。这个停止流程只影响当前 Linux 用户，但会中断该用户正在运行或排队的 Codex 工作。

如果更新的是**非当前中转站**，Relay 只保存新的 Key，不会打断当前 Codex。等以后切换到该中转站时再应用。

`cr use PROFILE` 只负责切换 config/auth，不主动启动 Codex；`cr switch PROFILE` 会切换并启动。若切换导致认证变化，启动前仍会刷新旧 app-server daemon。

> 已经运行中的 Codex 会话不会热切换 provider。API Key 或中转站发生变化后，应启动新的 Codex 会话；Relay 会负责当前用户的必要服务刷新，不再需要手动粘贴 API Key。

## 官方 Codex 额度

如果当前用户保存过官方 ChatGPT / Codex 登录，`cr menu` 首页会显示该账号的 Codex 使用额度，例如：

```text
官方额度    5h 82% · 7d 64% · credits 10
```

查看详细额度和重置时间：

```bash
cr quota
```

强制刷新：

```bash
cr quota --refresh
```

额度缓存 60 秒，保存在：

```text
~/.codex-relay/cache/official-quota.json
```

缓存只保存套餐、剩余百分比、重置时间和 credits 等归一化信息，不保存 access token、account id 或 API Key。

官方额度读取使用已经保存的官方 ChatGPT 登录；即使当前正在使用 Nova / baibai，只要之前保存过官方登录快照，Dashboard 仍可以显示官方 Codex 额度。

对于 Nova / baibai / 自定义中转站，只有服务商存在明确且稳定的公开额度接口时才适合自动读取。当前没有可靠统一接口时，Dashboard 会显示：

```text
中转额度    N/A · 服务商未提供稳定公开接口
```

而不会猜测余额。

## 语言设置

Codex-Relay **默认使用中文界面**。

第一次运行时，如果还没有语言配置文件，会自动使用：

```text
zh
```

语言设置保存在当前用户自己的：

```text
~/.codex-relay/language
```

查看当前语言：

```bash
cr language
```

切换到中文：

```bash
cr language zh
```

切换到英文：

```bash
cr language en
```

也可以在：

```bash
cr menu
```

中选择 **语言设置**。

语言设置是**每个用户独立**的，因此同一台服务器可以：

```text
userA → 中文
userB → English
userC → 中文
```

而所有人仍然共用同一个：

```text
/usr/local/bin/codex-relay
```

## CC-Switch 风格中转站管理

打开交互式中转站管理器：

```bash
cr
```

等价于：

```bash
cr providers
```

也可以在：

```bash
cr menu
```

中选择 **[1] 中转站**。

列表会显示当前激活中转站、模型以及 API Key 是否已经配置。进入某个中转站后可以直接：

- 切换并启动 Codex
- 修改当前用户的默认模型
- 修改当前用户的 API 地址
- 设置 / 更新当前用户自己的 API Key
- 无代理 HTTPS 测速
- DNS / HTTPS 网络诊断
- 重置当前用户的模型 / endpoint 修改
- 删除自定义中转站

例如只修改当前用户的 Nova 默认模型：

```bash
cr model nova gpt-5.6
```

只修改当前用户看到的 Nova endpoint：

```bash
cr endpoint nova https://example.com
```

测速：

```bash
cr speed nova
cr speed baibai
```

这些修改不会写进全局的 `/usr/local/bin/codex-relay`，而是保存在当前用户自己的：

```text
~/.codex-relay/overrides/nova.conf
~/.codex-relay/overrides/baibai.conf
~/.codex-relay/overrides/<自定义中转站>.conf
```

因此同一台服务器可以出现：

```text
userA: Nova → gpt-5.5
userB: Nova → gpt-5.6
userC: Nova → 另一个兼容 endpoint
```

互相不影响。

内置的 `nova` / `baibai` 可以按用户修改模型、endpoint 和 Key，但不能删除。自定义中转站可以在 `cr providers` 中直接添加和删除；新增时可以立即保存该用户自己的 API Key。

命令行仍然保留：

```bash
cr list
cr status
cr quota
cr services
cr stop
cr use NAME
cr switch NAME
cr model PROFILE MODEL
cr endpoint PROFILE URL
cr speed [PROFILE]
cr add NAME BASE_URL MODEL [PROVIDER_ID] [AUTH]
cr delete PROFILE
cr show-config
```

其中：

- `cr use NAME`：切换 `~/.codex/config.toml` + `~/.codex/auth.json`，但不启动 Codex
- `cr switch NAME`：完成 config/auth 切换，并启动 OpenAI 官方 Codex
- `cx`：使用当前 profile 的 config/auth 启动 OpenAI 官方 Codex

`cr use` / `cr switch` 都使用同一套 `CODEX_HOME`，不会创建第二套 `~/.codex`。

> 正在运行的 Codex 进程不会热加载新的 provider / endpoint / API Key。切换中转站时仍然需要结束当前 Codex 进程并启动新的进程，但 `cr switch PROFILE` 已经把重新配置和重新加载 Key 自动化。

## 当前用户 Codex 服务管理

查看当前 Linux 用户正在运行的 Codex 进程：

```bash
cr services
```

一键停止当前用户全部 Codex 服务和进程：

```bash
cr stop
```

`cr stop` 只处理当前用户，不使用 sudo，也不会停止其他 Linux 用户的 Codex。它会：

1. 先调用 Codex 官方命令：

   ```bash
   codex app-server daemon stop
   ```

2. 再扫描当前用户残留的 `codex` / `codex-*` 进程。
3. 对残留进程发送 `TERM`，短暂等待退出。
4. 对仍未退出的 Codex 进程发送 `KILL`。
5. 最后再次确认当前用户已经没有 Codex 进程。

> `cr stop` 会中断当前用户正在运行或排队的 Codex 工作。执行前确认没有需要保留的活跃任务。

如果只是想停止官方托管的 app-server daemon，可以直接使用：

```bash
codex app-server daemon stop
```

如果准备修改聊天数据库、重建索引或做一键历史修复，推荐先执行：

```bash
cr stop
```

`cr reindex` 和 `cr repair-history` 现在也会检查当前用户是否仍有 Codex 进程；如果有，会直接提示：

```text
请先执行: cr stop
```

完整控制中心 `cr menu` 中也提供 **[17] 停止当前用户全部 Codex**。

## 无 VPN / 无代理直连

只检测：

```bash
cr check nova
cr check baibai
```

第一次配置：

```bash
cr setup nova
cr setup baibai
```

网络异常时重新检查：

```bash
cr direct nova
cr direct baibai
```

处理逻辑：

```text
正常 DNS + HTTPS
        │
        ├── 成功 → 不修改系统
        │
        └── 失败
              ↓
        TCP DNS 查询
              ↓
        获取候选 IPv4
              ↓
        curl --resolve 验证 TLS / HTTPS
              ↓
        验证成功后才允许写 /etc/hosts
```

修改 `/etc/hosts` 前会自动备份。

> `/etc/hosts` 是系统级配置。如果当前用户没有 sudo 权限，需要管理员协助。

## 聊天记录

查看最近聊天：

```bash
cr history
cr history 100
```

搜索：

```bash
cr search 关键词
```

交互恢复：

```bash
cr recover-menu
```

按 ID 恢复：

```bash
cr resume THREAD_ID
```

强制使用指定 profile：

```bash
cr resume THREAD_ID nova
cr resume THREAD_ID baibai
```

列出全部可恢复聊天：

```bash
cr resume-all
```

## 聊天健康检查和一键恢复

检查本地聊天状态：

```bash
cr health
```

它会对比：

- `sessions/**/*.jsonl`
- `state_5.sqlite`
- `session_index.jsonl`

备份：

```bash
cr backup
```

仅重建索引：

```bash
cr stop
cr reindex
```

`cr reindex` 会修改 Codex 本地索引，因此要求当前用户没有运行中的 Codex 进程。

一键恢复：

```bash
cr stop
cr repair-history
```

如果忘记先停止，`cr repair-history` 会检测并提示运行 `cr stop`。

`repair-history` 会先备份，然后保守修复：

- rollout 仍在但 SQLite 缺失的 thread
- 失效的 rollout 路径
- 为空的 provider 元数据
- 缺失的部分 thread 元信息
- `session_index.jsonl`

最后执行 SQLite integrity check 和历史健康检查。

它**不会删除原始 `sessions/*.jsonl`**，也不会无条件覆盖已有正常 provider。

## 多用户结构

推荐最终结构：

```text
/usr/local/bin/codex-relay        # 全局唯一主程序

/home/userA/.codex/               # userA 的 Codex 配置 / 认证 / 聊天
/home/userA/.codex-relay/         # userA 的 relay 状态 / profile / 备份

/home/userB/.codex/
 /home/userB/.codex-relay/

 /home/userC/.codex/
 /home/userC/.codex-relay/
```

因此：

- 主程序只维护一份：`/usr/local/bin/codex-relay`
- GitHub 更新后只需要管理员更新一次
- 新用户不需要访问 GitHub
- `cr` / `cx` 每个用户在自己的 `~/.bashrc` 中配置
- `~/.codex/` 只用于 Codex 自己的配置、认证和聊天
- `~/.codex-relay/` 只用于 Codex-Relay 的状态、profile、语言、API Key、用户覆盖和备份
- `~/.codex-relay/secrets/` 每个用户独立；不同中转站的 Key 也分别保存
- `~/.codex-relay/overrides/` 每个用户独立；模型和 endpoint 修改不会影响其他用户
- `~/.codex/auth.json` 每个用户独立，不要互相复制
- `~/.codex/sessions/` 和 SQLite 聊天数据库每个用户独立
- `/etc/hosts` 是系统级配置，一次有效修改可以被所有用户共享
- 如果 `raw.githubusercontent.com` 无法连接，管理员使用 `git clone https://github.com/...` 更新即可

## 常用命令速查

```bash
cr                          # 打开中转站管理器
cr menu                     # 打开完整控制中心
cr providers                # 同 cr

cr language
cr language zh
cr language en

cr providers
cr model nova gpt-5.6
cr endpoint nova https://example.com
cr speed nova

cr key
cr key set nova
cr key set baibai

cr switch nova
cr switch baibai

cr use nova
cr use baibai
cx

cr check nova
cr setup nova
cr direct nova

cr history 100
cr search 关键词
cr recover-menu
cr resume THREAD_ID
cr resume-all

cr health
cr backup
cr repair-history
```

## 依赖

建议：

- Linux
- Bash
- Python 3
- curl
- `dig`（Ubuntu/Debian: `dnsutils`）
- sqlite3
- OpenAI Codex CLI

Ubuntu / Debian 可安装基础工具：

```bash
sudo apt update
sudo apt install -y curl dnsutils sqlite3 python3
```

## 无彩色模式

如果终端不适合彩色 UI：

```bash
NO_COLOR=1 cr menu
```

## 安全说明

本项目不会主动把 API Key 写进仓库。

请不要提交：

```text
~/.codex/auth.json
~/.codex/sessions/
~/.codex/state_5.sqlite
~/.codex-relay/secrets/
.env
API Key / Token
```

## License

当前仓库尚未指定开源许可证。发布或二次分发前，请根据你的需求添加合适的 LICENSE。
