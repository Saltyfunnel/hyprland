#!/usr/bin/env bash
# ───────────────────────────────────────────────
# Saltyfunnel’s Hyprland One-Shot Installer (Working)
# Main + utils + greeter
# ───────────────────────────────────────────────
set -euo pipefail

echo -e "🌈 Hyprland One-Shot Installer"
echo "────────────────────────────"

CLONE_DIR="$(pwd)"
AUR_HELPER=""
PKG_MANAGER="sudo pacman -S --needed --noconfirm"

# Make all .sh files executable
find "$CLONE_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# ───────────────────────────────────────────────
# Detect AUR helper
detect_aur_helper() {
    for helper in yay paru trizen; do
        if command -v $helper &>/dev/null; then
            AUR_HELPER=$helper
            echo "🔎 Detected AUR helper: $AUR_HELPER"
            return
        fi
    done
    echo "❌ No AUR helper found. Please install yay or paru first."
    exit 1
}

# ───────────────────────────────────────────────
# Install dependencies
install_system_deps() {
    echo "📦 Installing system dependencies..."
    $PKG_MANAGER \
        gtk4-layer-shell dart-sass python python-gobject python-pam gtk4 \
        libgirepository hyprland dbus dbus-glib python-pillow cairo libnm \
        cython hyprsunset upower python-pywayland cliphist xdg-dbus-proxy \
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland \
        xdg-utils polkit-gnome adw-gtk-theme greetd python-cairo \
        networkmanager hyprshot
}

install_aur_deps() {
    echo "📦 Installing AUR dependencies..."
    $AUR_HELPER -S --needed --noconfirm \
        python-materialyoucolor-git \
        libastal-bluetooth-git \
        libastal-wireplumber-git \
        ttf-material-symbols-variable-git
}

# ───────────────────────────────────────────────
# Build main HyprYou manually
build_main() {
    echo "🔧 Building main HyprYou..."
    pushd "$CLONE_DIR/hypryou" >/dev/null
    ./build.sh || { echo "❌ Build failed in hypryou/"; exit 1; }
    popd >/dev/null

    pushd "$CLONE_DIR/build" >/dev/null
    ./build.sh || { echo "❌ Build failed in build/"; exit 1; }
    popd >/dev/null
}

install_main() {
    echo "⚙️ Installing main HyprYou components..."
    sudo mkdir -p /usr/share/hypryou
    sudo cp -r "$CLONE_DIR/hypryou-assets" /usr/share/hypryou/
    sudo cp -r "$CLONE_DIR/hypryou" /usr/lib/
    sudo install -Dm755 "$CLONE_DIR/build/hypryouctl" /usr/bin/hypryouctl
    sudo install -Dm755 "$CLONE_DIR/build/hypryou-start" /usr/bin/hypryou-start
    sudo install -Dm755 "$CLONE_DIR/build/hypryou-crash-dialog" /usr/bin/hypryou-crash-dialog
    sudo install -Dm644 "$CLONE_DIR/assets/hypryou.desktop" /usr/share/wayland-sessions/hypryou.desktop
}

# ───────────────────────────────────────────────
# Build hypryou-utils manually
build_utils() {
    if [[ -f "$CLONE_DIR/hypryou-utils/hyprland-dialog.c" ]]; then
        echo "🧩 Building hypryou-utils..."
        gcc "$CLONE_DIR/hypryou-utils/hyprland-dialog.c" -o hyprland-dialog \
            $(pkg-config --cflags --libs gtk4) \
            -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 \
            -Wcast-align -Wconversion -Wstrict-overflow=5 -O2
        sudo install -Dm755 hyprland-dialog /usr/bin/hyprland-dialog
    else
        echo "⚠️ hypryou-utils C file not found, skipping."
    fi
}

# ───────────────────────────────────────────────
# Build greeter via makepkg
build_greeter() {
    if [[ -d "$CLONE_DIR/greeter" ]]; then
        echo "👋 Building and installing hypryou-greeter..."
        pushd "$CLONE_DIR/greeter" >/dev/null
        # Remove dependency on hypryou to avoid makepkg failure
        if grep -q "depends=('hypryou')" PKGBUILD; then
            sed -i "s/depends=('hypryou')/depends=()/g" PKGBUILD
        fi
        makepkg -si --noconfirm || { echo "❌ Failed to build/install greeter"; popd >/dev/null; exit 1; }
        popd >/dev/null
        echo "⚠️ Remember to configure greetd to use hypryou-greeter as the session."
    else
        echo "⚠️ Greeter folder not found, skipping."
    fi
}

# ───────────────────────────────────────────────
# Main installer
main() {
    detect_aur_helper
    install_system_deps
    install_aur_deps

    build_main
    install_main

    build_utils
    build_greeter

    echo -e "\n✅ Hyprland Material You fully installed!"
    echo "→ You can now select 'HyprYou' in your display/login manager."
}

main "$@"
