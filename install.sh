#!/usr/bin/env bash
# ───────────────────────────────────────────────
#  Saltyfunnel’s Hyprland Material You Installer
# ───────────────────────────────────────────────
# Based on: koeqaife/hyprland-material-you
# Adapted for automation by ChatGPT (GPT-5)
# For: Arch / EndeavourOS / Garuda systems
# ───────────────────────────────────────────────

set -euo pipefail

echo -e "🌈 Welcome to Saltyfunnel’s Hyprland (Material You Edition) Installer!"
echo "───────────────────────────────────────────────"
sleep 1

# Use the current folder as repo path
CLONE_DIR="$(pwd)"
REPO="https://github.com/koeqaife/hyprland-material-you.git"
AUR_HELPER=""
PKG_MANAGER="sudo pacman -S --needed --noconfirm"

# ───────────────────────────────────────────────
# Ensure all .sh files are executable
echo "🔧 Setting build scripts executable..."
find "$CLONE_DIR" -type f -name "*.sh" -exec chmod +x {} \;

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
    echo "❌ No AUR helper found. Please install yay or paru first."
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
    echo "📥 Cloning Hyprland Material You repository (if needed)..."
    # Only clone if folder doesn't exist
    if [[ ! -d "$CLONE_DIR/hypryou" ]]; then
        git clone --depth=1 "$REPO" "$CLONE_DIR"
    else
        echo "ℹ️ Repo folder already exists, skipping clone."
    fi
}

build_main() {
    echo "🔧 Building main HyprYou..."
    if [[ -d "$CLONE_DIR/hypryou" ]]; then
        pushd "$CLONE_DIR/hypryou" >/dev/null
        ./build.sh || { echo "❌ Build failed (hypryou)."; exit 1; }
        popd >/dev/null

        pushd "$CLONE_DIR/build" >/dev/null
        ./build.sh || { echo "❌ Build failed (main build)."; exit 1; }
        popd >/dev/null
    else
        echo "❌ Main hypryou folder missing, cannot build."
        exit 1
    fi
}

build_utils() {
    if [[ -d "$CLONE_DIR/hypryou-utils" ]]; then
        echo "🧩 Building HyprYou Utils..."
        pushd "$CLONE_DIR/hypryou-utils" >/dev/null
        ./build.sh || { echo "❌ Build failed (utils)."; exit 1; }
        popd >/dev/null
    else
        echo "⚠️ Skipping Utils: folder not found."
    fi
}

build_greeter() {
    if [[ -d "$CLONE_DIR/hypryou-greeter" ]]; then
        echo "👋 Building HyprYou Greeter..."
        pushd "$CLONE_DIR/hypryou-greeter" >/dev/null
        ./build.sh || { echo "❌ Build failed (greeter)."; exit 1; }
        popd >/dev/null
    else
        echo "⚠️ Skipping Greeter: folder not found."
    fi
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
    if [[ -d "$CLONE_DIR/hypryou-utils" ]]; then
        echo "🧰 Installing HyprYou Utils..."
        sudo mkdir -p /usr/share/hypryou-utils
        sudo cp -r "$CLONE_DIR/hypryou-utils" /usr/lib/
        sudo install -Dm755 "$CLONE_DIR/hypryou-utils/hypryou-utils" /usr/bin/hypryou-utils
    else
        echo "⚠️ Skipping Utils installation: folder not found."
    fi
}

install_greeter() {
    if [[ -d "$CLONE_DIR/hypryou-greeter" ]]; then
        echo "🙋 Installing HyprYou Greeter..."
        sudo mkdir -p /usr/share/hypryou-greeter
        sudo cp -r "$CLONE_DIR/hypryou-greeter" /usr/lib/
        sudo install -Dm755 "$CLONE_DIR/hypryou-greeter/hypryou-greeter" /usr/bin/hypryou-greeter
        echo "⚠️ Remember to configure greetd to use hypryou-greeter if desired."
    else
        echo "⚠️ Skipping Greeter installation: folder not found."
    fi
}

clean_up() {
    echo "🧹 Cleaning up temporary files..."
    # No deletion needed if using repo folder directly
}

done_message() {
    echo -e "\n✅ Installation complete!"
    echo "🚀 Welcome to Saltyfunnel’s Hyprland (Material You Edition)"
    echo "───────────────────────────────────────────────"
    echo "→ You can now select 'HyprYou' in your display/login manager."
    echo "→ If you installed the Greeter, edit /etc/greetd/config.toml to enable it."
    echo -e "\n💡 Tip: Restart your session or reboot to apply changes fully."
}

# ───────────────────────────────────────────────
# Main flow

main() {
    echo "🌈 Saltyfunnel’s Hyprland Installer (Material You Edition)"
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
