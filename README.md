# Collet OS

EU-sovereign, AI-integrated Linux desktop built on Fedora Atomic.

## What is this

Collet OS is a custom Linux distribution built with [BlueBuild](https://blue-build.org) on top of [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/). It ships with a local AI assistant powered by [Ollama](https://ollama.com), automatic updates with rollback, and privacy-by-architecture design.

## Architecture

- **Base**: Fedora Atomic (immutable, rpm-ostree)
- **Desktop**: GNOME (Wayland)
- **Apps**: Flatpak (sandboxed)
- **AI**: Ollama (local, backend-agnostic — supports Claude, Mistral, or on-prem)
- **Icons**: Phosphor Icons (MIT) mapped to freedesktop standards
- **Colors**: Collet Design System (OKLCH)
- **Updates**: Atomic with automatic rollback via Greenboot

## Quick start

### Build the image

```bash
# Fork this repo, then push to GitHub.
# GitHub Actions builds and signs the image automatically.
```

### Install on a Fedora Atomic system

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/YOUR_ORG/collet-os:latest
systemctl reboot
```

### Test in a VM (macOS with UTM)

1. Download [UTM](https://mac.getutm.app) (free)
2. Download [Fedora Silverblue ISO](https://fedoraproject.org/atomic-desktops/silverblue/)
3. Create a VM: 4+ CPU cores, 8+ GB RAM, 64 GB disk
4. Install Fedora Silverblue
5. Rebase to Collet OS:
   ```bash
   rpm-ostree rebase ostree-image-signed:docker://ghcr.io/YOUR_ORG/collet-os:latest
   systemctl reboot
   ```

## Repository structure

```
collet-os/
├── recipes/
│   └── collet-os.yml              # BlueBuild recipe (the distro definition)
├── config/
│   ├── dconf/db/local.d/          # GNOME settings overrides
│   │   ├── 01-collet-appearance   # Theme, fonts, colors
│   │   ├── 02-collet-privacy      # Privacy defaults
│   │   └── 03-collet-power        # Power management
│   ├── files/usr/share/
│   │   ├── collet-os/
│   │   │   ├── ai/                # AI configuration
│   │   │   │   ├── backend.toml   # Backend selection (local/cloud/on-prem)
│   │   │   │   ├── system-prompt.md
│   │   │   │   ├── safety-rules.toml
│   │   │   │   └── patterns/      # AI task patterns
│   │   │   ├── gtk-4.0/collet.css # GTK4 color overrides
│   │   │   ├── first-boot.sh
│   │   │   └── greenboot/         # Health checks for auto-rollback
│   │   ├── icons/Collet/          # Phosphor-based icon theme
│   │   ├── backgrounds/collet/    # Wallpapers (add your own)
│   │   └── applications/          # Desktop entries
│   └── scripts/                   # Build-time scripts
│       ├── 01-branding.sh
│       ├── 02-ai-layer.sh
│       └── 03-gnome-defaults.sh
├── .github/workflows/
│   └── build.yml                  # CI pipeline (BlueBuild)
└── README.md
```

## AI backends

The AI layer is backend-agnostic. Configure in `backend.toml`:

| Backend | Where it runs | For whom |
|---------|--------------|----------|
| Ollama (local) | On the machine | Default — 16GB+ RAM |
| Ollama (LAN server) | Organization's AI server | Thin clients, shared hardware |
| Claude API | Anthropic cloud | Opt-in, premium features |
| Mistral API | EU cloud (Paris) | Opt-in, sovereignty-aligned |

All backends share the same skills, safety rules, patterns, and audit logging.

## License

TBD — the OS image inherits Fedora's licensing. Custom configuration and scripts in this repo will be open source.
