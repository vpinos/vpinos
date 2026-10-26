<p align="center">
 <img width="1448" height="1086" alt="vpinos_transparent" src="https://github.com/user-attachments/assets/1643c2d9-0068-491a-a7ec-98cfe80d4963" />
</p>

<h1 align="center">VPinOS</h1>

<p align="center">
  A minimal, appliance-style Linux for virtual pinball cabinets and desktop PCs.<br>
  Boots fast, brings up a GPU-accelerated display, and launches
  <a href="https://github.com/vpinball/vpinball">Visual Pinball</a> and the
  <strong>vpinfe</strong> frontend.<br>
  Also plays Visual Pinball in <a href="#vr">VR</a>
  on standalone headsets like the Meta Quest 3, streamed over USB or Wi-Fi with
  <a href="https://github.com/WiVRn/WiVRn">WiVRn</a>.
</p>

<p align="center">
  <a href="../../actions/workflows/build-iso.yml"><img src="../../actions/workflows/build-iso.yml/badge.svg" alt="Build VPinOS ISO"></a>
  <a href="../../releases"><img src="https://img.shields.io/badge/download-latest%20release-4aa8ff" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/status-beta-orange" alt="Status: beta">
</p>

<p align="center">
  <a href="https://www.youtube.com/playlist?list=PLCu9W14IS_rs"><strong>Watch the videos on YouTube</strong></a>
  &nbsp;&bull;&nbsp;
  <a href="https://discord.com/channels/652274650524418078/1555201704574582844"><strong>Join the Discord channel</strong></a>
</p>

