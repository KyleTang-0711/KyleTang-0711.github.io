#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════
#  KyleTang-0711 个人主页 · 一键部署到 GitHub Pages
#  用法： ./deploy.sh
#  前提：本地已 git config user.name / user.email
# ═══════════════════════════════════════════════════════
set -e

REPO_NAME="KyleTang-0711.github.io"
GH_USER="KyleTang-0711"
GITHUB_URL="https://github.com/${REPO_NAME}.git"

# 颜色
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

step() { echo -e "\n${CYAN}▶ $*${NC}"; }
ok()   { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
err()  { echo -e "${RED}✗ $*${NC}"; }

cd "$(dirname "$0")"

# --- 1. 基础检查 ---
step "环境检查"
if ! command -v git >/dev/null; then err "git 未安装"; exit 1; fi
GIT_NAME=$(git config --global user.name || true)
GIT_EMAIL=$(git config --global user.email || true)
if [ -z "$GIT_NAME" ]; then
  warn "未设置 git user.name，使用默认"
  git config --global user.name "KyleTang-0711"
fi
if [ -z "$GIT_EMAIL" ]; then
  warn "未设置 git user.email，使用默认"
  git config --global user.email "KyleTang-0711@users.noreply.github.com"
fi
ok "git 已就绪 ($(git config --global user.name) <$(git config --global user.email)>)"

# --- 2. 获取 token ---
step "准备 GitHub Token（不会打印）"
if [ -z "$GITHUB_TOKEN" ]; then
  echo "请在浏览器创建一个有 repo 权限的 Fine-grained PAT："
  echo "  → https://github.com/settings/personal-access-tokens/new"
  echo "  → Repository access: Only select repositories → ${REPO_NAME}"
  echo "  → Permissions: Contents: Read and write; Pages: Read and write"
  read -s -p "把 token 粘到这里（输入不可见）：" TOKEN
  echo
  if [ -z "$TOKEN" ]; then err "token 不能为空"; exit 1; fi
  export GITHUB_TOKEN="$TOKEN"
fi

AUTH_URL="https://oauth2:${GITHUB_TOKEN}@github.com/${GH_USER}/${REPO_NAME}.git"

# --- 3. 验证身份 ---
step "验证 GitHub 身份"
ME=$(curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" https://api.github.com/user | grep '"login"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
if [ -z "$ME" ]; then err "Token 无效或网络问题"; exit 1; fi
ok "登录身份：$ME（期待 $GH_USER）"
if [ "$ME" != "$GH_USER" ]; then err "当前 token 不属于 $GH_USER，请确认用了正确账号的 PAT"; exit 1; fi

# --- 4. 创建仓库（如不存在）---
step "检查/创建 ${REPO_NAME} 仓库"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${GITHUB_TOKEN}" "https://api.github.com/repos/${GH_USER}/${REPO_NAME}")
if [ "$HTTP_CODE" = "200" ]; then
  ok "仓库已存在，跳过创建"
elif [ "$HTTP_CODE" = "404" ]; then
  warn "仓库不存在，正在创建…"
  curl -s -X POST -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Content-Type: application/json" \
    "https://api.github.com/user/repos" \
    -d "{\"name\":\"${REPO_NAME}\",\"description\":\"KyleTang-0711 的个人主页\",\"private\":false,\"auto_init\":true}" \
    | grep -q '"name"' && ok "仓库创建成功" || { err "创建失败，请确认 token 有 repo 权限"; exit 1; }
else
  err "访问仓库返回 HTTP $HTTP_CODE"; exit 1
fi

# --- 5. 初始化 git 与首次提交 ---
step "推送文件到 ${REPO_NAME}"
# 清理 .DS_Store / .git 等占位文件
rm -f .DS_Store 2>/dev/null || true

if [ ! -d .git ]; then
  git init -b main >/dev/null
  git add .
  git commit -m "feat: 初始化个人主页" >/dev/null
  ok "首次提交完成"
fi

# 设置 remote（含 token，避免重复输入）
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$AUTH_URL"
else
  git remote add origin "$AUTH_URL"
fi

git push -u origin main --force 2>&1 | tail -3
ok "代码已推送"

# --- 6. 启用 GitHub Pages ---
step "启用 GitHub Pages（main 分支根目录）"
PAGES_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/${GH_USER}/${REPO_NAME}/pages")
if [ "$PAGES_STATUS" = "200" ]; then
  ok "Pages 已启用"
else
  curl -s -X POST -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Content-Type: application/json" \
    "https://api.github.com/repos/${GH_USER}/${REPO_NAME}/pages" \
    -d '{"source":{"branch":"main","path":"/"}}' \
    | head -c 200 | grep -q "html_url" && ok "Pages 启用请求已发送" \
    || warn "Pages 启用可能需要你手动在仓库设置里点一下：Settings → Pages → Source: main / root"
fi

# --- 7. 完成 ---
echo
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  🎉  部署完成！${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo
echo "  访问地址（首次启用需要等 1~2 分钟生效）："
echo -e "  ${CYAN}https://${REPO_NAME}${NC}"
echo
echo "  后续修改内容后只需："
echo "    git add . && git commit -m 'update' && git push"
echo
