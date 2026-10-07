#!/bin/sh
# Crude placeholder menu. launch.sh handles everything -- starting
# Hyprland directly (exec, inheriting this shell's tty/session) and the
# chosen client as its client -- so this just needs to run it with
# the right command and wait for it to return.
#
# Only the installer is `sudo`'d -- it genuinely needs root for
# partitioning. vpinball/vpinfe/Chrome run directly as whichever user
# is running this menu (`vpinos`, in normal operation): seatd's default
# config already grants DRM/seat access to `video`-group members, no
# root required.
#
# A Textual (python3-textual) rewrite of this menu was tried and
# reverted -- it never rendered correctly on the real Linux virtual
# console (TERM=linux/fbcon): a confirmed, still-open upstream bug
# (https://github.com/Textualize/rich/issues/3231) means Rich/Textual's
# Unicode box-drawing borders don't render reliably there, even with a
# Unicode-capable console font and the right locale/encoding -- plain
# ASCII borders were tried too and still didn't come out right on a
# real boot. Back to plain POSIX sh/echo, which has no such dependency.

# VPXConfig and vpinos-config.py (cabinet configuration -- monitor
# roles/refresh rates, VPinball Mode, Rendering Options, Cabinet
# Autofit/Screen Dimensions/Full DMD) are both local web servers (the
# UI opens in a windowed Chrome, not the fullscreen kiosk one -- see
# launch.sh's hypr_config case arm) that each spawn and own their own
# Chrome process once launch.sh starts them (vpxconfig via its
# --open-chrome flag; vpinos-config.py always, since it needs Hyprland
# running for its hyprctl calls, same as any other graphical client
# here). Each is launch.sh's actual client -- not something this menu
# starts standalone and points a separately-launched Chrome at -- so
# Quit in the page closes the browser window too, and plain launch.sh
# client/exit-code handling (see its own header comment) is all that's
# needed: no separate run_/stop_ wrapper, port tracking, or curl
# health-check here, same shape as vpinball/vpinfe below.

# /etc/vpinos/boot-mode is what /etc/profile.d/vpinos-menu.sh reads at
# login to decide what to auto-launch before falling through to here.
# Changing it only makes sense on an INSTALLED system -- a live session
# never persists it across a reboot, and boot=live on the kernel cmdline
# is the same mechanism live-config itself already uses to tell the two
# apart (see notes/vpinos.md step 5), so it's precedented, not something
# new. Option 7 (and its whole submenu) simply doesn't exist on a live
# session -- not shown, not selectable, no renumbering of 1-6 either way.
is_installed() {
    ! grep -q 'boot=live' /proc/cmdline 2>/dev/null
}

# The list of available boot-on-startup programs lives here as a plain
# case statement, not a data structure -- POSIX sh (this file's shebang)
# has no arrays/associative arrays, and every other piece of this menu is
# already a plain case statement, so this matches. To add a program here,
# see the `manage-boot-programs` skill in notes/skills/ -- it walks
# through this function, the matching case arm in
# /etc/profile.d/vpinos-menu.sh, the audit check, and the docs together.
boot_mode_submenu() {
    while true; do
        clear
        cur=$(cat /etc/vpinos/boot-mode 2>/dev/null)
        [ -z "$cur" ] && cur=menu
        echo "=============================="
        echo "      Boot on startup"
        echo "=============================="
        echo "Currently: $cur"
        echo
        echo "1) VPinOS menu (default)"
        echo "2) VPinFE"
        echo "q) Cancel, no change"
        echo "=============================="
        printf "Select an option: "
        read -r bchoice
        case "$bchoice" in
            1)
                echo "menu" > /etc/vpinos/boot-mode
                echo "$(date -Is): menu: boot-mode set to menu" >>/var/log/vpinos-menu.log
                echo "Will boot to the VPinOS menu on next startup."
                sleep 2
                return
                ;;
            2)
                echo "vpinfe" > /etc/vpinos/boot-mode
                echo "$(date -Is): menu: boot-mode set to vpinfe" >>/var/log/vpinos-menu.log
                echo "Will boot straight to VPinFE on next startup."
                sleep 2
                return
                ;;
            q|Q)
                return
                ;;
            *)
                echo "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Switches which GPU kernel module launch.sh binds before starting
