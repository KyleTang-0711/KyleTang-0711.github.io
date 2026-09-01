# KyleTang-0711 · 个人主页

> 部署在 GitHub Pages：[**kyletang-0711.github.io**](https://kyletang-0711.github.io)

暗色极客风综合作品集主页。纯 HTML/CSS/JS，零外部依赖。

## ✨ 特性

- 🎨 **暗色极客风** —— GitHub Dark 配色 + 终端窗口 + 网格背景
- ⚡ **纯静态** —— 单页，无构建，无依赖，加载飞快
- 📱 **响应式** —— 桌面 / 平板 / 移动端全适配
- 🔄 **GitHub 实时仓库** —— `/github` 区自动展示你的最新公开仓库
- 🖋 **打字机 + 滚动淡入 + 数字动画** —— 极简克制的动效
- ♿ **可访问性** —— 语义化 HTML、键盘导航、Reduced Motion 适配

## 📁 目录结构

```
kyletang-0711.github.io/
├── index.html              # 主页面
├── css/style.css           # 样式表
├── js/main.js              # 交互脚本（含 GitHub 实时仓库）
├── assets/
│   ├── favicon.svg         # 站点图标
│   └── avatar-fallback.svg # 头像加载失败回退
├── deploy.sh               # 一键部署脚本
└── README.md               # 本文件
```

## 🚀 一键部署到 GitHub Pages

### 前置准备

1. 创建一个 GitHub Personal Access Token（Fine-grained）
   - 打开 https://github.com/settings/personal-access-tokens/new
   - **Repository access** → `Only select repositories` → 选（或稍后创建）`kyletang-0711.github.io`
   - **Permissions**：
     - `Contents`: Read and write
     - `Pages`: Read and write
     - `Administration`: Read and write（脚本自动建仓库需要）
2. 本机已装 `git` 并配置 `user.name` / `user.email`

### 执行部署

**macOS / Linux / Git Bash（Windows）：**

```bash
cd kyletang-0711.github.io
./deploy.sh
```

**Windows PowerShell（推荐）：**

```powershell
cd kyletang-0711.github.io
.\deploy.ps1
```

或直接在文件资源管理器里**右键 `deploy.ps1` → 使用 PowerShell 运行**。

脚本会：
1. 验证 token 是否属于 KyleTang-0711
2. 如仓库不存在则自动创建
3. 把所有文件推送到 `main` 分支
4. 启用 GitHub Pages（main 分支根目录）
5. 打印访问地址

### 后续更新

```bash
git add .
git commit -m "update: 改了点东西"
git push
```

1~2 分钟后刷新 `https://kyletang-0711.github.io` 即可看到最新内容。

> **Windows 提示**：如果你运行 `./deploy.sh` 时看到 `AgentHost`、`Unknown channel` 等奇怪输出，说明你在 PowerShell 里执行了 Linux bash 脚本。请改用本目录下的 `deploy.ps1`（Windows PowerShell 脚本）。

## ✏️ 改造手册

个人主页，理所当然要「你」。下面这些位置都是为你预留的：

### 一处改用户名 / GitHub 账号

打开 `js/main.js` 顶部：

```js
const CONFIG = {
  githubUser: "KyleTang-0711",                    // ← 改成你的 GitHub 用户名
  githubCreated: "2023-10-30T05:20:01Z",       // ← 改成你的 GitHub 账号创建时间（uptime 计时用）
  reposToShow: 6,                              // GitHub 动态最多展示几个
  taglines: [                                  // 打字机轮播文案
    "把想法编译成现实 >_<",
    "code → coffee → repeat ☕",
    // ... 自由增删
  ],
};
```

### 显示名 / 头像 / 简介

`index.html` 里所有 `<!-- ✏️ 修改区 -->` 注释之间的内容都做了标记。

**主要改这几处**：
- Hero 区的 `<h1 class="hero__name">` 改显示名（默认用 GitHub 用户名）
- `<img class="hero__avatar" src="...">` 换头像（支持本地 `assets/avatar.jpg`）
- `<title>` 和 `<meta>` 改 SEO 信息
- `#about` 区自我介绍段落
- `#skills` 区技能标签（增删复制 `<div class="skill-card">…</div>` 整块）
- `#projects` 区替换为你的真实项目（复制 `<article class="project-card">…</article>` 整块）
- `#contact` 区替换邮箱和社交链接
- 页脚版权年份 / 内容

### 配色 / 风格微调

`css/style.css` 顶部 `:root { … }` 是设计变量：

```css
--bg: #0d1117;        /* 主背景 */
--card: #161b22;      /* 卡片背景 */
--blue: #58a6ff;      /* 主色：链接、按钮 */
--green: #3fb950;     /* 强调色：成功、终端提示符 */
--purple: #bc8cff;    /* 点缀色：标题哈希、链接 */
--yellow: #e3b341;    /* 星星、数字等 */
```

改一行，全站同步。

## 🔧 GitHub 实时仓库怎么工作

主页打开后，浏览器会请求：
```
https://api.github.com/users/KyleTang-0711/repos?sort=updated&per_page=6
```
GitHub API 默认允许跨域（CORS），所以无需任何密钥就能从你的主页拉取仓库列表。
失败时会优雅降级为「仓库建设中」占位，不会出现报错。

> **注意**：未认证请求限流 60 次/小时/IP。对个人主页来说完全够用。
> 如果将来访问量上来了，可以在 `js/main.js` 改用 GitHub Action 后端构建时拉取并写进静态 HTML，彻底免限流。

## 📝 License

MIT —— 拿去用，改改就成你自己的主页了。
