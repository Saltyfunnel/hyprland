#!/usr/bin/env bash
# ───────────────────────────────────────────────
# Saltyfunnel’s Hyprland One-Shot Installer (Working)
# Builds main HyprYou manually, then installs utils & greeter
# ───────────────────────────────────────────────
set -euo pipefail

echo -e "🌈 Hyprland One-Shot Installer"
echo "────────────────────────────"

CLONE_DIR="$(pwd)"
AUR_HELPER=""
PKG_MANAGER="sudo pacman -S --needed --noconfirm"

# Make all .sh files executable
echo "🔧 Setting build scripts executable..."
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
# Build a package folder with PKGBUILD (utils or greeter)
build_pkg() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        echo "🔧 Building and installing package in $dir..."
        pushd "$dir" >/dev/null

        # Remove dependency on hypryou for greeter to avoid errors
        if [[ "$dir" == "greeter" ]] && grep -q "depends=('hypryou')" PKGBUILD; then
            sed -i "s/depends=('hypryou')/depends=()/g" PKGBUILD
        fi

        makepkg -si --noconfirm || { echo "❌ Failed to build/install $dir"; popd >/dev/null; exit 1; }
        popd >/dev/null
    else
        echo "⚠️ Folder $dir not found, skipping."
    fi
}

# ───────────────────────────────────────────────
# Main installer flow
main() {
    detect_aur_helper
    install_system_deps
    install_aur_deps

    build_main
    install_main

    # Build utils
    build_pkg "hypryou-utils"

    # Build greeter automatically
    build_pkg "greeter"
    echo "⚠️ Remember to configure greetd to use hypryou-greeter as the session."

    echo -e "\n✅ Hyprland Material You fully installed!"
    echo "→ You can now select 'HyprYou' in your display/login manager."
}

main "$@"
