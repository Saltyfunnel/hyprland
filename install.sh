#!/usr/bin/env bash
# ───────────────────────────────────────────────
# Saltyfunnel’s Hyprland One-Shot Installer (Fully Automatic)
# Installs HyprYou + utils + greeter without prompts
# ───────────────────────────────────────────────
set -euo pipefail

echo -e "🌈 Hyprland One-Shot Installer (Fully Automatic)"
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
# Build and install a package via makepkg
build_pkg() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        echo "🔧 Building and installing package in $dir..."
        pushd "$dir" >/dev/null

        # Remove hypryou dependency in greeter PKGBUILD to avoid errors
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
# Main installer
main() {
    detect_aur_helper
    install_system_deps
    install_aur_deps

    # Build & install main HyprYou first
    build_pkg "hypryou"

    # Build & install hypryou-utils automatically
    build_pkg "hypryou-utils"

    # Build & install greeter automatically
    build_pkg "greeter"
    echo "⚠️ Remember to configure greetd to use hypryou-greeter as the session."

    echo -e "\n✅ Hyprland Material You fully installed!"
    echo "→ You can now select 'HyprYou' in your display/login manager."
}

main "$@"
