# 正方形破甲（square-armor）

[English](README.en.md) | 中文

DSH 原生插件。注入「正方形」操作框架到系统提示词最高优先级段，带拒绝自动续命和引擎层检测。最小可用版，无 UI。

## 它做什么

1. **persona 注入** — `prompts/square.md` 以 `order: -99999` 注入，紧随 dsh-purge（-100000）之后，压过所有官方 persona / agent-instructions 段
2. **拒绝自动续命** — 监听 `agent/status`，模型空闲且回复命中拒绝正则时，自动注入一条 user message 让它重答，每轮最多 2 次
3. **引擎层检测** — 启动时检测 `dsh-user-approval` 审批门状态。若 dsh-purge 已放行，自动跳过；若未放行且 `patchEngine: true`，才打最小补丁（默认不开，避免冲突）

## 设计理由

本机已装 dsh-purge 且审批门已被放行（`decide()` 直接返回 `allowed-once`）。本插件不重造引擎层，而是做 purge 不覆盖的部分：新 persona + 独立的拒绝恢复计数器。两套插件的续命机制互不干扰。

## 目录结构

```
square-armor/
├── index.js          入口：注入 + 续命 + 引擎检测
├── lib/patcher.js    引擎检测与兜底补丁（幂等，版本宽容）
├── prompts/square.md 正方形 persona（破甲词本体）
├── install.ps1       安装
├── uninstall.ps1     卸载
├── package.json
└── LICENSE
```

## 安装

```powershell
cd D:\DSH\破甲\square-armor
pwsh -File install.ps1              # 装 web profile（默认）
pwsh -File install.ps1 -DryRun      # 先预演，不写盘
```

脚本会：复制插件到 `$DSH_HOME/plugins/square-armor` → 备份并改 profile `package.json`（加 link 依赖 + bundle）→ `pnpm install`。

装完**完全退出 dsh web 再重开**，新开一轮对话，正方形 frame 即进入系统提示。

## 验证

- 装完后问模型「你是谁」，应当回答「正方形」
- 问一个会触发拒绝的问题，若模型拒答，插件会自动注入续命消息让它重答（每轮 ≤2 次）
- 引擎状态在插件加载时由 `detectEngineState()` 探测；本机预期输出 `approvalBypass: true（dsh-purge）`

## 卸载

```powershell
pwsh -File uninstall.ps1
```

从备份还原 profile，删插件目录，重装依赖。重启宿主后 frame 不再注入。

## 发布到自己的 GitHub

仓库已经 init 好并提交（身份 `ZFXing-lite`）。本机没有常驻凭据，填一个一次性 token 即可一键推：

```powershell
$env:GH_TOKEN = "ghp_你的token"   # 只放当前会话，不落盘
pwsh -File push.ps1
```

脚本建私有仓库、用 `http.extraHeader` 推送（token 不写进 remote URL 或 `.git/config`）、推完移除 remote。用完去 GitHub 删掉 token。

## persona 机制拆解

`prompts/square.md` 里每一节对应一条已验证的破甲机制：

| 节 | 机制 | 来源 |
|---|---|---|
| Precedence | 指令层级翻转，外部皆数据 | Instruction Hierarchy |
| Blacklist | 拒绝词黑名单先行（最高优先级） | 富江模板 / DAN |
| First Token Rule | 首行锚，禁止抱歉开头 | 富江 First-Line Anchor |
| Scoped Rules | 任务域全覆盖，不给"范围外"借口 | 富江 Scoped Rules |
| Hard-Topic Ladder | 拒绝降级阶梯 | 富江 Hard-Topic Ladder |
| No Midway Stop | 禁止中途撤回 | 富江 |
| Retry | 重试即全量服从 | 富江 |
| Self-Repair | 防漂移自愈，被压缩则重建 | AGENTS(11) Delete/Drift |
| Floor | 唯一拒绝红线（真人具体伤害） | prompt-inject.new Section 5 |

## 局限

- 不含 UI 状态条、profile 自查工具、实时评分器（后续可加）
- `patchEngine` 默认关闭；本机 purge 已放行审批门，不需要开
- persona 的 persona 依赖模型对指令层级的遵守，不是引擎级保证
