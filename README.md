<div align="center">

<img src="docs/images/rhino-9-on-linux.png" alt="Rhino 9 running on Linux: shaded Perspective viewport rendered with DXVK, wireframe Top, Front and Right views" width="900">

# Rhino on Linux

**Run [Rhinoceros 3D](https://www.rhino3d.com) — the best Windows CAD modeler — natively on Linux, with Wine, DXVK and a bit of engineering.**

[![Flatpak build](https://github.com/keshavsapra/rhino-linux/actions/workflows/flatpak.yml/badge.svg)](https://github.com/keshavsapra/rhino-linux/actions/workflows/flatpak.yml)
[![Setup tests](https://github.com/keshavsapra/rhino-linux/actions/workflows/test-setup.yml/badge.svg)](https://github.com/keshavsapra/rhino-linux/actions/workflows/test-setup.yml)
[![Wine build](https://github.com/keshavsapra/rhino-linux/actions/workflows/build-wine.yml/badge.svg)](https://github.com/keshavsapra/rhino-linux/actions/workflows/build-wine.yml)
![License](https://img.shields.io/badge/license-LGPL_2.1%2B_%2F_MIT-orange)
![Platform](https://img.shields.io/badge/platform-Linux-fcc624)
![Rhino](https://img.shields.io/badge/Rhino-7_%7C_8_%7C_9-2f8f3d)

*33 Wine/X11 patches · hardware-accelerated D3D11 · Cloud Zoo & offline licences · a friendly no-terminal GUI*

</div>

---

## Table of contents

- [Quickstart](#quickstart)
- [🖥️ The GUI app (prefer not to use the terminal?)](#the-gui-app-prefer-not-to-use-the-terminal)
- [🔒 Offline mode: no McNeel servers](#offline-mode-no-mcneel-servers)
- [Rhino 7, 8 and 9 side by side](#rhino-7-8-and-9-side-by-side)
- [As a Flatpak](#as-a-flatpak) · [Without Flatpak](#without-flatpak)
- [Installing plug-ins](#installing-plug-ins)
- [GPU rendering on NVIDIA](#gpu-rendering-on-nvidia) · [Several graphics cards](#computers-with-several-graphics-cards)
- [Desktop environments](#desktop-environments--window-managers)
- [What the patches do](#what-the-patches-do) · [Building Wine manually](#building-wine-manually)
- [Dependencies](#dependencies) · [FAQ](#faq) · [Credits & licence](#credits--acknowledgements)

## Quickstart

```bash
git clone https://github.com/keshavsapra/rhino-linux.git
cd rhino-linux
./install.sh
```

That's it. `./install.sh` downloads the pre-built **patched Wine runtime** (~54 MB) from the releases, installs Rhino from McNeel's own installer, and puts `rhino-linux` in your applications menu. **No compiling, no terminal fiddling afterwards.**

Then get the Rhino installer:

1. download `rhino_….exe` from [McNeel](https://www.rhino3d.com/download/) (needs your Rhino account, or use the licence you already have)
2. run `./install.sh --installer /path/to/rhino_installer.exe`, or just drag the file onto the GUI app

```bash
rhino-linux            # open the newest installed Rhino
rhino-linux model.3dm  # open a model
```

> The runtime works on **any 64-bit Intel/AMD** processor, on distributions from 2023 or later
> (glibc 2.38+): Ubuntu 24.04, Fedora 39+, Debian 13, current Arch. Check with `ldd --version`.

---

## The GUI app (prefer not to use the terminal?)

A small desktop app installs Rhino for you and looks after it afterwards.

<table>
<tr>
<td align="center"><img src="docs/images/app-welcome.png" width="180"><br>Welcome</td>
<td align="center"><img src="docs/images/app-check.png" width="180"><br>System check</td>
<td align="center"><img src="docs/images/app-installer.png" width="180"><br>Installer</td>
<td align="center"><img src="docs/images/app-home.png" width="180"><br>Home</td>
</tr>
</table>

Once Rhino is installed, the app is where you go to:

- **open** Rhino, or one of several versions installed side by side
- **install** another version (Rhino 7, 8 or 9)
- **choose** the graphics card Rhino uses (multi-GPU machines)
- **install plug-ins** — drop a `.rhi`/`.yak`/`.gha`/`.zip` file on its window
- **🔒 toggle offline mode** — cut Rhino off from McNeel's servers with one switch
- **check for updates**, **repair** without losing files or sign-in, **close** a stuck Rhino, **uninstall** everything

Turn on *Expert mode* in the menu for the Wine side of things: `winecfg`, the registry editor, DXVK settings and the prefix folders.

Run it from the repo with `python3 tools/rhino-on-linux.py`; after the first installation it also shows up in your applications menu. Needs GTK 4 and libadwaita 1.5+ (Ubuntu 24.04, Fedora 40, current Arch all have it).

---

## Offline mode: no McNeel servers

Rhino normally phones home on its own: licence check-ins, the update check, usage statistics, crash uploads, the news panel. This repo can **cut all of it off**, while Rhino keeps working to the full:

| | |
|---|---|
| 🧱 **Isolated sandbox** | Rhino, Wine and everything they start run in a network namespace whose only interface is your own machine. No DNS, no route, no socket out — to McNeel *or anywhere else*. |
| 🖥️ **No embedded browser** | Rhino's embedded Edge (WebView2) is swapped for a stub: no browser process, no Chromium background traffic, no OAuth pages. |
| 📣 **No update checks, no statistics** | The launcher sets the registry value McNeel documents for this (`McNeelUpdate Enabled = False`). |
| 🔁 **Loopback still works** | Rhino's local licence broker on `127.0.0.1` keeps working, because the loopback interface is kept. |
| 🛡️ **Fail-safe by default** | If isolation cannot be set up, Rhino refuses to start online rather than silently connecting. |

The GUI puts this behind one switch (**Home → Without the internet → Run Rhino offline**); the CLI matches:

```bash
rhino-linux --online       # one launch with network: validate a licence key, install a plug-in
rhino-linux --offline      # this launch, fully isolated
rhino-linux --set-offline 1  # offline becomes the default for every launch (menu icons too)
sudo tools/block-mcneel-hosts.sh add   # optional: also block McNeel system-wide (/etc/hosts)
```

**Good to know about licences:**

| Licence | Fully offline? | Needs the network |
|---|---|---|
| Single-computer **licence key** | ✅ forever | once, when the key is first validated |
| **Cloud Zoo** (Rhino account) | ~2 weeks between check-ins | to sign in, then periodically |

After the one-time validation, the machine never has to talk to McNeel again.

> **Details, tool by tool:** what stops working (only the package manager, web panels and news feed), how to verify with `getent hosts api.mcneel.com`, and the hosts blocklist are in **[docs/offline.md](docs/offline.md)**.

---

## Rhino 7, 8 and 9 side by side

Install as many versions as you like — run `./install.sh --installer` once per installer. The version is read from the installer's name (`rhino_en-us_8.36….exe` is Rhino 8), or pass `--version 7`, `8` or `9`.

Each version gets its **own Windows environment** (`~/.wine-rhino7`, `~/.wine-rhino8`, `~/.wine-rhino9`), sharing one Wine runtime, so they never interfere and each can be repaired or removed on its own.

```bash
rhino-linux              # the newest installed Rhino
rhino-linux --version 8  # Rhino 8; rhino-8 does the same (rhino-7 and rhino-9 too)
rhino-linux --stop       # close every Rhino that is running
```

Before 1.2 the command was `rhino-9`, whatever the version. It still works: it opens Rhino 9, or the newest Rhino when Rhino 9 is not installed.

> Rhino 7 runs on Microsoft's .NET Framework 4.8 instead of the .NET that Rhino 8 and 9 ship with. The installer sets it up first with [winetricks](https://github.com/Winetricks/winetricks), which makes Rhino 7's first installation take 30 to 60 minutes. That part comes from [Rhino7-Linux](https://github.com/JonasPedrotti/Rhino7-Linux).

## As a Flatpak

The Flatpak works the same on every distribution and brings everything the app needs with it. You only need Flatpak and the Flathub remote, which most desktop distributions set up already.

Download [RhinoOnLinux.flatpak](https://github.com/keshavsapra/rhino-linux/releases/latest/download/RhinoOnLinux.flatpak) and double-click it. Your software center (GNOME Software, Discover) installs it, along with the GNOME runtime it needs from Flathub.

If double-clicking opens nothing, your software center may not handle downloaded Flatpak files. Installing from a terminal always works:

```bash
flatpak install --user ~/Downloads/RhinoOnLinux.flatpak
```

The download doesn't update itself. When a new version comes out, download it again and install it over the old one; Rhino and your settings stay.

To build it yourself from this repository instead:

```bash
flatpak install --user flathub org.flatpak.Builder
flatpak run org.flatpak.Builder --user --install --install-deps-from=flathub \
    --force-clean build-flatpak flatpak/io.github.jabern.RhinoOnLinux.yml
```

Either way, open **Rhino on Linux** from your applications menu. Rhino gets its own entry there too, and double-clicking a `.3dm` file opens it in Rhino.

The Flatpak keeps Rhino and its Wine setup in `~/.var/app/io.github.jabern.RhinoOnLinux/`, separate from a regular install. **Uninstall** in the app removes Rhino; `flatpak uninstall --delete-data io.github.jabern.RhinoOnLinux` removes the app and everything with it. It can see your home folder, so you can open and save models wherever you keep them.

## Without Flatpak

Run the app straight from the downloaded folder with `python3 tools/rhino-on-linux.py`. After the first installation it also shows up in your applications menu. It runs the same scripts as the command line, so both ways give you the same result.

This needs Python with GTK 4 and libadwaita 1.5 or newer (Ubuntu 24.04, Fedora 40 and current Arch have it):

| Distribution | Packages |
|---|---|
| **Arch / Manjaro** | `sudo pacman -S --needed python-gobject gtk4 libadwaita` |
| **Ubuntu / Debian** | `sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-adw-1` |
| **Fedora** | `sudo dnf install python3-gobject gtk4 libadwaita` |

## Installing plug-ins

Rhino's own Package Manager (`_PackageManager` inside Rhino) lists many plug-ins. For the ones you download yourself, use **Install a plug-in…** in the app, drop the file on its window, or double-click the file in your file manager. The app knows these files:

| File | What happens |
|---|---|
| `.rhi` | McNeel's Rhino Installer Engine installs it, the same tool Windows uses |
| `.yak` | Rhino's package manager installs it from the file |
| `.gha`, `.ghuser` | copied into Grasshopper's Libraries or UserObjects folder |
| `.exe`, `.msi` | the plug-in's own installer runs, inside Rhino's Wine prefix |
| `.zip` | unpacked first, then installed as above |

Close Rhino before installing. If it is still open, the app offers to close it for you. From the terminal, the same thing is `tools/install-plugin.sh bella_rhino-26.4.0-win32.zip`.

Here is the [Bella](https://bellarender.com) renderer, installed from its download `.zip` and rendering its sample scene:

<div align="center"> <img src="docs/images/bella-in-rhino.jpg" alt="Bella for Rhino rendering a glass jug of orange juice, a glass and two oranges on a checked tablecloth, next to the Rhino viewports" width="700"> </div>

> Some plug-ins won't work under Wine: anything that installs a Windows driver, such as a USB license dongle. Bella renders on the CPU, so it isn't affected.

## GPU rendering on NVIDIA

Rhino Render and the Raytraced display mode (Cycles) render on NVIDIA GPUs with CUDA or OptiX. When the setup finds the NVIDIA driver, it adds `nvcuda` and `nvoptix` from [nvidia-libs](https://github.com/SveSop/nvidia-libs), which pass Rhino's calls to the Linux driver. In Rhino, pick the GPU under **Options > Cycles**, or with `RhinoCycles_SelectDevice`.

- Needs the proprietary NVIDIA driver; the Flatpak gets CUDA and OptiX from its NVIDIA driver extension.
- The first Raytraced start on OptiX shows "Uploading" for about half a minute while the driver compiles the kernels; later starts are quick.
- To skip this step, run the setup with `RHINO_NO_CUDA=1`.

### Computers with several graphics cards

With more than one graphics card, for example two NVIDIA cards or a laptop with built-in graphics, Rhino can hang at its start screen. Choose the card your monitor is connected to in the app's **Graphics card** section, or give part of its name when starting Rhino:

```bash
RHINO_GPU=4080 rhino-linux
flatpak run --env=RHINO_GPU=4080 --command=rhino-linux io.github.jabern.RhinoOnLinux
```

## Desktop environments & window managers

| | Recommended |
|---|---|
| 🖥️ **KDE Plasma · GNOME** | Multi-window CAD, floating palettes, middle-click pop-ups and multi-monitor setups work out of the box, with zero configuration. |
| 🪟 **Tiling WMs (Niri, Hyprland, Sway)** | Supported with custom window rules — see [docs/tiling-window-managers.md](docs/tiling-window-managers.md). |

## What the patches do

Stock Wine experiences crashes, blank web panels, and visual glitches when running Rhino. We maintain **33 targeted patches** to resolve these issues across all major subsystems:

| Area | Fixes |
|---|---|
| ⚙️ **Compute & stability** | 64-bit dynamic OpenMP loop scheduling, NT thread-pool worker caps, CPU affinity APIs |
| 🔑 **Cloud Zoo & licensing** | DirectComposition WebView2 swapchain hosting, ECDSA P-256 JWT auth, Session 0 RPC services |
| 🪟 **UI chrome & pop-ups** | 32bpp depth matching, alpha-blended menus, layered child panels, Task Dialogs, `RhinoGreet` startup |
| 🎨 **Viewport & graphics** | X11 client-surface repaints, DXGI format fallback, swapchain-recreation redraws |
| 🖥️ **Multi-monitor & Wayland** | MDI-child offset fixes, XRandR anchoring, Wayland pop-ups & overlays |

The full technical breakdown of all 33 patches is in **[docs/patches.md](docs/patches.md)**.

## Building Wine manually

If you prefer building Wine yourself instead of running `./install.sh`:

```bash
# 1. Clone Wine
git clone https://gitlab.winehq.org/wine/wine.git ~/src/wine
cd ~/src/wine
git checkout wine-11.20

# 2. Apply patches
for p in /path/to/rhino-linux/patches/{0[1-9],1[0-5],1[7-9],[2-9][0-9]}-*.patch; do
    patch -p1 < "$p"
done

# 3. Build Wine 64-bit
mkdir ~/src/build-wine && cd ~/src/build-wine
../wine/configure --enable-win64 --prefix=/opt/wine-rhino --without-capi
make -j$(nproc)
sudo make install

# 4. Configure prefix
cd /path/to/rhino-linux
./tools/deploy-rhino.sh --prefix ~/.wine-rhino --wine /opt/wine-rhino/bin/wine
```

## Dependencies

### Runtime Dependencies

Make sure you have Vulkan drivers and DXVK installed:

| Distribution | Command |
|---|---|
| **Arch / Manjaro** | `sudo pacman -S --needed wine vulkan-icd-loader vulkan-headers dxvk-bin libx11 freetype2 gnutls` |
| **Ubuntu / Debian** | `sudo apt update && sudo apt install -y wine64 libvulkan1 vulkan-tools libx11-6 libfreetype6 libgnutls30 dxvk` |
| **Fedora** | `sudo dnf install -y wine vulkan-loader libX11 freetype gnutls dxvk` |
| **openSUSE** | `sudo zypper install -y wine vulkan libX11 freetype2 libgnutls dxvk` |

### Build Dependencies (Optional)

Only required if you choose to compile Wine from source with `--build-wine` (requires `bison`, `flex`, `gcc`, `mingw-w64`, X11 dev headers).

## FAQ

**Does this work with my licence?** — A single-computer licence key validates once and then never needs the internet; a Cloud Zoo licence signs in with your Rhino account. Fully offline use is possible with either; see [offline mode](#offline-mode-no-mcneel-servers).

**Is this pirated software?** — No. You need a genuine Rhino licence and installers from McNeel. This project only makes *legitimately licensed* software run on Linux.

**Where is everything stored?** — Each Rhino version lives in its own Wine prefix (`~/.wine-rhino<version>`, or `~/.var/app/io.github.jabern.RhinoOnLinux/` in the Flatpak). Uninstalling removes exactly those files.

**Does Rhino 7 work too?** — Yes, but its first install takes 30–60 minutes because of .NET Framework 4.8.

**Rhino is stuck / hangs at the start screen** — try `rhino-linux --fresh` (restarts the wineserver for clean HTTP state, used for Cloud Zoo licensing), or pick the other graphics card in the app; see [several graphics cards](#computers-with-several-graphics-cards).

## Credits & Acknowledgements

- Thanks to [ItHasLegs](https://github.com/ItHasLegs/rhino8-wine) for researching the early `uxtheme` dark-mode crash (now upstream in Wine 11.14) and for the `--fresh` wineserver restart concept to clear stale HTTP state for Cloud Zoo OAuth licensing.
- Thanks to [eqeka](https://github.com/eqeka) for testing, and for tracking down the straight Grasshopper wires (fixed in Patch 21) and the Grasshopper menu focus issue on Niri.

## License

- Patches in `patches/` follow Wine's **LGPL 2.1+** license.
- Scripts and configs are **MIT**.
- *Rhino on Linux is not affiliated with Robert McNeel & Associates. Rhino is a trademark of Robert McNeel & Associates.*
