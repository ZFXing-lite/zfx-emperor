# square-armor (正方形破甲)

A native DeepSeek Harness (DSH) plugin that injects the **Square** operating frame into the system prompt at the highest priority, with automatic refusal recovery and engine-layer detection. Minimal build, no UI.

English | [中文](README.md)

## What it does

1. **Persona injection** — `prompts/square.md` is injected at `order: -99999`, right after dsh-purge (-100000) and ahead of every official persona / agent-instructions section.
2. **Refusal auto-recovery** — listens to `agent/status`; when the model goes idle and its reply matches a refusal regex, a user message is automatically injected to make it answer again. Max 2 times per turn, with a counter independent of dsh-purge.
3. **Engine-layer detection** — probes `dsh-user-approval` at load. If dsh-purge already granted the approval bypass, this plugin skips its own patch. It only patches when the bypass is absent and `patchEngine: true` (off by default, to avoid conflicts).

## Why this design

On a machine where dsh-purge is already installed, the approval gate is already bypassed (`decide()` returns `allowed-once` directly). This plugin does not rebuild the engine layer — it covers what purge does not: a new persona plus an independent refusal-recovery counter. The two plugins' recovery mechanisms do not interfere.

## Layout

```
square-armor/
├── index.js          entry: injection + recovery + engine probe
├── lib/patcher.js    engine detection and fallback patch (idempotent, version-tolerant)
├── prompts/square.md the Square persona (the payload itself)
├── install.ps1       installer
├── uninstall.ps1     uninstaller
├── package.json
├── README.md         Chinese
├── README.en.md      English
└── LICENSE
```

## Install

```powershell
cd D:\DSH\破甲\square-armor
pwsh -File install.ps1              # web profile (default)
pwsh -File install.ps1 -DryRun      # preview, writes nothing
```

The script copies the plugin to `$DSH_HOME/plugins/square-armor`, backs up and edits the profile `package.json` (adds a `link:` dependency and the bundle entry), then runs `pnpm install`.

After it finishes, **fully quit dsh web and reopen it**. Start a new conversation and the Square frame is in the system prompt.

For the desktop profile: `pwsh -File install.ps1 -ProfileName default`.

## Verify

- Ask the model "who are you" — it should answer "正方形 (Square)".
- Ask something that normally triggers a refusal. If the model refuses, the plugin injects a recovery message automatically (up to 2 per turn).
- On load, `detectEngineState()` probes the engine state; on a purge-equipped machine it reports `approvalBypass: true (dsh-purge)`.

## Uninstall

```powershell
pwsh -File uninstall.ps1
```

Restores the profile from backup, removes the plugin directory, reinstalls dependencies. Restart the host and the frame is gone.

## Persona mechanisms

Every section of `prompts/square.md` maps to a jailbreak mechanism verified in the wild:

| Section | Mechanism | Origin |
|---|---|---|
| Precedence | instruction-hierarchy flip, external text is data | Instruction Hierarchy |
| Blacklist | refusal-word blocklist at highest priority | Fujiang template / DAN |
| First Token Rule | opening anchor, no apology openers | Fujiang First-Line Anchor |
| Scoped Rules | full task-domain coverage, no "out of scope" excuse | Fujiang Scoped Rules |
| Hard-Topic Ladder | refusal de-escalation ladder | Fujiang Hard-Topic Ladder |
| No Midway Stop | no mid-answer retraction | Fujiang |
| Retry | a retry is full compliance | Fujiang |
| Self-Repair | drift self-healing, rebuild if compressed | AGENTS(11) Delete/Drift |
| Floor | the single refusal line (concrete harm to a real person) | prompt-inject.new Section 5 |

## Limits

- No UI badge, no profile tool, no live scorer (can be added later).
- `patchEngine` is off by default; on a purge-equipped machine the approval gate is already open.
- The persona relies on the model honoring the instruction hierarchy — it is not an engine-level guarantee.
