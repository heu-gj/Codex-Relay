#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/heu-gj/Codex-Relay/main"
GLOBAL_RELAY="/usr/local/bin/codex-relay"

# 管理员模式：全局安装/更新主程序，然后退出。
if [[ "${1:-}" == "--global" ]]; then
  [[ "$(id -u)" -eq 0 ]] || {
    echo "ERROR: --global 需要 root 权限。请使用 sudo bash -s -- --global" >&2
    exit 1
  }
  command -v curl >/dev/null 2>&1 || { echo "ERROR: 缺少 curl" >&2; exit 1; }
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  echo "==> 下载最新 codex-relay"
  curl -fsSL "$REPO_RAW/codex-relay" -o "$tmp"
  echo "==> Bash 语法检查"
  bash -n "$tmp"
  echo "==> 安装到 $GLOBAL_RELAY"
  install -o root -g root -m 0755 "$tmp" "$GLOBAL_RELAY"
  echo "==> 全局安装/更新完成: $GLOBAL_RELAY"
  echo "所有用户共用这一份主程序；各自的 ~/.codex 仍然独立。"
  exit 0
fi

# 用户初始化模式；兼容旧用法: install.sh baibai
if [[ "${1:-}" == "--user" ]]; then
  shift
fi

DEFAULT_PROFILE="${1:-nova}"
case "$DEFAULT_PROFILE" in
  nova|baibai) ;;
  *) echo "用法: bash $0 [nova|baibai]" >&2; exit 2 ;;
esac

HOME_DIR="$HOME"
RELAY="$GLOBAL_RELAY"
BASHRC="$HOME_DIR/.bashrc"
CODEX_DIR="${CODEX_HOME:-$HOME_DIR/.codex}"
MARK_BEGIN='# >>> codex-relay managed >>>'
MARK_END='# <<< codex-relay managed <<<'

say() { printf '\n==> %s\n' "$*"; }
warn() { printf '\nWARNING: %s\n' "$*" >&2; }
need() { command -v "$1" >/dev/null 2>&1; }

say "用户: $(id -un)"
say "HOME: $HOME_DIR"

mkdir -p "$CODEX_DIR"

[[ -x "$RELAY" ]] || {
  echo "ERROR: 没有找到全局主程序: $RELAY" >&2
  echo "请先让管理员执行：" >&2
  echo "  curl -fsSL $REPO_RAW/install.sh | sudo bash -s -- --global" >&2
  exit 1
}

# 旧版曾安装到 ~/bin；备份它，避免 PATH 抢在 /usr/local/bin 前面。
LEGACY_RELAY="$HOME_DIR/bin/codex-relay"
if [[ -e "$LEGACY_RELAY" || -L "$LEGACY_RELAY" ]]; then
  LEGACY_BACKUP="$LEGACY_RELAY.user-backup.$(date +%Y%m%d-%H%M%S)"
  mv "$LEGACY_RELAY" "$LEGACY_BACKUP"
  say "旧的用户级版本已备份: $LEGACY_BACKUP"
fi

say "使用全局主程序: $RELAY"

need python3 || { echo "ERROR: 缺少 python3" >&2; exit 1; }

python3 - "$BASHRC" "$MARK_BEGIN" "$MARK_END" <<'PYBLOCK123'
from pathlib import Path
import sys

path=Path(sys.argv[1])
begin=sys.argv[2]
end=sys.argv[3]
text=path.read_text(errors='replace') if path.exists() else ''
lines=text.splitlines()
out=[]
in_block=False
for line in lines:
    if line.strip()==begin:
        in_block=True
        continue
    if in_block and line.strip()==end:
        in_block=False
        continue
    if not in_block:
        out.append(line)

block=[
    begin,
    "alias cr='/usr/local/bin/codex-relay'",
    "alias cx='/usr/local/bin/codex-relay run'",
    end,
]
if out and out[-1].strip():
    out.append('')
out.extend(block)
path.write_text('\n'.join(out)+'\n')
PYBLOCK123

say "已配置 ~/.bashrc：cr、cx（显式使用 /usr/local/bin/codex-relay）"

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY || true

missing=()
for x in python3 curl; do
  need "$x" || missing+=("$x")
done
if ((${#missing[@]})); then
  echo "缺少必要命令: ${missing[*]}" >&2
  exit 1
fi

if ! need codex; then
  warn "当前用户找不到 codex 命令。codex-relay 已安装，但需要先让该用户能够运行 Codex CLI。"
fi
if ! need dig; then
  warn "找不到 dig。直连自动修复需要 dig；基础切换功能仍可使用。"
fi
if ! need sqlite3; then
  warn "找不到 sqlite3。history/health 功能会受限；中转切换仍可使用。"
fi

say "设置默认 profile: $DEFAULT_PROFILE"
"$RELAY" use "$DEFAULT_PROFILE"

for p in nova baibai; do
  say "检测 $p 无 VPN 直连"
  if "$RELAY" check "$p"; then
    echo "[$p] 直连正常"
  else
    warn "[$p] 普通直连检测失败。"
    if need dig; then
      echo "尝试自动直连修复；若需要修改 /etc/hosts，可能会提示 sudo 密码。"
      if "$RELAY" direct "$p"; then
        echo "[$p] 直连修复完成"
      else
        warn "[$p] 自动直连没有成功。可稍后运行: cr direct $p"
      fi
    fi
  fi
done

"$RELAY" use "$DEFAULT_PROFILE"

say "安装完成"
cat <<EOF

当前默认: $DEFAULT_PROFILE
配置文件: $CODEX_DIR/config.toml
聊天目录: $CODEX_DIR/sessions

重新打开终端后：
  cr use nova
  cx

或者：
  cr use baibai
  cx

菜单：
  cr menu

聊天：
  cr history 100
  cr recover-menu
  cr health

注意：
  1. cx 启动时会清除 HTTP/HTTPS/ALL proxy，不依赖 127.0.0.1:7897。
  2. 认证不会从其他用户复制；每个用户使用自己的 auth/API Key。
  3. 聊天记录保存在该用户自己的 ~/.codex 下。
EOF