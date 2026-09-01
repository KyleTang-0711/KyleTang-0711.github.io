/* ═══════════════════════════════════════════════════════
   KyleTang-0711 · 个人主页脚本
   功能：打字机 / 滚动淡入 / 数字动画 / GitHub 实时仓库
   ═══════════════════════════════════════════════════════ */

"use strict";

/* ✏️ ===== 全站配置（想改 GitHub 账号相关，只需要改这里）===== */
const CONFIG = {
  githubUser: "KyleTang-0711",                      // GitHub 用户名（决定实时仓库区拉谁的数据）
  githubCreated: "2023-10-30T05:20:01Z",         // GitHub 账号创建时间（用于 uptime 计时）
  reposToShow: 6,                                // 实时仓库区最多展示几个

  // 打字机轮播文案（中英混排随意增删）
  taglines: [
    "把想法编译成现实 >_<",
    "code → coffee → repeat ☕",
    "stay hungry, stay foolish.",
    "正在 Github 上种树 🌱",
    "解决问题的人。",
  ],
};
/* ✏️ ===== 配置结束 ===== */


/* ---------- 1. 打字机 ---------- */
(function typewriter() {
  const el = document.getElementById("typewriter");
  if (!el) return;

  const lines = CONFIG.taglines;
  let li = 0, ci = 0, deleting = false;

  function tick() {
    const line = lines[li];
    el.textContent = deleting ? line.slice(0, --ci) : line.slice(0, ++ci);

    let delay = deleting ? 34 : 88;

    if (!deleting && ci === line.length) {
      delay = 2200;                    // 打完整句停顿
      deleting = true;
    } else if (deleting && ci === 0) {
      deleting = false;
      li = (li + 1) % lines.length;    // 下一句
      delay = 420;
    }
    setTimeout(tick, delay);
  }
  tick();
})();


/* ---------- 2. 滚动淡入 ---------- */
(function reveal() {
  const els = document.querySelectorAll("[data-reveal]");
  if (!("IntersectionObserver" in window) || !els.length) {
    els.forEach(el => el.classList.add("revealed"));
    return;
  }
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.classList.add("revealed");
        io.unobserve(e.target);
      }
    });
  }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });
  els.forEach(el => io.observe(el));
})();


/* ---------- 3. 数字滚动动画 ---------- */
(function counters() {
  const els = document.querySelectorAll("[data-counter]");
  if (!els.length) return;

  function animate(el) {
    const target = parseInt(el.dataset.counter, 10);
    const suffix = el.dataset.suffix || "";
    const dur = 1400, t0 = performance.now();

    function frame(t) {
      const p = Math.min((t - t0) / dur, 1);
      const eased = 1 - Math.pow(1 - p, 3); // easeOutCubic
      el.textContent = Math.round(target * eased) + suffix;
      if (p < 1) requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }

  if (!("IntersectionObserver" in window)) { els.forEach(animate); return; }
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) { animate(e.target); io.unobserve(e.target); }
    });
  }, { threshold: 0.6 });
  els.forEach(el => io.observe(el));
})();


/* ---------- 4. uptime 计时 ---------- */
(function uptime() {
  const el = document.getElementById("uptimeCounter");
  if (!el) return;

  const start = new Date(CONFIG.githubCreated).getTime();
  if (isNaN(start)) { el.textContent = "很久"; return; }

  function render() {
    const ms = Date.now() - start;
    if (ms < 0) { el.textContent = "刚刚"; return; }
    const days = Math.floor(ms / 86400000);
    const hours = Math.floor(ms % 86400000 / 3600000);
    const mins = Math.floor(ms % 3600000 / 60000);

    el.textContent = days > 0
      ? `${days} 天 ${hours} 小时`
      : hours > 0 ? `${hours} 小时 ${mins} 分钟` : `${mins} 分钟`;
  }
  render();
  setInterval(render, 60000);
})();


