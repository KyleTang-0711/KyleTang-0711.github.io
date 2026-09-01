#Requires -Version 5.1
# ═══════════════════════════════════════════════════════
#  KyleTang-0711 个人主页 · Windows 一键部署到 GitHub Pages
#  用法： 右键 → 使用 PowerShell 运行 deploy.ps1
#        或在 PowerShell 里输入 .\deploy.ps1
# ═══════════════════════════════════════════════════════
$ErrorActionPreference = "Stop"

$REPO_NAME = "KyleTang-0711.github.io"
$GH_USER = "KyleTang-0711"
$REPO_FULL = "${GH_USER}/${REPO_NAME}"

function Write-Step($msg) { Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "✗ $msg" -ForegroundColor Red }

# --- 1. 基础检查 ---
Write-Step "环境检查"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "git 未安装。请先安装 Git for Windows：https://git-scm.com/download/win"
    exit 1
}

$gitName = git config --global user.name 2>$null
$gitEmail = git config --global user.email 2>$null
if (-not $gitName) {
    Write-Warn "未设置 git user.name，使用默认"
    git config --global user.name "KyleTang-0711"
}
if (-not $gitEmail) {
    Write-Warn "未设置 git user.email，使用默认"
    git config --global user.email "KyleTang-0711@users.noreply.github.com"
}
Write-Ok "git 已就绪 ($(git config --global user.name) <$(git config --global user.email)>)"

# --- 2. 获取 token ---
Write-Step "准备 GitHub Token（不会打印）"
if (-not $env:GITHUB_TOKEN) {
    Write-Host "请在浏览器创建一个有 repo 权限的 Fine-grained PAT：" -ForegroundColor Yellow
    Write-Host "  → https://github.com/settings/personal-access-tokens/new"
    Write-Host "  → Repository access: Only select repositories → $REPO_NAME"
    Write-Host "  → Permissions: Contents: Read and write; Pages: Read and write; Administration: Read and write"
    $secureToken = Read-Host "把 token 粘到这里（输入不可见）" -AsSecureString
    $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    )
    if (-not $token) { Write-Err "token 不能为空"; exit 1 }
    $env:GITHUB_TOKEN = $token
} else {
    $token = $env:GITHUB_TOKEN
}

$headers = @{
    Authorization = "Bearer $token"
    Accept = "application/vnd.github+json"
}

# --- 3. 验证身份 ---
Write-Step "验证 GitHub 身份"
try {
    $user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
    Write-Ok "登录身份：$($user.login)"
    if ($user.login -ne $GH_USER) {
        Write-Err "当前 token 不属于 $GH_USER，请确认用了正确账号的 PAT"
        exit 1
    }
} catch {
    Write-Err "Token 无效或网络问题：$($_.Exception.Message)"
    exit 1
}

# --- 4. 检查/创建仓库 ---
Write-Step "检查/创建 $REPO_NAME 仓库"
try {
    $repo = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO_FULL" -Headers $headers
    Write-Ok "仓库已存在，跳过创建"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Warn "仓库不存在，正在创建…"
        $body = @{
            name = $REPO_NAME
            description = "KyleTang-0711 的个人主页"
            private = $false
            auto_init = $true
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method POST `
            -Headers $headers -Body $body -ContentType "application/json" | Out-Null
        Write-Ok "仓库创建成功"
    } else {
        Write-Err "访问仓库失败：$($_.Exception.Message)"
        exit 1
    }
}

# --- 5. 初始化 git 与推送 ---
Write-Step "推送文件到 $REPO_NAME"
$authUrl = "https://oauth2:${token}@github.com/${GH_USER}/${REPO_NAME}.git"

Remove-Item -Path ".DS_Store" -ErrorAction SilentlyContinue

if (-not (Test-Path ".git")) {
    git init -b main | Out-Null
    git add . | Out-Null
    git commit -m "feat: 初始化个人主页" | Out-Null
    Write-Ok "首次提交完成"
}

# 安全地检查 origin remote 是否存在（抑制 git 的非零退出码错误）
$hasOrigin = $false
$prevErr = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$remoteList = git remote 2>$null
$ErrorActionPreference = $prevErr
if ($remoteList) {
    $hasOrigin = ($remoteList -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq "origin" }) -ne $null
}

if ($hasOrigin) {
    git remote set-url origin $authUrl | Out-Null
} else {
    git remote add origin $authUrl | Out-Null
}

try {
    git push -u origin main --force 2>&1 | Select-Object -Last 3
    Write-Ok "代码已推送"
} catch {
    Write-Err "推送失败：$($_.Exception.Message)"
    exit 1
}

# --- 6. 启用 Pages ---
Write-Step "启用 GitHub Pages（main 分支根目录）"
try {
    $pages = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO_FULL/pages" -Headers $headers
    Write-Ok "Pages 已启用"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        $body = @{ source = @{ branch = "main"; path = "/" } } | ConvertTo-Json -Depth 3
        try {
            Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO_FULL/pages" -Method POST `
                -Headers $headers -Body $body -ContentType "application/json" | Out-Null
            Write-Ok "Pages 启用请求已发送"
        } catch {
            Write-Warn "Pages 启用可能需要你手动在仓库设置里点一下：Settings → Pages → Source: main / root"
        }
    } else {
        Write-Warn "Pages 状态未知：$($_.Exception.Message)"
    }
}

# --- 7. 完成 ---
Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  🎉  部署完成！" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "`n  访问地址（首次启用需要等 1~2 分钟生效）："
Write-Host "  https://$REPO_NAME" -ForegroundColor Cyan
Write-Host "`n  后续修改内容后只需："
Write-Host "    git add . && git commit -m 'update' && git push"
Write-Host ""
