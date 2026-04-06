# Phosphor Icons → Freedesktop Icon Name Mapping

This file documents which Phosphor icons map to which freedesktop standard icon names.
Use this as a reference when populating the icon theme directories.

## Source
- Phosphor Icons: https://phosphoricons.com
- License: MIT
- Weights used: Regular (default), Fill (active/panel), Duotone (app icons)

## How to populate

1. Download Phosphor SVGs from https://github.com/phosphor-icons/core
2. Copy SVGs into the appropriate `scalable/` directories
3. Rename to freedesktop standard names (see mapping below)
4. For fixed sizes (16x16, 22x22, etc.), render SVGs at those sizes or let GTK scale from scalable

## Priority Mappings (ship these first)

### Actions (scalable/actions/)
| Freedesktop Name | Phosphor Icon | Weight |
|---|---|---|
| document-open | file-plus | regular |
| document-save | floppy-disk | regular |
| document-new | file | regular |
| document-print | printer | regular |
| edit-copy | copy | regular |
| edit-cut | scissors | regular |
| edit-paste | clipboard-text | regular |
| edit-undo | arrow-counter-clockwise | regular |
| edit-redo | arrow-clockwise | regular |
| edit-delete | trash | regular |
| edit-find | magnifying-glass | regular |
| list-add | plus | regular |
| list-remove | minus | regular |
| go-home | house | regular |
| go-next | caret-right | regular |
| go-previous | caret-left | regular |
| go-up | caret-up | regular |
| go-down | caret-down | regular |
| view-refresh | arrows-clockwise | regular |
| process-stop | x | regular |
| system-run | play | regular |
| system-shutdown | power | regular |
| system-reboot | arrow-counter-clockwise | regular |
| system-log-out | sign-out | regular |
| system-lock-screen | lock | regular |
| window-close | x | regular |
| window-maximize | corners-out | regular |
| window-minimize | minus | regular |

### Status (scalable/status/)
| Freedesktop Name | Phosphor Icon | Weight |
|---|---|---|
| network-wireless | wifi-high | fill |
| network-wired | plugs-connected | fill |
| network-offline | wifi-slash | fill |
| battery-full | battery-full | fill |
| battery-low | battery-low | fill |
| battery-charging | battery-charging | fill |
| audio-volume-high | speaker-high | fill |
| audio-volume-medium | speaker-low | fill |
| audio-volume-muted | speaker-slash | fill |
| dialog-information | info | fill |
| dialog-warning | warning | fill |
| dialog-error | warning-circle | fill |
| dialog-question | question | fill |

### Places (scalable/places/)
| Freedesktop Name | Phosphor Icon | Weight |
|---|---|---|
| folder | folder | duotone |
| folder-open | folder-open | duotone |
| folder-documents | folder | duotone |
| folder-download | download-simple | duotone |
| folder-music | music-notes | duotone |
| folder-pictures | image | duotone |
| folder-videos | video-camera | duotone |
| user-home | house | duotone |
| user-trash | trash | duotone |
| network-server | hard-drives | duotone |
| network-workgroup | users | duotone |

### Devices (scalable/devices/)
| Freedesktop Name | Phosphor Icon | Weight |
|---|---|---|
| computer | desktop | regular |
| drive-harddisk | hard-drive | regular |
| drive-removable-media | usb | regular |
| media-optical | disc | regular |
| printer | printer | regular |
| phone | device-mobile | regular |
| camera-photo | camera | regular |
| input-keyboard | keyboard | regular |
| input-mouse | mouse | regular |
| audio-headphones | headphones | regular |

### Apps (scalable/apps/)
| Freedesktop Name | Phosphor Icon | Weight |
|---|---|---|
| utilities-terminal | terminal | duotone |
| system-file-manager | folder-open | duotone |
| preferences-system | gear | duotone |
| help-browser | question | duotone |
| collet-ai-assistant | robot | duotone |

## Unmapped Icons

Any icon not in this mapping falls through to Adwaita (the Inherits in index.theme).
No gaps, no missing icons — just Collet style where we define it, Adwaita everywhere else.