# Hyprland (see vpinos-gpu-driver.sh) -- unlike boot_mode_submenu above,
# this takes effect on the very next graphical launch, not the next
# reboot, and works identically live or installed: nothing graphical
# has started by the point launch.sh applies it, on any boot. Opt-in
# default ("default", meaning the open-source Mesa/NVK driver this
# image already ships and uses everywhere else) -- NVIDIA proprietary
# is precompiled at build time (0120-install-nvidia-driver.hook.chroot)
# but Hyprland/Wayland compatibility with it hasn't been independently
# verified by this project on real hardware, see notes/vpinos.md step 5.
gpu_driver_submenu() {
    while true; do
        clear
        cur=$(cat /etc/vpinos/gpu-driver 2>/dev/null)
        [ -z "$cur" ] && cur=default
        echo "=============================="
        echo "         GPU Driver"
        echo "=============================="
        echo "Currently: $cur"
        echo
        echo "1) Default (open-source Mesa/NVK)"
        echo "2) NVIDIA proprietary"
        echo "q) Cancel, no change"
        echo "=============================="
        printf "Select an option: "
        read -r gchoice
        case "$gchoice" in
            1)
                echo "default" > /etc/vpinos/gpu-driver
                echo "$(date -Is): menu: gpu-driver set to default" >>/var/log/vpinos-menu.log
                echo "Will use the open-source driver on the next launch."
                sleep 2
                return
                ;;
            2)
                echo "nvidia" > /etc/vpinos/gpu-driver
                echo "$(date -Is): menu: gpu-driver set to nvidia" >>/var/log/vpinos-menu.log
                echo "Will use the NVIDIA proprietary driver on the next launch."
                sleep 2
                return
                ;;
            q|Q)
                return
                ;;
            *)
                echo "Invalid option"
                sleep 1
                ;;
        esac
    done
}

