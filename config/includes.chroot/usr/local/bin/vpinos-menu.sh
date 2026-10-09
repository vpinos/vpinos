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
# new. "Boot on startup" (inside the Setup submenu) simply doesn't exist
# on a live session -- not shown, not selectable.
is_installed() {
    ! grep -q 'boot=live' /proc/cmdline 2>/dev/null
}

# Raw ANSI art + bordered version/IP line for the main menu's header --
# deliberately NOT shared with /usr/local/bin/vpinos-banner.sh (the
# identical-looking banner shown on SSH login via
# /etc/update-motd.d/00-vpinos-banner): kept as two independent,
# duplicated copies on purpose rather than one calling the other, so
# this file has no runtime dependency on another script existing/being
# installed at a specific path. A quoted heredoc so the embedded escape
# sequences pass through byte-for-byte with zero shell interpretation
# (dash's own echo/printf escape handling is not portable, so this
# sidesteps that entirely). Uses only standard 16-color SGR codes
# (30-37/40-47/90-97), the same basic color mechanism `ls --color`/
# `dmesg` already rely on -- confirmed reliable on the real Linux
# console in a way this file's own header comment notes fancy Unicode
# box-drawing was NOT (the Textual/Rich rewrite that was tried and
# reverted). If the art/version/IP format ever needs to change, update
# both this function and vpinos-banner.sh.
print_logo() {
    cat <<'EOF'
[40m[30m▄[47m[97m▄[107m[37m░[47m[97m▄[107m[37m░[40m[30m▄[40m  [40m▄[97m▄[107m[30m   ▄[37m░░[30m      [40m[97m▄[37m▄[30m▄[107m   [40m▄▄▄▄▄▄▄▄▄▄▄[96m▄▄[46m▄▄▄▄▄[40m▄▄[30m▄[96m▄▄[106m[30m     [36m░[30m [40m[96m▄[30m▄[0m
[40m[30m [40m▄[107m   [40m[97m▄[30m▄▄[97m▄[107m[30m   [40m▄[97m▄[107m[30m   ▄▄▄    [40m[97m▄▄▄[30m▄[97m▄▄▄▄▄▄▄▄[30m▄▄[106m[36m░░░[30m▄▄▄▄[36m░░░[40m[30m▄[106m[36m░░░[30m▄▄▄▄▄▄▄[40m▄[0m
[40m[30m [40m▄[107m▄[37m░░░[40m[30m▄[97m▄[107m[37m░░[30m [40m▄▄[107m  [37m░[40m[97m▄▄▄▄[107m[37m░░[30m [40m▄[107m   [40m▄[107m   ▄▄    [40m[96m▄[106m[36m▒▒░[40m[30m▄▄▄[90m▄[106m[36m▒▒░[40m[30m▄[106m[36m▒▒▒▒▒▒▒[40m▄▄[30m▄[40m [0m
[40m[30m  [40m▄[107m[94m░[34m░░[40m[37m▄[107m[34m░░[30m▄[40m▄▄[97m▄[107m[94m░░░[30m▄▄▄▄▄▄[40m▄[97m▄[107m[94m░░[30m▄[37m░[94m░░[40m[30m▄▄▄[107m[94m░░░[40m[30m▄[106m[34m▒░░[40m[30m▄▄▄▄[106m[36m▄[34m▒▒[30m▄[40m▄▄[106m▄▄[46m▄▄▄[106m[34m▒▒▒[40m[30m▄[40m [0m
[40m[30m  [40m▄[47m▄[106m[35m░░░░[107m[30m▄[40m▄▄▄[107m[94m▒▒▒[47m[30m▄[40m▄▄▄▄▄▄▄[107m[94m▒▒▒[40m[30m▄[107m[94m▒▒▒[40m[30m▄▄[90m▄[107m[94m▒▒[47m[97m▄[40m[30m▄[104m[36m░░░░░░░░░[106m[34m▒[40m[30m▄[104m[36m░░░░░░░░░[30m▄[40m▄[40m [0m
[40m[30m   [40m▄[107m▄▄▄▄[40m▄▄▄▄[107m▄▄▄[40m▄▄▄▄▄▄▄▄[107m▄▄▄[47m▄[107m▄▄[96m▄[40m[30m▄▄[107m▄▄▄[40m▄▄▄[106m▄▄▄▄▄▄▄[40m▄▄[106m▄▄▄▄▄▄▄▄▄[40m▄▄[40m  [0m
[40m[30m    [40m▄[104m▄▄▄[46m▄▄▄▄[106m▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄[40m[96m▄[106m[30m▄[36m▒[40m[30m▄[104m[36m░[40m[30m▄[106m▄▄▄▄▄▄▄▄▄▄▄▄▄▄[46m▄▄▄▄[104m▄▄▄▄[40m▄[40m    [0m
[40m[30m                          [40m▄[106m▄[40m[96m▄[30m▄▄[104m[36m░[40m[30m▄[40m                           [0m
[40m[30m                           [40m▄▄[106m▄[46m▄[40m▄▄[40m                           [0m
EOF
    # VERSION_ID comes straight from /etc/os-release (the same file
    # vpinos_sysinfo.py and every other version-reporting place in this
    # project reads) -- sourced in a subshell so it can't leak/clobber
    # any variable in the caller. `hostname -I` (capital I, the
    # `hostname` package's own flag, not iproute2) lists every assigned
    # address space-separated; first one is enough for an at-a-glance
    # cabinet IP, and it's empty (not an error) before DHCP has
    # completed or with no cable/Wi-Fi connected, so that's handled
    # explicitly rather than printing a blank value.
    ver=$(. /etc/os-release 2>/dev/null; echo "$VERSION_ID")
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    [ -z "$ip" ] && ip="not connected"

    # Bordered, centered under the logo -- plain ASCII (+/-/|), not box-
    # drawing Unicode, deliberately: same reasoning as the art above
    # avoiding Rich/Textual's box-drawing glyphs, zero risk instead of
    # unverified risk. Width matches the logo's own visible width (62
    # columns, confirmed via the art above -- every line is the same
    # width) so the frame lines up edge-to-edge with it rather than
    # floating at some unrelated size. Version and IP are separate rows
    # (not one combined line) and each centered independently, since
    # they're two distinct pieces of information, not one value.
    left_label="Version: "
    left="${left_label}${ver}"
    right_label="IP: "
    right="${right_label}${ip}"
    width=60
    leftcol=8
    rightcol=$((width - ${#right} + 1 - 8))
    # Overlaid directly onto the logo's own second-to-last row (not a
    # separate line below it) via plain VT100 cursor positioning --
    # CSI nA (cursor up n rows) and CSI nG (move to column n, same
    # row) -- ordinary ANSI cursor control, not Unicode, so it's no
    # less reliable on the real console than the color codes already
    # used throughout this art. \033[0m resets color first: that row
    # is black-on-black at this position in the original art, which
    # would otherwise make this text invisible without it. Labels red
    # (31), values bright white (97) for contrast. leftcol=8 (7-space
    # indent from column 1) and rightcol subtracts 10 from the plain
    # right-aligned position -- both fixed offsets from their earlier
    # flush-left/flush-right placement, not computed from the art's
    # own content. Ends by moving back down and to column 1 so
    # whatever prints next (menu options, etc.) resumes on a fresh
    # line below the logo, not mid-overlay.
    printf '\033[2A\033[%dG\033[0m\033[31m%s\033[97m%s' "$leftcol" "$left_label" "$ver"
    printf '\033[%dG\033[31m%s\033[97m%s' "$rightcol" "$right_label" "$ip"
    printf '\033[0m\033[2B\033[1G\n'
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
        print_logo
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
        print_logo
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

# Everything that configures the cabinet rather than runs/tests it --
# grouped here (instead of flat at the top level) once the menu grew
# past half a dozen items. "VPinOS Configuration" was the top-level
# "Configuration" option before this menu had submenus; same
# vpinos-config.py, same client_name, just relocated and relabeled.
setup_submenu() {
    while true; do
        clear
        print_logo
        echo "            Setup"
        echo "=============================="
        gcur=$(cat /etc/vpinos/gpu-driver 2>/dev/null)
        [ -z "$gcur" ] && gcur=default
        echo "1) GPU Driver: $gcur"
        echo "2) VPinOS Configuration"
        echo "3) Network Settings"
        echo "4) VPXConfig (Advanced VPinball Configuration)"
        echo "5) VPinFE Map Controls"
        if is_installed; then
            bcur=$(cat /etc/vpinos/boot-mode 2>/dev/null)
            [ -z "$bcur" ] && bcur=menu
            echo "6) Boot on startup: $bcur"
        fi
        echo "q) Back"
        echo "=============================="
        printf "Select an option: "
        read -r schoice

        case "$schoice" in
            1)
                gpu_driver_submenu
                ;;
            2)
                echo "$(date -Is): menu: selected setup/vpinos-config" >>/var/log/vpinos-menu.log
                /usr/local/bin/launch.sh vpinos-config /usr/local/bin/vpinos-config.py
                echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
                ;;
            3)
                # nmtui is a plain ncurses TUI (NetworkManager's own) --
                # no display server needed, unlike every other option
                # here, so it runs directly in this tty rather than
                # through launch.sh/Hyprland. Covers both Ethernet and
                # Wi-Fi connections (edit/activate), plus the system
                # hostname -- not Wi-Fi-specific despite the common
                # association. `sudo` (scoped in /etc/sudoers.d/vpinos)
                # because editing connections needs polkit
                # auth_admin_keep even for the active local session, and
                # there's no polkit agent here to satisfy that prompt --
                # root bypasses it entirely.
                echo "$(date -Is): menu: selected setup/network-settings" >>/var/log/vpinos-menu.log
                sudo nmtui
                echo "$(date -Is): menu: nmtui exited $?" >>/var/log/vpinos-menu.log
                ;;
            4)
                echo "$(date -Is): menu: selected setup/vpxconfig" >>/var/log/vpinos-menu.log
                /usr/local/bin/launch.sh vpxconfig /usr/bin/vpxconfig --open-chrome
                echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
                ;;
            5)
                # --gamepadtest: vpinfe's own controller-mapping mode.
                # Routed through launch.sh the same as plain vpinfe --
                # still a real Wayland client needing Hyprland up, just
                # given an extra flag (launch.sh's own usage comment
                # already documents `<name> <command> [args...]`, so
                # this is nothing new). Distinct client_name for its own
                # clearly-labeled log lines; doesn't affect hypr_config
                # selection (only "installer"/"vpxconfig"/"vpinos-config"
                # get the windowed config, everything else -- this
                # included -- gets the normal fullscreen kiosk one,
                # matching plain vpinfe's own treatment).
                echo "$(date -Is): menu: selected setup/vpinfe-map-controls" >>/var/log/vpinos-menu.log
                /usr/local/bin/launch.sh vpinfe-gamepadtest /opt/vpinfe/vpinfe --gamepadtest
                echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
                ;;
            6)
                if is_installed; then
                    boot_mode_submenu
                else
                    echo "Invalid option"
                    sleep 1
                fi
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

# Live CD only (see its one call site's is_installed guard) -- lets
# you SSH in with a password instead of a key, for debugging from a
# machine that hasn't got this cabinet's key set up. Off by default;
# toggling writes/removes a drop-in via vpinos-ssh-password-auth.sh
# (sudo'd, see /etc/sudoers.d/vpinos) rather than hand-editing
# /etc/ssh/sshd_config directly -- see that script's own comment.
ssh_password_auth_submenu() {
    while true; do
        clear
        if [ -e /etc/ssh/sshd_config.d/99-vpinos-live-testing.conf ]; then
            cur=on
        else
            cur=off
        fi
        print_logo
        echo "  SSH Password Authentication"
        echo "=============================="
        echo "Currently: $cur"
        echo
        echo "1) Enable"
        echo "2) Disable"
        echo "q) Cancel, no change"
        echo "=============================="
        printf "Select an option: "
        read -r schoice
        case "$schoice" in
            1)
                sudo /usr/local/bin/vpinos-ssh-password-auth.sh on
                echo "$(date -Is): menu: ssh-password-auth set to on" >>/var/log/vpinos-menu.log
                echo "SSH password authentication enabled."
                sleep 2
                return
                ;;
            2)
                sudo /usr/local/bin/vpinos-ssh-password-auth.sh off
                echo "$(date -Is): menu: ssh-password-auth set to off" >>/var/log/vpinos-menu.log
                echo "SSH password authentication disabled."
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

# Things you run to try the cabinet out rather than configure it.
# VPinFE itself lives here on a live session (there's nothing else to
# reach it from), but is promoted to its own top-level option on an
# installed system -- that's the one a cabinet builder reaches for
# constantly once it's actually built, so it doesn't belong a menu
# level down from day-to-day use.
testing_submenu() {
    while true; do
        clear
        print_logo
        echo "           Testing"
        echo "=============================="
        echo "1) Launch VPinball Example Table"
        if ! is_installed; then
            echo "2) VPinFE"
            if [ -e /etc/ssh/sshd_config.d/99-vpinos-live-testing.conf ]; then
                sshacur=on
            else
                sshacur=off
            fi
            echo "3) SSH Password Authentication: $sshacur"
        fi
        echo "q) Back"
        echo "=============================="
        printf "Select an option: "
        read -r tchoice

        case "$tchoice" in
            1)
                echo "$(date -Is): menu: selected testing/vpinball-example-table" >>/var/log/vpinos-menu.log
                /usr/local/bin/launch.sh vpinball \
                    /opt/vpinball/VPinballX_BGFX -play /opt/vpinball/assets/exampleTable.vpx
                echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
                ;;
            2)
                if is_installed; then
                    echo "Invalid option"
                    sleep 1
                else
                    echo "$(date -Is): menu: selected testing/vpinfe" >>/var/log/vpinos-menu.log
                    /usr/local/bin/launch.sh vpinfe /opt/vpinfe/vpinfe
                    echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
                fi
                ;;
            3)
                if is_installed; then
                    echo "Invalid option"
                    sleep 1
                else
                    ssh_password_auth_submenu
                fi
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

# Launch Chrome only (debug) -- not reachable from any menu, but still
# works if run directly from "Quit to shell":
#   /usr/local/bin/launch.sh chrome /usr/bin/google-chrome --kiosk \
#     --enable-logging=stderr --vmodule='*ozone*=1,*wayland*=1' about:blank

while true; do
    clear
    print_logo
    echo "            Main"
    echo "=============================="
    echo "1) Setup"
    if is_installed; then
        echo "2) VPinFE"
        echo "3) Testing"
    else
        echo "2) Testing"
        echo "3) Install VPinOS"
    fi
    echo "4) System Info (Debug)"
    echo "q) Quit to shell"
    echo "s) Shutdown"
    echo "=============================="
    printf "Select an option: "
    read -r choice

    case "$choice" in
        1)
            setup_submenu
            ;;
        2)
            if is_installed; then
                echo "$(date -Is): menu: selected top/vpinfe" >>/var/log/vpinos-menu.log
                /usr/local/bin/launch.sh vpinfe /opt/vpinfe/vpinfe
                echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            else
                testing_submenu
            fi
            ;;
        3)
            if is_installed; then
                testing_submenu
            else
                echo "$(date -Is): menu: selected top/install-vpinos" >>/var/log/vpinos-menu.log
                sudo /usr/local/bin/launch.sh installer /usr/bin/calamares
                echo "$(date -Is): menu: launch.sh exited $?" >>/var/log/vpinos-menu.log
            fi
            ;;
        4)
            # Plain "sysinfo" client_name, not in launch.sh's windowed-
            # config case arm: a Tk GUI that manages its own fullscreen
            # presentation, so it runs fine under the plain kiosk
            # Hyprland config -- no windowed-config special case needed
            # (see launch.sh's hypr_config selection).
            echo "$(date -Is): menu: selected top/sysinfo" >>/var/log/vpinos-menu.log
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
