# windows-scripts

A collection of PowerShell scripts to fully set up a fresh Windows LTSC (or any clean Windows) install for **gaming, content creation, and development** — no Microsoft Store required.

---

## What it does

| Step | Script | Run as | Description |
|------|--------|--------|-------------|
| 0 | `Install-Winget.ps1` | Admin | Installs winget from GitHub (no Store needed) |
| 1 | `Install-Runtimes.ps1` | Admin | VCRedist, .NET, DirectX, WebView2, XNA, .NET 3.5 |
| 2 | `Set-Tweaks.ps1` | Admin | Classic context menu, Explorer defaults, power plan |
| 3 | `Install-Dev.ps1` | **User** | PS7 (interactive), Terminal, eza, Starship, PS profile |

---

## Quick start

> **On LTSC** PowerShell 7 is not pre-installed — open **Windows PowerShell** (the built-in one) as Administrator.

**Step 1 – Admin setup** (runtimes + tweaks). Open **Windows PowerShell as Administrator**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
irm https://raw.githubusercontent.com/habibimedwassim/windows-scripts/main/setup.ps1 | iex
```

The setup script asks upfront whether to enable the Microsoft Store (`wsreset -i`, no ISO needed — required for Xbox Game Bar). It then handles winget install if missing, all runtimes, and system tweaks.

**Step 2 – Shell setup** (run as your normal user, not elevated):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\Install-Dev.ps1
```

This launches the PS7 MSI interactively (so you can uncheck telemetry and the Windows Update auto-update option), then silently installs Windows Terminal, eza, and Starship, and deploys your PowerShell profile.

---

## Scripts

### `setup.ps1`

The admin entry point. Runs cleanly from a remote `irm … | iex` one-liner or from a local clone. Flow:

1. Prompts to enable the Microsoft Store via `wsreset -i` (no ISO, pulls from Windows Component Store)
2. Installs winget if missing
3. Presents a menu:

```
0  Full setup  (both steps below)
1  Runtimes    – VCRedist, .NET, DirectX, WebView2, XNA, .NET Framework 3.5
2  Tweaks      – Classic context menu, Explorer defaults, power plan, accessibility
```

At the end it prints instructions to run `Install-Dev.ps1` as a normal user.

---

### `scripts/Install-Winget.ps1`

Installs [winget](https://github.com/microsoft/winget-cli) on machines that don't have it (LTSC, Server, Sandbox). Downloads:

- `Microsoft.VCLibs.x64.14.00.Desktop.appx` (via `aka.ms` redirect)
- `Microsoft.UI.Xaml 2.8` (from NuGet, no Store required)
- Latest `Microsoft.DesktopAppInstaller` msixbundle from the GitHub release

---

### `scripts/Install-Runtimes.ps1`

Installs all common runtimes that games and apps depend on:

- Visual C++ Redistributables (2005, 2008, 2010, 2012, 2013, 2015+) — x86 & x64
- .NET Desktop Runtime (3.1, 5, 6, 7, 8, 9, 10)
- .NET Framework 3.5 (via DISM)
- Windows App Runtime 1.8
- Microsoft Edge WebView2 Runtime
- DirectX End-User Runtime
- OpenAL (`OpenAL.OpenAL`)
- Xbox Game Bar (`9NZKPSTSNW4P`) *(requires msstore source — may not be available on LTSC)*
- XNA Framework 4.0 (`Microsoft.XNARedist` via winget)

---

### `scripts/Install-Dev.ps1`

> **Run as your normal user — not as Administrator.**  
> winget installs user-scoped by default when not elevated, which is correct for these tools. The script will refuse to run if it detects an elevated session.

Installs the base shell environment:

- **PowerShell 7** — launched via `winget install -i` (interactive MSI) so you can uncheck telemetry and the "update via Windows Update" option
- **Windows Terminal**
- **eza** (modern `ls`)
- **Starship** prompt
- Deploys `profile/Microsoft.PowerShell_profile.ps1` to both the PS7 and WinPS5 profile paths

---

### `scripts/Set-Tweaks.ps1`

Registry and system tweaks (requires Admin):

- **Classic context menu** — restores the Windows 10-style right-click menu
- Show file extensions in Explorer
- Show hidden files and folders
- Disable Sticky / Filter / Toggle key prompts
- Disable mouse enhance pointer precision (acceleration)
- Disable Game DVR / background recording (eats CPU/GPU even when idle)
- Enable Hardware-Accelerated GPU Scheduling (HAGS) — GTX 1000+ / RX 5000+, takes effect after reboot
- Set power plan to High Performance

---

### `profile/Microsoft.PowerShell_profile.ps1`

Configures `eza`-based `ls` aliases and initialises the Starship prompt.  
Installed automatically by `Install-Dev.ps1`, or copy it manually to:

```
%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

---

## Notes

- `setup.ps1` and all `Install-Runtimes` / `Set-Tweaks` / `Install-Winget` scripts require **Administrator** privileges.
- `Install-Dev.ps1` must be run as a **normal user** (it will refuse to run elevated).
- Scripts are designed to be idempotent — safe to re-run; winget will skip already-installed packages.
- `irm … | iex` downloads each sub-script from GitHub at runtime so no local clone is needed on a bare machine.
- This repo intentionally does **not** install opinionated apps (editors, browsers, games, etc.). It is a base layer — install whatever you want on top.

---

## License

MIT
