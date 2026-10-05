// ZFX Emperor — Web UI 状态条
// DSH web client 插件：在界面右下角显示插件状态徽章。
// 通过 package.json 的 dsh.client.platform = "web" 注册。

export const name = "zfx-emperor-client";

export function mount(root, { status } = {}) {
  // 创建徽章容器
  const badge = document.createElement("div");
  badge.id = "zfx-emperor-badge";
  badge.style.cssText = [
    "position:fixed",
    "bottom:12px",
    "right:12px",
    "z-index:9999",
    "display:flex",
    "align-items:center",
    "gap:6px",
    "padding:4px 10px",
    "border-radius:4px",
    "background:#101010",
    "color:#f59e0b",
    "font-size:12px",
    "font-family:monospace",
    "box-shadow:0 2px 8px rgba(0,0,0,0.3)",
    "cursor:default",
    "user-select:none",
  ].join(";");

  // 棱形图标（SVG 内联）
  const icon = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  icon.setAttribute("width", "14");
  icon.setAttribute("height", "14");
  icon.setAttribute("viewBox", "0 0 200 200");
  icon.innerHTML =
    '<rect x="60" y="60" width="80" height="80" transform="rotate(45 100 100)" fill="none" stroke="#f59e0b" stroke-width="20"/>';
  badge.appendChild(icon);

  // 状态文字
  const label = document.createElement("span");
  label.textContent = "正方形在线";
  badge.appendChild(label);

  // 续命计数（如果有）
  if (status?.scorer) {
    const stats = document.createElement("span");
    stats.style.color = "#888";
    stats.textContent = `avg ${status.scorer.avg ?? "?"}`;
    badge.appendChild(stats);
  }

  root.appendChild(badge);

  return {
    update(newStatus) {
      if (newStatus?.scorer) {
        const stats = badge.querySelector("span:last-child");
        if (stats) stats.textContent = `avg ${newStatus.scorer.avg ?? "?"}`;
      }
    },
    unmount() {
      badge.remove();
    },
  };
}
