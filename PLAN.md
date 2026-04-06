# Collet OS — Product Plan

## Brand Assets
- Logo: `config/files/usr/share/pixmaps/collet-os-logo.svg` (C lettermark, black/white)
- Wallpaper: `config/files/usr/share/backgrounds/collet/default-dark.png` (dark abstract waves)
- Colors: Collet Design System (OKLCH, warm muted light / pure neutral dark)
- Icons: Phosphor (regular, fill, duotone weights)
- Fonts: Inter (UI), JetBrains Mono (terminal)

---

## 1. The AI Philosophy: Invisible, Not On-The-Nose

### What Microsoft Got Wrong with Copilot

Microsoft's Copilot integration failed because it violated the most basic UX principle: **the user didn't ask for it.**

**Specific mistakes we must not repeat:**

1. **Permanent sidebar eating screen space.** Copilot occupied a fixed panel on the right side of the screen. Users couldn't use that space for anything else. It was removed and replaced with a standalone app after backlash — an admission of failure.

2. **Dedicated keyboard key nobody asked for.** The "Copilot key" on new keyboards (first new key since the Windows key in 1994) became a meme. Users remapped it. The key was later made configurable after complaints.

3. **Taskbar icon that couldn't be removed.** Early versions pinned Copilot to the taskbar with no way to remove it. Users found registry hacks to disable it. Microsoft eventually added a toggle — but the damage was done. The message received: "We don't trust you to choose."

4. **Unsolicited suggestions and notifications.** Copilot offered "helpful" suggestions users didn't ask for. This felt intrusive, not intelligent. Users trained themselves to ignore it, like they ignore cookie banners.

5. **$30/month for enterprise with unclear value.** Organizations couldn't articulate what Copilot actually did for them. ROI was unmeasurable. Many pilots didn't convert to paid.

6. **AI features tied to hardware requirements.** Copilot+ PC features required NPU hardware, fragmenting the Windows experience into "AI haves" and "have-nots."

### Collet OS AI Design Principles

**Principle 1: The AI is not a feature. It's the substrate.**

The user never "opens the AI assistant." There is no AI sidebar. There is no AI icon in the taskbar. There is no dedicated AI app with a chat window.

Instead, the AI is present in the way the OS responds to the user:
- Right-click a file → "Summarize this document" appears naturally among other actions
- Search bar finds things intelligently, not just by filename
- Settings panel understands natural language in the search field
- Error dialogs offer "Help me fix this" that actually works
- The terminal has an inline helper that responds to `?` prefix

The AI is the quality of the experience, not a product placed inside the experience.

**Principle 2: Invoked, never imposed.**

The AI does nothing unprompted. No suggestions. No notifications. No "Did you know?" tooltips. No proactive offers.

The user reaches for help when they need it, and the help is excellent. The rest of the time, the AI is invisible. Like electricity — you don't think about it until you flip a switch, and then it works perfectly.

**Principle 3: Contextual, not conversational.**

The primary interaction is NOT a chat window. It's contextual actions embedded where the user already is:
- In the file manager: right-click actions (organize, summarize, convert)
- In settings: natural language search ("how do I connect bluetooth?")
- In the terminal: `? how do I find large files` → shows the command with explanation
- In notification center: "3 updates available" with a "tell me more" expansion
- Keyboard shortcut (Super+Space or similar): quick command palette with AI understanding

Chat is available as a fallback (like Spotlight/Alfred power-user mode), but it's not the primary surface.

**Principle 4: Competent, not chatty.**

The AI doesn't greet you. It doesn't say "Great question!" It doesn't introduce itself. It doesn't explain what it can do. It just does things well when asked.

Responses are short. Actions are clear. Confirmations are one line. The AI has the personality of a capable colleague who respects your time — not a customer service bot.

**Principle 5: Transparent about its limits.**

When the AI doesn't know something: "I'm not sure about that." Not a hallucinated answer. Not a confident wrong answer. Just honesty.

When an action requires cloud: "This needs an internet connection to process. Send?" — never silently.

When something is risky: shows exactly what will happen, waits for confirmation, no ambiguity.

---

## 2. AI Integration Surfaces (Specific)

### 2.1 Terminal Helper (Priority 1 — build first)