/* ---------- 5. GitHub 实时仓库 ---------- */
(function githubRepos() {
  const grid = document.getElementById("reposGrid");
  if (!grid) return;

  // GitHub linguist 常见语言颜色
  const LANG_COLORS = {
    JavaScript: "#f1e05a", TypeScript: "#3178c6", Python: "#3572A5",
    HTML: "#e34c26", CSS: "#563d7c", Java: "#b07219", "C++": "#f34b7d",
    C: "#555555", Go: "#00ADD8", Rust: "#dea584", Ruby: "#701516",
    PHP: "#4F5D95", Shell: "#89e051", Vue: "#41b883", Dart: "#00B4AB",
    Swift: "#F05138", Kotlin: "#A97BFF", "Jupyter Notebook": "#DA5B0B",
  };

  function langColor(lang) {
    return LANG_COLORS[lang] || "#8b949e";
  }

  function timeAgo(iso) {
    const s = (Date.now() - new Date(iso).getTime()) / 1000;
    if (s < 3600) return Math.max(1, Math.floor(s / 60)) + " 分钟前";
    if (s < 86400) return Math.floor(s / 3600) + " 小时前";
    if (s < 2592000) return Math.floor(s / 86400) + " 天前";
    if (s < 31536000) return Math.floor(s / 2592000) + " 个月前";
    return Math.floor(s / 31536000) + " 年前";
  }

  function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, c =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }

  function renderRepos(repos) {
    grid.innerHTML = repos.map(r => `
      <a class="repo-card" href="${escapeHtml(r.html_url)}" target="_blank" rel="noopener">
        <div class="repo-card__name">${escapeHtml(r.name)}</div>
        <div class="repo-card__desc">${r.description ? escapeHtml(r.description) : "<span class='t-dim'>// 暂无描述</span>"}</div>
        <div class="repo-card__meta">
          ${r.language
            ? `<span class="repo-card__lang"><span class="repo-card__lang-dot" style="background:${langColor(r.language)}"></span>${escapeHtml(r.language)}</span>`
            : ""}
          <span class="repo-card__stars">${r.stargazers_count}</span>
          <span class="repo-card__update">${timeAgo(r.updated_at)}</span>
        </div>
      </a>`).join("");
  }

  function renderEmpty() {
    grid.innerHTML = `
      <div class="repos__empty">
        <div class="repos__empty-icon">🚧</div>
        <div class="repos__empty-title">仓库建设中 · 00 repos</div>
        <div class="repos__empty-text">
          这里将自动展示 <code>${escapeHtml(CONFIG.githubUser)}</code> 的最新公开仓库。<br>
          只需推送到 GitHub，本站无需任何改动，列表实时更新 ✨
        </div>
      </div>`;
  }

  fetch(`https://api.github.com/users/${encodeURIComponent(CONFIG.githubUser)}/repos?sort=updated&per_page=${CONFIG.reposToShow}`)
    .then(res => {
      if (!res.ok) throw new Error("HTTP " + res.status);
      return res.json();
    })
    .then(repos => {
      const publicRepos = repos.filter(r => !r.fork);
      // 同步「关于我」区的仓库计数
      const statEl = document.querySelector('[data-counter][data-suffix="+"]');
      if (statEl) statEl.dataset.counter = publicRepos.length;
      publicRepos.length ? renderRepos(publicRepos) : renderEmpty();
    })
    .catch(() => renderEmpty());
})();


/* ---------- 6. 导航交互 ---------- */
(function nav() {
  const toggle = document.getElementById("navToggle");
  const links = document.getElementById("navLinks");

  // 移动端菜单
  if (toggle && links) {
    toggle.addEventListener("click", () => {
      const open = links.classList.toggle("open");
      toggle.setAttribute("aria-expanded", String(open));
      toggle.classList.toggle("active", open);
    });
    links.querySelectorAll("a").forEach(a =>
      a.addEventListener("click", () => links.classList.remove("open")));
  }

  // 回到顶部按钮
  const backTop = document.getElementById("backTop");
  if (backTop) {
    const onScroll = () => {
      backTop.classList.toggle("show", window.scrollY > 480);
      // 章节高亮
      const pos = window.scrollY + 140;
      document.querySelectorAll("main section[id], header[id]").forEach(sec => {
        const link = document.querySelector(`.nav__link[href="#${sec.id}"]`);
        if (!link) return;
        const active = pos >= sec.offsetTop && pos < sec.offsetTop + sec.offsetHeight;
        link.style.color = active ? "var(--blue)" : "";
        link.style.background = active ? "rgba(88,166,255,.09)" : "";
      });
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    backTop.addEventListener("click", () => window.scrollTo({ top: 0, behavior: "smooth" }));
  }
})();


/* ---------- 7. 控制台彩蛋 ---------- */
console.log(
  "%c ⌨ KyleTang-0711 %c 你好，正在看控制台的人 👋 ",
  "background:#58a6ff;color:#08131f;font-weight:bold;padding:4px 8px;border-radius:4px 0 0 4px",
  "background:#161b22;color:#8b949e;padding:4px 8px;border-radius:0 4px 4px 0"
);
console.log(
  "%c$ echo '保持好奇，持续构建。'",
  "color:#3fb950;font-family:monospace"
);