while true; do
    clear
    echo "=============================="
    echo "            VPinOS"
    echo "=============================="
    echo "1) Configuration"
    echo "2) Network Settings"
    echo "3) Launch VPinball Example Table"
    echo "4) VPinFE"
    echo "5) VPinFE Map Controls"
    # 6) Launch Chrome only (debug) -- hidden from the menu for now, but
    # the case arm below is kept working; run it directly if needed:
    # /usr/local/bin/launch.sh chrome /usr/bin/google-chrome --kiosk ...
    echo "7) Install VPinOS"
    echo "8) VPXConfig (Advanced VPinball Configuration)"
    if is_installed; then
        cur=$(cat /etc/vpinos/boot-mode 2>/dev/null)
        [ -z "$cur" ] && cur=menu
        echo "9) Boot on startup: $cur"
    fi
    gcur=$(cat /etc/vpinos/gpu-driver 2>/dev/null)
    [ -z "$gcur" ] && gcur=default
    echo "10) GPU Driver: $gcur"
    echo "11) System Info (Debug)"
    echo "q) Quit to shell"
    echo "s) Shutdown"
    echo "=============================="
    printf "Select an option: "
    read -r choice

    case "$choice" in
        1)
            echo "$(date -Is): menu: selected option 1 (configuration)" >>/var/log/vpinos-menu.log
            /usr/local/bin/launch.sh vpinos-config /usr/local/bin/vpinos-config.py
            echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            ;;
        2)
            # nmtui is a plain ncurses TUI (NetworkManager's own) -- no
            # display server needed, unlike every other option here, so
            # it runs directly in this tty rather than through
            # launch.sh/Hyprland. Covers both Ethernet and Wi-Fi
            # connections (edit/activate), plus the system hostname --
            # not Wi-Fi-specific despite the common association. `sudo`
            # (scoped in /etc/sudoers.d/vpinos) because editing
            # connections needs polkit auth_admin_keep even for the
            # active local session, and there's no polkit agent here to
            # satisfy that prompt -- root bypasses it entirely.
            echo "$(date -Is): menu: selected option 2 (network settings)" >>/var/log/vpinos-menu.log
            sudo nmtui
            echo "$(date -Is): menu: nmtui exited $?" >>/var/log/vpinos-menu.log
            ;;
        3)
            echo "$(date -Is): menu: selected option 3 (vpinball)" >>/var/log/vpinos-menu.log
            /usr/local/bin/launch.sh vpinball \
                /opt/vpinball/VPinballX_BGFX -play /opt/vpinball/assets/exampleTable.vpx
            echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            ;;
        4)
            echo "$(date -Is): menu: selected option 4 (vpinfe)" >>/var/log/vpinos-menu.log
            /usr/local/bin/launch.sh vpinfe /opt/vpinfe/vpinfe
            echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            ;;
        5)
            # --gamepadtest: vpinfe's own controller-mapping mode. Routed
            # through launch.sh the same as plain vpinfe (option 4) --
            # still a real Wayland client needing Hyprland up, just given
            # an extra flag (launch.sh's own usage comment already
            # documents `<name> <command> [args...]`, so this is nothing
            # new). Distinct client_name for its own clearly-labeled log
            # lines; doesn't affect hypr_config selection (only
            # "installer"/"vpxconfig" get the windowed config, everything
            # else -- this included -- gets the normal fullscreen kiosk
            # one, matching plain vpinfe's own treatment).
            echo "$(date -Is): menu: selected option 5 (vpinfe map controls)" >>/var/log/vpinos-menu.log
            /usr/local/bin/launch.sh vpinfe-gamepadtest /opt/vpinfe/vpinfe --gamepadtest
            echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            ;;
        6)
            echo "$(date -Is): menu: selected option 6 (chrome debug)" >>/var/log/vpinos-menu.log
            /usr/local/bin/launch.sh chrome /usr/bin/google-chrome \
                --kiosk --enable-logging=stderr --vmodule='*ozone*=1,*wayland*=1' about:blank
            echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            ;;
        7)
            echo "$(date -Is): menu: selected option 7 (calamares installer)" >>/var/log/vpinos-menu.log
            sudo /usr/local/bin/launch.sh installer /usr/bin/calamares
            echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            ;;
        8)
            echo "$(date -Is): menu: selected option 8 (vpxconfig)" >>/var/log/vpinos-menu.log
            /usr/local/bin/launch.sh vpxconfig /usr/bin/vpxconfig --open-chrome
            echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            ;;
        9)
            if is_installed; then
                boot_mode_submenu
            else
                echo "Invalid option"
                sleep 1
            fi
            ;;
        10)
            gpu_driver_submenu
            ;;
        11)
            # Plain "sysinfo" client_name, not in launch.sh's windowed-
            # config case arm (unlike option 1's "vpinos-config"): a Tk
            # GUI that manages its own fullscreen presentation, so it
            # runs fine under the plain kiosk Hyprland config -- no
            # windowed-config special case needed (see launch.sh's
            # hypr_config selection).
            echo "$(date -Is): menu: selected option 11 (system info)" >>/var/log/vpinos-menu.log
            /usr/local/bin/launch.sh sysinfo /usr/local/bin/vpinos_sysinfo.py
            echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            ;;
        q|Q)
            break
            ;;
        s|S)
            printf "Shut down now? [y/N]: "
            read -r confirm
            case "$confirm" in
                y|Y)
                    echo "$(date -Is): menu: selected shutdown, confirmed" >>/var/log/vpinos-menu.log
                    sudo /usr/bin/systemctl poweroff
                    ;;
                *)
                    echo "$(date -Is): menu: selected shutdown, cancelled" >>/var/log/vpinos-menu.log
                    ;;
            esac
            ;;
        *)
            echo "Invalid option"
            sleep 1
            ;;
    esac
done