The most natural entry point. Users who open the terminal are already in "command mode."

```
$ ? how do I see disk usage
  → du -sh ~/* | sort -rh | head -20
  Shows the 20 largest items in your home directory, sorted by size.
  [Run] [Copy] [Explain more]

$ ? install spotify
  → flatpak install flathub com.spotify.Client
  Installs Spotify from Flathub (sandboxed).
  [Run] [Copy]
```

Implementation: shell function that pipes to Ollama API, formats response inline. ~200 lines of bash/python.

### 2.2 File Manager Context Menu (Priority 2)

Right-click integration in Nautilus (GNOME Files):
- "Summarize" (for documents/PDFs)
- "Organize this folder" (our file organization pattern)
- "What is this file?" (for unknown file types)

Implementation: Nautilus extension (Python), calls Ollama API. ~300 lines.

### 2.3 Settings Search Enhancement (Priority 3)

GNOME Settings search already works with keywords. Enhance it to understand natural language:
- Typing "make text bigger" → navigates to Accessibility > Font Size
- Typing "connect printer" → navigates to Printers
- Typing "dark mode" → navigates to Appearance

Implementation: GNOME search provider that routes through local LLM. ~400 lines.

### 2.4 Quick Command Palette (Priority 4)

`Super+Space` opens a minimal overlay (like Spotlight/Raycast):
- Type anything — it figures out if you mean an app, a file, a setting, or a question
- Apps: launches immediately
- Files: opens file manager at location
- Settings: opens the right settings panel
- Questions: brief answer inline, option to open terminal for execution

Implementation: Custom GTK4 overlay app. ~1-2k lines.

### 2.5 Notification Intelligence (Priority 5 — future)

Not proactive suggestions. Instead:
- Groups noisy notifications intelligently
- Summarizes multiple notifications from the same app
- "5 updates available — all security patches, none will restart your computer"

### 2.6 Voice (Priority 6 — future)

Push-to-talk via keyboard shortcut (not wake word — no always-listening).
- Hold Super key + speak → command processed
- Local Whisper → local LLM → local Piper TTS if audio response needed

---

## 3. Visual Identity — Making It Feel Personal

### 3.1 Current State (what just shipped)

- Collet OS branding in os-release ✓
- Dark mode default ✓
- Wallpaper asset ready (dark abstract waves) — needs push
- Logo SVG ready — needs push
- Collet Design System colors in GTK4 CSS ✓
- Phosphor icon theme scaffold ✓ (needs SVGs populated)
- Inter + JetBrains Mono fonts ✓

### 3.2 Next Visual Steps

| Task | What | Effort |
|---|---|---|
| Ship wallpaper + logo | Push assets already in repo | 1 commit |
| Plymouth boot splash | Collet logo animation on boot (SVG → Plymouth theme) | 2-3 hours |
| GDM login theme | Collet wallpaper + logo on login screen | 1-2 hours |
| Populate Phosphor icons | Map priority icons (50-80 most common) from PHOSPHOR_MAPPING.md | 4-6 hours |
| GNOME Shell mini-theme | Top bar transparency, rounded corners, accent color on active | 2-3 hours |
| App grid curation | Organize default app grid layout, hide unnecessary entries | 1 hour |
| Cursor theme | Subtle, clean cursor (or adopt an existing one like Bibata) | 30 min |

### 3.3 The "Personal" Feeling

What makes an OS feel personal (not just themed):

1. **First-boot experience knows your language.** Detect locale, greet in that language, set everything up without asking 15 questions.

2. **The desktop is clean.** No icons on the desktop. No "Getting Started" widget. No shortcuts the user didn't create. Just the wallpaper and the panel.

3. **Apps the user expects are already there.** Firefox, LibreOffice, a calculator, a calendar. No bloatware. No trial software. No "Discover our partners."

4. **The system is quiet.** No notifications on first boot. No "tips and tricks." No "rate your experience." The OS earns attention through quality, not demands it.

5. **Everything responds to the user's preference.** Dark mode is the default, but if they switch to light, everything — terminal, apps, file manager, login screen — all switch together. No app-by-app configuration.

---

## 4. Development Roadmap

### Phase 1: Foundation Polish (Current → 2 weeks)

