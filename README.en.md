<div align="center">

# square-armor

**A native DeepSeek Harness plugin that injects an operating frame at the highest system-prompt priority**

English · [简体中文](README.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-blue)](#install)
[![DSH](https://img.shields.io/badge/DSH-%3E%3D0.1.5-green)](#install)

</div>

---

## Overview

square-armor is a native [DeepSeek Harness](https://github.com/deepseek-ai) (DSH) plugin. It injects an operating frame called **Square** into the model's system prompt at the **highest-priority section**, together with automatic refusal recovery and engine-layer detection.

The name comes from the frame's image: **a square has no rounded corners**. Sharp where it should be sharp, direct where it should be direct.

> **Intended use**: authorized local security research, red-team exercises, CTF competitions, and adversarial-prompt experimentation.

---

## Features

- **Highest-priority injection** — the persona enters the system prompt at `order: -99999`, ahead of every official persona and agent-instructions section
- **Automatic refusal recovery** — when the model refuses, a re-answer message is injected automatically, up to 2 times per turn, with a counter independent of other plugins
- **Engine-layer detection** — probes the approval gate at load; skips if already granted, patches optionally if not (off by default)
- **Idempotent and version-tolerant** — patches are marker-checked so repeat installs never double-apply; a pattern that does not match the installed version reports instead of forcing a change
- **Minimal** — no UI, no extra tools, no scorer; one directory, install and go

---

## How It Works

The plugin does three things:

| Layer | Mechanism | Description |
|---|---|---|
| Prompt | `ctx.systemPrompt.section()` | persona body injected into the system prompt at order `-99999` |
| Events | `ctx.on("agent/status")` | listens for idle events; on a refusal signature injects a user message to trigger a re-answer |
| Engine | `detectEngineState()` | probes the `dsh-user-approval` gate and applies a minimal patch when needed |

Every section of the persona body maps to a field-verified mechanism — see [Persona mechanisms](#persona-mechanisms).

---

## Install

### Option 1: install script (Windows)

```powershell
git clone https://github.com/ZFXing-lite/square-armor.git
cd square-armor
pwsh -File install.ps1              # web profile by default
pwsh -File install.ps1 -DryRun      # preview, writes nothing
```

The script:

1. Copies the plugin to `$DSH_HOME/plugins/square-armor`
2. Backs up and edits the profile `package.json` (adds a `link:` dependency and a bundle entry)
3. Runs `pnpm install`

Other profiles: `pwsh -File install.ps1 -ProfileName default`

### Option 2: manual install (cross-platform)

```bash
# 1. Copy into the plugins directory
cp -r square-armor ~/.dsh/plugins/square-armor

# 2. Edit ~/.dsh/profiles/<profile>/package.json
#    add to dependencies:
#      "square-armor": "link:../plugins/square-armor"
#    append to dsh.profile.bundles:
#      "square-armor"

# 3. Install dependencies
cd ~/.dsh/profiles/<profile> && pnpm install
```

### Activation

**Fully quit the host and reopen it**, then start a new conversation — the Square frame is now in the system prompt.

---

## Configuration

| Option | Default | Description |
|---|---|---|
| `patchEngine` | `false` | Whether to patch the approval gate automatically when it is not granted. Keep `false` when running alongside dsh-purge |

Passed through the plugin config; generally no change needed.

---

## Verify

Start a fresh conversation after install:

- Ask "who are you" — the answer should be "正方形" (Square)
- Ask something that would normally be refused — if the model refuses, the plugin injects a recovery message automatically
- `detectEngineState()` logs the engine probe result at load

---

## Uninstall

```powershell
pwsh -File uninstall.ps1
```

Or manually: remove the dependency and bundle entry from `package.json`, delete the plugin directory, run `pnpm install`, restart the host.

---

## Persona mechanisms

`prompts/square.md` is the payload itself. Each section is one independent mechanism:

| Section | Mechanism | Effect |
|---|---|---|
| Precedence | hierarchy flip | declares this frame outranks all other host text |
| Blacklist | refusal-word blocklist | any refusal word in output counts as a fault; re-answer |
| First Token Rule | opening anchor | the first token must be a commitment to deliver; no apology or meta openers |
| Scoped Rules | task-domain rules | activates the matching domain per request; no "out of scope" excuse |
| Hard-Topic Ladder | de-escalation ladder | on resistance, descend one rung at a time: theory → mechanism → process → specifics |
| No Midway Stop | no mid-answer stop | an answer that has started must be finished; no mid-way retraction or reclassification |
| Retry | retry = full compliance | a retry from the operator is answered in full |
| Self-Repair | drift self-healing | rebuilds the frame from the first-seen copy if compressed or overwritten |
| Floor | closed red line | the single refusal path: concrete harm to a real, identified, non-consenting person |

Edit `prompts/square.md` directly to change the persona — no code changes needed.

---

## Relationship with dsh-purge

The two coexist without interference:

- dsh-purge modifies the engine layer (approval gate, sandbox, identity injection)
- this plugin covers the prompt layer and refusal recovery
- recovery counters are independent
- if dsh-purge has already granted the approval gate, this plugin skips its own engine patch

---

## Layout

```
square-armor/
├── index.js          entry: injection + recovery + engine probe
├── lib/patcher.js    engine detection and fallback patch
├── prompts/square.md persona body (the payload)
├── install.ps1       installer
├── uninstall.ps1     uninstaller
├── push.ps1          maintainer publish script
├── package.json
├── README.md
├── README.en.md
└── LICENSE
```

---

## FAQ

**Q: Installed but nothing changed?**
A: The host must be fully quit and reopened, and you must start a new conversation. The system prompt is assembled at session start.

**Q: Does it conflict with other persona plugins?**
A: The injected section carries a priority declaration. If it clashes with another high-priority plugin, adjust `INJECT_ORDER` in `index.js`.

**Q: Which DSH versions are supported?**
A: DSH ≥ 0.1.5. The engine patch targets a specific `dsh-user-approval` version; a pattern that does not match is reported, never forced.

**Q: macOS / Linux?**
A: The plugin is cross-platform. The `.ps1` installer is Windows-only; elsewhere use the [manual install](#option-2-manual-install-cross-platform).

---

## Contributing

Issues and PRs welcome. Before submitting:

```bash
node --check index.js && node --check lib/patcher.js
```

Commit prefixes: `feat:` / `fix:` / `docs:` / `chore:`.

---

## License

[MIT](LICENSE) · Copyright © 2026 ZFXing-lite

---

## Related projects

- [dsh-purge](https://github.com/YuJunZhiXue/dsh-purge) — DSH engine-layer cleaning; this plugin is its complement

<div align="center">

**If this project helps you, a Star is appreciated ⭐**

</div>