> [!IMPORTANT]
> **From v1.1 on, VPinOS updates itself, so you won't need a new ISO.** The
> menu, launcher and configuration tools, the kernel and the NVIDIA driver
> all ship as packages. Pick **Update VPinOS** from the menu (or run
> `sudo apt update && sudo apt upgrade`) to get every new release on an
> installed VPinOS system. Your settings (monitor layout, boot mode, GPU
> driver choice, VPinFE settings) are never changed by an update.
>
> **Coming from 1.0.x?** Moving to v1.1 needs **one fresh install**; there is
> no in-place upgrade from 1.0.x. Back up your tables, `~/.config/vpinfe/` and
> `~/.local/share/VPinballX/10.8/VPinballX.ini` first. After that, every
> update comes through the menu. See [Updates](#updates).

> [!WARNING]
> **VPinOS is in beta.** It works end to end (boot, launch, install), but it
> is under active development: expect rough edges, breaking changes between
> releases, and features that are still placeholders (the console menu, for
> one). Don't rely on it for anything you can't reinstall, keep backups of
> your tables and settings, and please
> [report problems](../../issues) or drop by the
> [Discord channel](https://discord.com/channels/652274650524418078/1555201704574582844).

> [!NOTE]
> **3 sample tables are bundled directly in the ISO** (Fair Fight, Mars
> Trek, Halley Comet) — no network needed to see them, live or installed.
> A 4th table (Cyclopes) is available but not bundled; fetching it
> requires re-enabling `vpinos-fetch-tables.service`, which is off by
> default. See [Sample tables](#sample-tables) for details.

---

## What it is

VPinOS is a custom Debian 13 (trixie) image, built with
[live-build](https://live-team.pages.debian.net/live-manual/), that ships as
a single hybrid ISO. It is **not** a general-purpose desktop. The whole point
is a machine that goes from power-on to pinball with as little OS in the way
as possible:

- **Base:** Debian trixie with `trixie-backports` enabled. The **Linux 7.1
  kernel**, a current **Mesa (26.1)** and current **AMD GPU firmware** come
  from backports so recent GPUs work out of the box (see
  [Requirements](#requirements)); everything else is stock trixie.
- **Display:** [Hyprland](https://hyprland.org/) as the compositor,
  with the launched program as its only Wayland client.
- **Graphics:** open-source Mesa Vulkan drivers (AMD, Intel, NVIDIA via
  NVK) on the Linux 7.1 kernel, so VPinball's BGFX renderer runs with a
  real GPU.
- **Apps:** `vpinball` and `vpinfe` (a pinball frontend/launcher), plus
  Google Chrome for vpinfe's local UI.
- **VR (optional):** play VPinball in a standalone headset
  such as a Meta Quest 3, streamed from the VPinOS machine with
  [WiVRn](https://github.com/WiVRn/WiVRn). Installed on demand from the
  menu, not part of the ISO. See [VR](#vr).
- **Account:** one hardcoded appliance user, `vpinos` (password `vpinos`),
  in the `video`, `input`, `audio`, `render`, `dialout`, `plugdev` and
  `sudo` groups. The apps run
  as this user, not as root.

## Live vs. installed

The same image runs two ways. Everything is identical except where it lives
and whether changes survive a reboot.

|                       | **Live** (boot the USB stick)                    | **Installed** (on the machine's disk)              |
|-----------------------|--------------------------------------------------|----------------------------------------------------|
| How you get it        | Write the ISO to a USB stick and boot it         | Run the installer from the live session ("Install VPinOS") |
| Storage               | Read-only image, changes held in RAM             | Normal read-write install                          |
| Changes persist?      | **No** &mdash; everything resets on reboot, unless you boot "save settings to USB" ([below](#saving-settings-on-the-live-usb)) | Yes |
| Login                 | Console autologin as `vpinos` on tty1            | Console autologin as `vpinos` on tty1              |
| Start the menu        | automatic on login                               | automatic on login                                 |
| `sudo`                | Passwordless (live session default)              | Asks for the `vpinos` password, except the launcher the menu uses |
| Updating VPinOS       | Not useful (lost at reboot) &mdash; use a newer ISO | Menu &rarr; Update VPinOS, or `sudo apt update && sudo apt upgrade` |
| Good for              | Trying it, hardware checks, running the installer | Daily use                                         |

The **live** session is the way to try VPinOS on a machine without touching
its disks. To make it permanent, pick **Install VPinOS** from
the menu and follow the prompts (language, keyboard, partitioning, summary).

### Saving settings on the live USB

To keep your settings on the stick across reboots, pick
**Live system (amd64, save settings to USB)** at the boot menu. The first
time, VPinOS makes a partition (`vpinos-data`) in all the free space on the
stick after the image, before the menu comes up. From then on, booting the
same entry brings back:

- VPinOS Configuration (screens, table rotation), Console Rotation, GPU
  Driver and Boot on startup (`/etc/vpinos`)
- VPinball and VPinFE settings, and your tables (`/home/vpinos`)
- Wi-Fi and other network connections

Pick that entry on every boot: the boot menu waits, and the normal
**Live system** entry starts without the saved settings (and doesn't touch
them). The main menu says whether settings are being saved, and why not if
they aren't. **Tools &rarr; Reset Saved Settings** clears them and reboots.

Good to know:

- It needs a stick written from the ISO as in [Using an ISO](#using-an-iso)
  (dd, balenaEtcher, or Rufus in DD mode) with at least 1 GB free after the
  image. Ventoy, Rufus's ISO mode, a DVD or a virtual machine's CD don't
  have room for it; the menu says so.
- Only settings are kept, not installed software: VR components, VPX Editor
  and updates are still lost at reboot. Install VPinOS for those.
- Writing the ISO to the stick again removes the saved settings.
- Settings saved on the stick aren't copied when you install VPinOS from it.

### The menu

The menu launches automatically on login — a plain numbered shell prompt
("Quit to shell" drops to a normal shell, e.g. for debugging — running
`vpinos-menu` by hand brings it back). The top level differs slightly
between the live session and an installed system:

```
live session                      installed system
--------------------------------  --------------------------------
1) Setup                          1) Setup
2) Testing                        2) VPinFE
3) VR                             3) VR
4) Install VPinOS                 4) Update VPinOS
5) System Info (Debug)            5) Testing
q) Quit to shell                  6) System Info (Debug)
s) Shutdown                       q) Quit to shell
r) Reboot                         s) Shutdown
                                  r) Reboot
```

"Update VPinOS" (installed systems only) runs the same full update as
`sudo apt update && sudo apt upgrade`, right in the console, then restarts
the menu. See [Updates](#updates).

"Setup" groups everything that configures the system rather than runs it:

```
1) Console Rotation: normal
2) GPU Driver: default
3) VPinOS Configuration
4) Network Settings
5) VPXConfig (Advanced VPinball Configuration)
6) VPinFE Map Controls
7) Boot on startup: menu       (installed, or live with saved settings)
```

"VPinOS Configuration" (`vpinos-config` — was "Monitor Detection" until it
grew past just monitors) starts a local web server and opens it in a
windowed Chrome, same pattern as "VPXConfig" below (`127.0.0.1:1112`, this
machine only, stopped as soon as you close the browser): identify which
output name (`DP-2`, `HDMI-A-1`, ...) is which physical screen, assign each
one a role (Table/Backglass/DMD) and refresh rate, set VPinball
Mode/Rendering Options, and save straight into
`hyprland.conf`/`VPinballX.ini`.

"Network Settings" runs `nmtui`, NetworkManager's own text UI — edit or
activate Ethernet/Wi-Fi connections, and set the system hostname. Not
Wi-Fi-specific despite the common association.

"VPXConfig" starts a configuration tool with a web interface: the menu
starts its local server (`127.0.0.1:1111`, this machine only), opens it in a
windowed Chrome, and stops the server as soon as you close the browser (or
click its own Quit button).

"VPinFE Map Controls" runs `vpinfe --gamepadtest`, vpinfe's own
controller-mapping mode.

"Boot on startup" (installed systems, or a live USB that
[saves its settings](#saving-settings-on-the-live-usb)) lets
you pick a program to launch automatically on boot instead of this menu, e.g.
VPinFE for a setup that should go straight to the frontend. Quitting that
program (or it exiting for any other reason) always falls back to this menu,
never a dead end.

"Testing" groups things you run to try the system out, rather than
configure it:

```
1) Launch VPinball Example Table
2) VPinFE       (live session only)
```

VPinFE itself — the table-browsing frontend — is tucked into
Testing on the live session (there's nowhere else to reach it from), but
promoted to its own top-level option on an installed system: that's the one
you reach for constantly in day-to-day use, so it doesn't sit a menu level
down.

"GPU Driver" switches between the open-source driver this image uses by
default (Mesa/NVK on NVIDIA hardware, RADV on AMD, Intel's own driver) and
the NVIDIA proprietary driver, precompiled into the image at build time.
Takes effect on the very next launch — no reboot needed, live or installed.
Confirmed working well with Hyprland/Wayland on real NVIDIA hardware by
multiple testers, and **recommended on NVIDIA cards**: testers report poor
pinball performance with NVK. NVK/nouveau stays the default because it
needs no setup, and it's the only option for cards older than Turing,
which the proprietary driver here doesn't support.

"VR" streams VPinball to a standalone VR headset. See
[VR](#vr) below.

"Shutdown" asks for confirmation, then powers the machine off.

The menu is a deliberate placeholder to prove out the launch path; booting
straight into the frontend is still to come.

## Releases

Prebuilt ISOs are published on the
[**Releases**](../../releases) page.

- A release is created **only when a version tag** (`v1.2.3`, matching the
  version stamped into the image) is pushed. The `Build VPinOS ISO` GitHub
  Actions workflow builds the image from a clean checkout and attaches it.
- Each release contains:
  - `live-image-amd64.hybrid.iso` &mdash; the image (roughly 2&nbsp;GB)
  - `live-image-amd64.packages` &mdash; every package and version in the image
  - `live-image-amd64.contents` / `.files` &mdash; the full file listing
- Pushes to `main` and manual runs build the image and upload it as a
  short-lived workflow artifact for verification, but do not create a release.
- The version shown on the boot splash, in the installer, on the login
  banner and in `/etc/os-release` all come from that one file:
  [`config/includes.chroot/etc/os-release`](config/includes.chroot/etc/os-release).

### Using an ISO

1. Download `live-image-amd64.hybrid.iso` from the latest release.
2. Write it to a USB stick (this **erases** the stick), for example:
   ```bash
   sudo dd if=live-image-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress conv=fsync
   ```
   or use a tool such as balenaEtcher. Double-check `/dev/sdX` first.
3. Boot the target machine from the stick. The image carries both BIOS
   (syslinux) and UEFI (GRUB) boot files.
4. Run `vpinos-menu`. To install, choose "Install VPinOS".

### Requirements

- x86-64 PC with a Vulkan-capable GPU. The image ships the **Linux 7.1
  kernel, Mesa 26.1 and current AMD GPU firmware from Debian's
  trixie-backports** (trixie's own 6.12 kernel and Mesa 25.0 are too old for
  the newest cards). By default VPinOS uses the **open-source Mesa
  drivers**, all included, so no driver install is needed:
  - **AMD** &mdash; Mesa RADV
  - **Intel** &mdash; Mesa Intel Vulkan
  - **NVIDIA** &mdash; the open-source NVK driver (Mesa) with NVIDIA's GPU
    firmware, for Turing (RTX 16/20-series) and newer cards. It runs on
    real NVIDIA hardware, but testers report **poor performance** with it
    for pinball, so on NVIDIA the proprietary driver (below) is
    recommended instead. Older NVIDIA cards (Kepler, Maxwell, Pascal
    &mdash; e.g. Quadro K-series, GTX 900/10-series) are not known to have a
    working Vulkan driver here (untested with the newer Mesa): the kernel's
    `nouveau` driver still runs the display, but Vulkan may fall back to
    software (see below). Whether OpenGL on those cards is usable for
    vpinball is untested.

    **Recommended for NVIDIA:** NVIDIA's **proprietary driver**, which
    is included in the image as well and switched on from the menu
    ("GPU Driver"). It's what all current NVIDIA testers use. See
    [NVIDIA video card support](#nvidia-video-card-support).
- **How to tell if your GPU is being used:** run `vulkaninfo --summary`. If
  the device is `llvmpipe` (or `lavapipe`), Vulkan is falling back to
  software rendering on the CPU &mdash; the GPU isn't supported, and it will
  be far too slow for pinball.
- The installer sets up a **UEFI** boot (GRUB EFI). Installing onto a
  BIOS-only machine has not been tested.
- A network connection is needed to update, and for the 4th sample table
  (not bundled, see [Sample tables](#sample-tables) below), but not
  otherwise to run.
- **A network connection is required to complete installation via
  Calamares.** The image ships without apt package indices (see the
  `lb config` command's `--apt-indices false` further down) to keep the
  ISO smaller, so the installer refreshes them from the network
  (`apt-get update`, via `update_db: true` in
  `config/includes.chroot/etc/calamares/modules/packages.conf`) before it
  can remove the live-only packages during install. No connection at that
  point means installation fails with a "Package Manager error". Connect
  via "Network Settings" (`nmtui`, see below) from the live session
  *before* launching the installer.

### NVIDIA video card support

Besides the open-source NVK driver above (the default, no install needed),
every amd64 VPinOS install also carries NVIDIA's **proprietary** driver, and
you can switch to it at runtime from the console menu (`vpinos-menu` &rarr;
"GPU Driver" &rarr; "NVIDIA proprietary"). It's off unless you pick it. It is
NVIDIA's **615.71.09** driver from NVIDIA's own apt repository, using
NVIDIA's open-source kernel module (NVIDIA no longer ships the closed one
on this driver branch). The kernel module comes prebuilt for the exact
VPinOS kernel (package `vpinos-nvidia-modules-<kernel>`), so nothing is
compiled on your machine, and newer tested driver versions arrive through
the normal update (see [Updates](#updates)). That open kernel
module supports Turing and newer GPUs:

| Architecture       | Year | GeForce series                          |
|--------------------|------|------------------------------------------|
| Turing             | 2018 | GeForce 16 series, GeForce 20 series     |
| Ampere              | 2020 | GeForce 30 series                        |
| Ada Lovelace        | 2022 | GeForce 40 series                        |
| Blackwell           | 2025 | GeForce 50 series                        |

Older cards (Kepler, Maxwell, Pascal &mdash; e.g. GTX 900/10-series and
earlier) aren't supported by this proprietary path at all; they fall back to
the default NVK/nouveau path above. The proprietary driver has been
confirmed working well with Hyprland/Wayland on real NVIDIA hardware by
multiple testers &mdash; see `notes/nvidia-proprietary.md` for the
investigation history.

## VR

VPinOS can stream VPinball to a standalone VR headset, such as a
**Meta Quest 3**, using [WiVRn](https://github.com/WiVRn/WiVRn). VPinball
renders the table through OpenXR on the PC's GPU, and WiVRn encodes it
and sends it to the headset over **USB** or **Wi-Fi**. It has been
confirmed working on real hardware by testers; if you hit a problem, please
[report it](../../issues).

Nothing VR-related is in the ISO. Everything is installed on demand from
the menu, so installations without a headset don't carry it.

### Setting it up

1. **Headset:** turn on **Developer Mode** for the headset (Meta Horizon
   phone app), and install the **WiVRn app** on it. The app's version must
   **match the WiVRn version on the VPinOS machine**, which VR &rarr; Setup shows
   once installed.
2. **VPinOS machine:** `vpinos-menu` &rarr; **VR** &rarr; **Setup** &rarr;
   **Install VR components**. This needs a network connection. It installs
   WiVRn and xrizer (from the VPinOS apt repository), adb, and the video
   encoder libraries that match your GPU.
3. **NVIDIA cards:** for hardware encoding (NVENC), also set **GPU Driver**
   to **NVIDIA proprietary**. It's in VR &rarr; Setup too. Without it,
   WiVRn falls back to slower software encoding. AMD and Intel use VAAPI
   hardware encoding with the default driver.

On the **live** USB the VR components are lost at every reboot, like
anything else installed there, so install VPinOS to keep them.

### Playing

```
              VR
==============================
Components: installed
Server: stopped   Headset (USB): connected
Encoder: nvenc   VPX VR: off

1) Setup
2) Start VR server
3) Stop VR server
4) WiVRn Dashboard
5) Connect headset over USB
6) Pair new headset (Wi-Fi)
7) Launch VPinball Example Table
8) Show server log
```

- **Start VR server** starts WiVRn and turns VR on in VPinball
  (`[PlayerVR] AskToTurnOn = 0` in `VPinballX.ini`, which it creates if
  VPinball hasn't run yet). **Stop VR server** stops WiVRn and puts that
  setting back to what it was before. While the server is running, every
  table you launch (from VPinFE too) opens in the headset.
- **Over USB:** plug the headset in, accept the "Allow USB debugging"
  prompt inside it the first time, then use **Connect headset over USB**.
  That starts the WiVRn app on the headset and connects it.
- **Over Wi-Fi:** the headset finds the VPinOS machine by itself on the same
  network. A new headset has to be paired once: **Pair new headset**, then
  enter the PIN shown when the headset asks.
- **WiVRn Dashboard** opens WiVRn's own settings app (starting the VR
  server first). Close it with SUPER+Q to get back to the menu.
- **Launch VPinball Example Table** does all of the above and opens the
  example table, as a quick test.

Other VR settings (refresh rate, table position, passthrough, ...) are
VPinball's own, in the `[PlayerVR]` section of
`~/.local/share/VPinballX/10.8/VPinballX.ini`.

## Sample tables

`~/tables` ships pre-populated with 3 of the 4 tables from
[`superhac/vpinos-test-tables`](https://github.com/superhac/vpinos-test-tables)
&mdash; Fair Fight, Mars Trek and Halley Comet (143.2&nbsp;MB) &mdash;
fetched at build time, not committed into this repo. The 4th table,
Cyclopes (103.3&nbsp;MB), is left out: bundling all 4 (246.5&nbsp;MB)
would push the ISO over GitHub's 2&nbsp;GB release-asset limit.

A systemd service, `vpinos-fetch-tables.service`, can instead download
the full current set from the network on boot &mdash; **not enabled by
default for now**, since the bundled tables already populate `~/tables`
and its own idempotency check would just no-op against that. Re-enable
it (`systemctl enable vpinos-fetch-tables.service` in
`0200-enable-kiosk.hook.chroot`) to go back to download-on-boot instead
of bundling, e.g. if the upstream table set changes enough that the
bundled copies go stale.

## Updates

Since 1.1, VPinOS itself is a package. The menu, launcher, configuration
tool, helper scripts, sudoers rules and systemd units are `vpinos-core`,
built in [`vpinos/vpinos-packages`](https://github.com/vpinos/vpinos-packages).
`vpinball`, `vpinfe` and `vpxconfig` are packages too, built in
[`vpinos/deb-package-builder`](https://github.com/vpinos/deb-package-builder).
All of them are published from one signed apt repository,
[`vpinos/deb-repo`](https://github.com/vpinos/deb-repo), whose source and
public key are part of the image. So on an **installed** system, either pick
**Update VPinOS** from the menu or run:

```bash
sudo apt update && sudo apt upgrade
```

That picks up new VPinOS, vpinball, vpinfe and vpxconfig releases plus
Debian security updates, with no reinstall. Use `apt upgrade`, not
`apt-get upgrade`: `apt-get upgrade` won't install new packages, so it holds
back an update that adds a dependency. A newly built ISO always contains
whatever is currently published.

**Your settings are never touched by an update:**
`/etc/vpinos/hyprland.conf` (including the monitor layout set in VPinOS
Configuration), `/etc/vpinos/hyprland-installer.conf`, the boot mode and GPU
driver choices, and `~/.config/vpinfe/` (settings and theme) are written
once, at install, and left alone after that. A changed default for any of
them only reaches new installs.

The kernel, Mesa and the NVIDIA driver are held at fixed versions by a frozen
backports snapshot and exact-version apt pins, so a normal update never
changes them by accident. When VPinOS moves to a newer kernel or NVIDIA
driver, that arrives through the same update as well (packages
`vpinos-platform`, `vpinos-kernel` and the prebuilt NVIDIA modules). Reboot
afterwards. If you update by hand rather than from the menu, run
`sudo apt update && sudo apt upgrade` **twice** after a kernel/driver release:
the first run installs the new pins, the second the new kernel/driver. The
previous kernel stays in the GRUB menu as a fallback.

**Upgrading from 1.0.x:** there is no upgrade path. Systems installed from a
1.0.x ISO need a fresh install from 1.1 or newer (back up your tables,
`~/.config/vpinfe/` and `VPinballX.ini` first). After that, updates come
through apt.

### Backports (kernel, Mesa, GPU firmware)

The kernel (7.1), Mesa, GPU firmware and Hyprland come from
`trixie-backports`, but from a **frozen snapshot**, not the live backports
mirror. `/etc/apt/sources.list.d/vpinos-backports.list` points at one fixed
[snapshot.debian.org](https://snapshot.debian.org/) date, and
`/etc/apt/preferences.d/vpinos-backports.pref` prefers that snapshot for
those packages. The kernel is also pinned by its exact package name
(`linux-image-7.1.13+deb13-amd64`), and the NVIDIA driver by its exact version
(`/etc/apt/preferences.d/vpinos-nvidia-repo.pref`). Notes:

- **`sudo apt upgrade` does not move the kernel, Mesa, firmware or the NVIDIA
  driver on its own.** They only change when VPinOS publishes a new
  `vpinos-platform`/`vpinos-kernel` (see [Updates](#updates)). Everything else
  follows normal trixie and trixie-security updates.
- The snapshot replaced the live mirror because the live mirror's kernel
  packages were caught mid-transition more than once, which broke builds.
- The NVIDIA kernel modules come prebuilt for the exact kernel
  (`vpinos-nvidia-modules-<kernel>`), so an installation never needs DKMS or a
  compiler.
- Backports are opt-in in Debian. To take any other package from the
  snapshot, ask for it explicitly: `sudo apt install -t trixie-backports <package>`.

## Security notes

VPinOS is a single-purpose pinball image and ships with a **known default
password** (`vpinos` / `vpinos`) and an **SSH server** installed for remote
maintenance. On any VPinOS installation that is reachable from a network, change the
password after installing (`passwd`), and don't expose it to the internet.

## Building from source

You need Docker; everything else happens inside the `vpinos-builder`
container defined by the [`Dockerfile`](Dockerfile).

```bash
docker build -t vpinos-builder .

docker run --rm --privileged --ulimit nofile=65536:65536 -v "$PWD:/work" -w /work vpinos-builder lb clean
docker run --rm --ulimit nofile=65536:65536 -v "$PWD:/work" -w /work vpinos-builder \
  lb config \
    --distribution trixie \
    --architectures amd64 \
    --binary-images iso-hybrid \
    --archive-areas "main contrib non-free non-free-firmware" \
    --bootappend-live "boot=live components username=vpinos" \
    --apt-indices false

# NOT --backports true -- trixie-backports comes from
# config/archives/vpinos-backports.list instead, pinned to a frozen
# snapshot.debian.org timestamp (the live mirror's kernel packaging
# proved unreliable). See notes/vpinos.md step 2 for the full story,
# including why config/archives/vpinos-backports.pref pins by
# `origin snapshot.debian.org`, not just by release/suite name.
#
# --apt-indices false -- drops /var/lib/apt/lists (the downloaded
# Packages/Release/Translation indices for every configured repo,
# ~168M) from the shipped image after live-build's own final
# `Apt chroot update` re-sync against the real mirrors. A
# chroot-stage hook can't do this: that re-sync runs in the later
# binary stage, after every chroot hook, and silently repopulates
# whatever a hook deletes. Nothing at runtime needs it --
# network-manager + systemd-timesyncd are already present, so
# `apt-get update` works normally the first time anyone installs
# something on a real installation. See notes/vpinos.md for the full story.

# Fix ownership of the generated config only -- never `chown -R` the whole
# project: it corrupts cache/bootstrap and the built image ends up with its
# base system owned by the wrong user.
docker run --rm -v "$PWD:/work" -w /work vpinos-builder sh -c \
  'for d in config auto local .build; do [ -e "$d" ] && chown -R '"$(id -u):$(id -g)"' "$d"; done; true'

docker run --rm --privileged --ulimit nofile=65536:65536 -v "$PWD:/work" -w /work vpinos-builder lb build
```

The ISO lands in the project root as `live-image-amd64.hybrid.iso`. Always
run the full `lb clean` &rarr; `lb config` &rarr; `lb build` cycle after
editing anything under `config/`; a bare `lb build` silently reuses stale
stages. The [GitHub Actions workflow](.github/workflows/build-iso.yml) runs
this same sequence.

## Repository layout

| Path | What it is |
|------|------------|
| `config/package-lists/` | Debian packages installed into the image |
| `config/archives/` | apt preferences: kernel, Mesa and AMD firmware come from trixie-backports |
| `config/hooks/live/` | Scripts run inside the image at build time (user creation, branding, adding NVIDIA's apt repo, installing vpinos-core/vpinball/vpinfe, base services) |
| `config/includes.chroot/` | Files copied verbatim into the image: apt source and key, Calamares branding, `os-release`, `base-version`. The menu, launcher, Hyprland config and units come from the `vpinos-core` package ([`vpinos/vpinos-packages`](https://github.com/vpinos/vpinos-packages)) |
| `config/bootloaders/` | Boot splash and GRUB background artwork |
| `Dockerfile` | The reproducible build environment |
| `.github/workflows/build-iso.yml` | CI build and tag-triggered release |

`chroot/`, `binary/`, `cache/`, `.build/` and `dist/` are build output and
are not committed.

## Status

**Beta.** Early and actively developed. The build, live boot, launch path
(Hyprland &rarr; vpinball / vpinfe) and installer are working end to end.
Booting straight into the frontend on an installed system is now
opt-in ("Boot on startup"). Still ahead: persistence for the live medium, and
narrowing GPU/firmware support once the target hardware is settled.