What we have: a working, bootable Collet OS with branding and AI runtime.

| Task | Priority | Effort |
|---|---|---|
| Push wallpaper + logo to repo | P0 | 1 hour |
| Set up Hetzner dev server | P0 | 2 hours |
| Terminal `?` helper (bash + Ollama) | P1 | 1-2 days |
| Plymouth boot splash with Collet logo | P1 | 3 hours |
| GDM login screen branding | P1 | 2 hours |
| Populate top-50 Phosphor icon mappings | P2 | 1 day |
| Test AI first-boot model pull (Ollama) | P1 | 2 hours |
| Light mode wallpaper variant | P2 | Commission/create |

### Phase 2: AI Surfaces (2-4 weeks)

| Task | Priority | Effort |
|---|---|---|
| File manager right-click actions (Nautilus extension) | P1 | 2-3 days |
| Settings natural language search provider | P2 | 2-3 days |
| Quick command palette (Super+Space) | P2 | 3-5 days |
| AI interaction mode toggle (guided/assisted/direct) | P2 | 1-2 days |
| Audit logging for all AI actions | P1 | 1 day |
| Backend switching (local ↔ cloud) tested end-to-end | P1 | 1-2 days |

### Phase 3: Onboarding & Migration (4-6 weeks)

| Task | Priority | Effort |
|---|---|---|
| First-boot flow (custom welcome, language, AI intro) | P1 | 1 week |
| Windows migration tool (files, bookmarks, WiFi) | P2 | 1 week |
| Calamares installer branding + custom modules | P2 | 3-5 days |
| "Getting started" contextual hints (not intrusive — triggered only when user appears stuck) | P3 | 3-5 days |

### Phase 4: Enterprise & Scale (6-12 weeks)

| Task | Priority | Effort |
|---|---|---|
| Fleet management (central config push to many machines) | P1 | 2-3 weeks |
| RBAC for AI capabilities (admin vs user permissions) | P1 | 1-2 weeks |
| CRA compliance documentation + SBOM | P1 | 1-2 weeks |
| On-premises AI server mode (Ollama on LAN) | P2 | 1 week |
| Accessibility audit (EAA compliance) | P1 | 2 weeks |
| Automated testing pipeline (boot, login, basic operations) | P2 | 1 week |

### Adjacent / Future Work

| Area | What | When |
|---|---|---|
| COSMIC migration | Move from GNOME to COSMIC when 1.0 ships | When COSMIC is ready |
| Collet OS website | Product page, download, docs | Phase 2-3 |
| Hardware partnerships | Tuxedo, Framework pre-install conversations | Phase 3-4 |
| EU funding applications | Sovereign Tech Fund, Digital Europe Programme | Phase 2 |
| ISO installer | Standalone bootable ISO (not just rebase) | Phase 3 |
| Localization | Full UI strings for DE, FR, SE, IT, ES, NL, PL | Phase 3 |
| Flatpak curation | Curated "Collet Picks" app category | Phase 2 |

---

## 5. Anti-Patterns (What We Never Do)

Drawn from Copilot, Cortana, Clippy, and every failed OS assistant:

1. **Never show AI capabilities unsolicited.** No "I can help with that!" popups.
2. **Never add an AI icon to the taskbar/panel.** The AI has no persistent visual presence.
3. **Never require AI for basic operations.** Everything works without AI. AI makes it better, not possible.
4. **Never make AI opt-out.** There is no AI to opt out of. It's integrated into existing surfaces. If you don't use the `?` prefix, the terminal is just a terminal.
5. **Never brand the AI.** It doesn't have a name. It's not "Collet Assistant" or "ColletAI." It's just how the OS works.
6. **Never add AI settings in a prominent place.** AI configuration lives in advanced settings, not front page.
7. **Never interrupt workflow.** No mid-task suggestions. No "while you're here..." prompts.
8. **Never animate the AI.** No pulsing orbs, no typing indicators, no loading animations beyond standard system spinners. The AI's response appears like any other system response.
9. **Never compare to competitors.** No "unlike other AI assistants..." messaging. The product speaks for itself.
10. **Never collect data to "improve the experience."** If telemetry exists, it's opt-in, anonymous, and genuinely optional with zero degradation.
