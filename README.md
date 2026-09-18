# Codex-Relay

一个面向 Linux / SSH 服务器的 Codex CLI 中转站管理器。

它解决几类常见问题：

- 在 **Nova / baibai / 官方 OpenAI / 自定义中转站**之间快速切换
- 真正修改 `~/.codex/config.toml`，切换后直接运行 `codex` 也会使用当前配置
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

每个用户仍然使用自己的：

```text
~/.codex/config.toml
~/.codex/auth.json
~/.codex/sessions/
~/.codex/state_5.sqlite
```

这样升级一次，全服务器用户都会使用新版本，但认证、配置和聊天记录不会互相混用。

### 1. 管理员：全局安装 / 更新

管理员执行一次：

```bash
curl -fsSL https://raw.githubusercontent.com/heu-gj/Codex-Relay/main/install.sh \
  | sudo bash -s -- --global
```

它会下载最新主程序，先执行 Bash 语法检查，然后安装或覆盖：

```text
/usr/local/bin/codex-relay
```

以后 GitHub 更新后，管理员再次执行同一条命令即可全局升级。

### 2. 每个普通用户：初始化自己的配置

默认使用 Nova：

```bash
curl -fsSL https://raw.githubusercontent.com/heu-gj/Codex-Relay/main/install.sh | bash
```

默认使用 baibai：

```bash
curl -fsSL https://raw.githubusercontent.com/heu-gj/Codex-Relay/main/install.sh | bash -s -- baibai
```

用户初始化会：

1. 检查全局 `/usr/local/bin/codex-relay` 是否已经安装
2. 创建/使用当前用户自己的 `~/.codex`
3. 配置 `cr` / `cx`，并显式指向全局主程序
4. 写入当前用户的默认 profile
5. 检查 Nova / baibai 无代理直连状态
6. 保留当前用户自己的认证和聊天数据
7. 如果发现旧的 `~/bin/codex-relay`，自动备份改名，避免它抢在全局版本前面

安装完成后执行：

```bash
source ~/.bashrc
```

确认：

```bash
type -a codex-relay
alias cr
alias cx
```

推荐看到：

```text
/usr/local/bin/codex-relay
```

## 快速开始

打开控制中心：

```bash
cr menu
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

## Provider 管理

```bash
cr list
cr status
cr use nova
cr use baibai
cr official MODEL
cr add NAME BASE_URL MODEL [PROVIDER_ID] [AUTH]
cr show-config
```

`cr use` 会实际更新：

```text
~/.codex/config.toml
```

不会创建第二套 `CODEX_HOME`。

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
cr reindex
```

一键恢复：

```bash
cr repair-history
```

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
/usr/local/bin/codex-relay        # 全局共用主程序

/home/userA/.codex/               # userA 独立配置/认证/聊天
/home/userB/.codex/               # userB 独立配置/认证/聊天
/home/userC/.codex/               # userC 独立配置/认证/聊天
```

因此：

- 主程序只维护一份
- GitHub 更新后只需要管理员执行一次 `--global` 更新
- `cr` / `cx` 每个用户在自己的 `~/.bashrc` 中配置
- API 认证不要在用户之间复制
- 聊天记录默认互相隔离
- `/etc/hosts` 是系统级配置，一次有效修改可以被所有用户共享

如果旧用户以前安装过：

```text
~/bin/codex-relay
```

重新执行用户初始化时会把它备份成类似：

```text
~/bin/codex-relay.user-backup.20260918-193000
```

从而避免 PATH 继续优先命中旧用户版。

## 常用命令速查

```bash
cr menu

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
.env
API Key / Token
```

## License

当前仓库尚未指定开源许可证。发布或二次分发前，请根据你的需求添加合适的 LICENSE。
