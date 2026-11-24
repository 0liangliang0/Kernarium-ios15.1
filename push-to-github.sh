#!/bin/sh
# 一键把本移植版推送到你的 GitHub 仓库并触发 Actions 构建。
# 用法: sh push-to-github.sh https://github.com/你的用户名/你的仓库.git
set -eu

REPO_URL=${1:-}
if [ -z "$REPO_URL" ]; then
	printf '用法: sh push-to-github.sh <github仓库URL>\n' >&2
	printf '例:   sh push-to-github.sh https://github.com/me/kernarium-ios15.git\n' >&2
	exit 1
fi

# 必须在仓库根目录运行（能找到 workflow 即视为根目录）
[ -f .github/workflows/build-ios15.yml ] || {
	printf '错误: 请在 Kernarium-ios15.1 仓库根目录执行本脚本\n' >&2
	exit 1
}

BRANCH=ios15.1-port

printf '目标仓库: %s\n' "$REPO_URL"
printf '推送分支: %s\n' "$BRANCH"
printf '注意: 目标仓库应为空仓库（或允许强制推送的独立分支）。\n'
printf '继续? [y/N] '
read -r answer
case "$answer" in y|Y|yes|YES) ;; *) printf '已取消\n'; exit 0;; esac

if [ ! -d .git ]; then
	git init -q
fi
git checkout -B "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
git add -A
git commit -m "Andarium 1.1 iOS 15.1 software-renderer port" || printf '(无可提交改动)\n'

if git remote get-url origin >/dev/null 2>&1; then
	git remote set-url origin "$REPO_URL"
else
	git remote add origin "$REPO_URL"
fi

printf '\n推送中...\n'
git push -u -f origin "$BRANCH"

printf '\n完成。到 GitHub 仓库的 Actions 页面查看构建进度。\n'
printf '构建产物 IPA 在单次运行的 Artifacts 中下载。\n'
