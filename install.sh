#!/usr/bin/env bash
# Hyprland Material You one-shot installer (Full version)
# Author: Adapted for automation by ChatGPT (GPT-5)
# For Arch/EndeavourOS/Garuda systems
set -euo pipefail

REPO="https://github.com/koeqaife/hyprland-material-you.git"
CLONE_DIR="$HOME/.cache/hyprland-material-you"
AUR_HELPER=""
PKG_MANAGER="sudo pacman -S --needed --noconfirm"

# ───────────────────────────────────────────────
# Helper functions

detect_aur_helper() {
    for helper in yay paru trizen; do
        if command -v $helper &>/dev/null; then
            AUR_HELPER=$helper
            echo "🔎 Detected AUR helper: $AUR_HELPER"
            return
        fi
    done
    echo "❌ No AUR helper found. Please install yay or paru."
    exit 1
}

aur_install() {
    echo "📦 Installing AUR dependencies..."
    $AUR_HELPER -S --needed --noconfirm \
        python-materialyoucolor-git \
        libastal-bluetooth-git \
        libastal-wireplumber-git \
        ttf-material-symbols-variable-git
}

pacman_install() {
    echo "📦 Installing system dependencies..."
    $PKG_MANAGER \
        gtk4-layer-shell dart-sass python python-gobject python-pam gtk4 \
        libgirepository hyprland dbus dbus-glib python-pillow cairo libnm \
        cython hyprsunset upower python-pywayland cliphist xdg-dbus-proxy \
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland \
        xdg-utils polkit-gnome adw-gtk-theme greetd python-cairo \
        networkmanager hyprshot
}

clone_repo() {
    echo "📥 Cloning repository..."
    rm -rf "$CLONE_DIR"
    git clone --depth=1 "$REPO" "$CLONE_DIR"
}

build_main() {
    echo "🔧 Building main HyprYou..."
    pushd "$CLONE_DIR/hypryou" >/dev/null
    ./build.sh || { echo "❌ Build failed (hypryou)."; exit 1; }
    popd >/dev/null

    pushd "$CLONE_DIR/build" >/dev/null
    ./build.sh || { echo "❌ Build failed (main build)."; exit 1; }
    popd >/dev/null
}

build_utils() {
    echo "🧩 Building HyprYou Utils..."
    pushd "$CLONE_DIR/hypryou-utils" >/dev/null
    ./build.sh || { echo "❌ Build failed (utils)."; exit 1; }
    popd >/dev/null
}

build_greeter() {
    echo "👋 Building HyprYou Greeter..."
    pushd "$CLONE_DIR/hypryou-greeter" >/dev/null
    ./build.sh || { echo "❌ Build failed (greeter)."; exit 1; }
    popd >/dev/null
}

install_main() {
    echo "⚙️ Installing main components..."
    sudo mkdir -p /usr/share/hypryou
    sudo cp -r "$CLONE_DIR/hypryou-assets" /usr/share/hypryou/
    sudo cp -r "$CLONE_DIR/hypryou" /usr/lib/
    sudo install -Dm755 "$CLONE_DIR/build/hypryouctl" /usr/bin/hypryouctl
    sudo install -Dm755 "$CLONE_DIR/build/hypryou-start" /usr/bin/hypryou-start
    sudo install -Dm755 "$CLONE_DIR/build/hypryou-crash-dialog" /usr/bin/hypryou-crash-dialog
    sudo install -Dm644 "$CLONE_DIR/assets/hypryou.desktop" /usr/share/wayland-sessions/hypryou.desktop
}

install_utils() {
    echo "🧰 Installing Utils..."
    sudo mkdir -p /usr/share/hypryou-utils
    sudo cp -r "$CLONE_DIR/hypryou-utils" /usr/lib/
    sudo install -Dm755 "$CLONE_DIR/hypryou-utils/hypryou-utils" /usr/bin/hypryou-utils
}

install_greeter() {
    echo "🙋 Installing Greeter..."
    sudo mkdir -p /usr/share/hypryou-greeter
    sudo cp -r "$CLONE_DIR/hypryou-greeter" /usr/lib/
    sudo install -Dm755 "$CLONE_DIR/hypryou-greeter/hypryou-greeter" /usr/bin/hypryou-greeter
    echo "⚠️ Remember to configure greetd to use hypryou-greeter if desired."
}

clean_up() {
    echo "🧹 Cleaning up temporary files..."
    rm -rf "$CLONE_DIR"
}

done_message() {
    echo -e "\n✅ Hyprland Material You installed successfully!"
    echo "→ You can now select 'HyprYou' in your display/login manager."
    echo "→ If you installed the Greeter, edit /etc/greetd/config.toml to enable it."
}

# ───────────────────────────────────────────────
# Main flow

main() {
    echo "🌈 Hyprland Material You - Full Installer"
    echo "─────────────────────────────────────────"
    detect_aur_helper
    pacman_install
    aur_install
    clone_repo
    build_main
    install_main

    echo -n "🧩 Install HyprYou Utils (optional)? [y/N]: "
    read -r utils_choice
    if [[ "$utils_choice" =~ ^[Yy]$ ]]; then
        build_utils
        install_utils
    fi

    echo -n "👋 Install HyprYou Greeter (optional)? [y/N]: "
    read -r greeter_choice
    if [[ "$greeter_choice" =~ ^[Yy]$ ]]; then
        build_greeter
        install_greeter
    fi

    clean_up
    done_message
}

main "$@"
