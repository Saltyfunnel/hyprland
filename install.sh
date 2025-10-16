#!/usr/bin/env bash
# ───────────────────────────────────────────────
# Saltyfunnel’s Hyprland One-Shot Installer
# Builds HyprYou and Greeter as proper packages
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
# Create temporary PKGBUILD for main HyprYou
create_hypryou_pkg() {
    echo "⚡ Creating temporary PKGBUILD for HyprYou..."
    TEMP_DIR="$CLONE_DIR/hypryou-pkg"
    mkdir -p "$TEMP_DIR"

    cat > "$TEMP_DIR/PKGBUILD" <<'EOF'
# Maintainer: Saltyfunnel
pkgname=hypryou
pkgver=1.0.0
pkgrel=1
pkgdesc="HyprYou - Main Hyprland Material You Package"
arch=('x86_64')
license=('GPL3')
depends=('gtk4' 'python' 'python-pillow')
source=()
sha256sums=()
package() {
    mkdir -p "$pkgdir/usr/lib/hypryou"
    cp -r ../hypryou/* "$pkgdir/usr/lib/hypryou/"
    cp -r ../hypryou-assets "$pkgdir/usr/share/hypryou/"
    install -Dm755 ../build/hypryouctl "$pkgdir/usr/bin/hypryouctl"
    install -Dm755 ../build/hypryou-start "$pkgdir/usr/bin/hypryou-start"
    install -Dm755 ../build/hypryou-crash-dialog "$pkgdir/usr/bin/hypryou-crash-dialog"
    install -Dm644 ../assets/hypryou.desktop "$pkgdir/usr/share/wayland-sessions/hypryou.desktop"
}
EOF
}

# ───────────────────────────────────────────────
# Build & install HyprYou via makepkg
build_main_pkg() {
    echo "🔧 Building main HyprYou package..."
    pushd "$CLONE_DIR/hypryou" >/dev/null
    ./build.sh || { echo "❌ Failed to build hypryou/"; exit 1; }
    popd >/dev/null

    pushd "$CLONE_DIR/build" >/dev/null
    ./build.sh || { echo "❌ Failed to build build/"; exit 1; }
    popd >/dev/null

    create_hypryou_pkg
    pushd "$CLONE_DIR/hypryou-pkg" >/dev/null
    makepkg -si --noconfirm || { echo "❌ Failed to build HyprYou package"; exit 1; }
    popd >/dev/null
}

# ───────────────────────────────────────────────
# Install optional greeter
install_greeter() {
    GREETER_DIR="$CLONE_DIR/greeter"
    if [[ -d "$GREETER_DIR" ]]; then
        echo "👋 Installing HyprYou Greeter..."
        pushd "$GREETER_DIR" >/dev/null
        makepkg -si --noconfirm || { echo "❌ Failed to build greeter"; popd >/dev/null; return; }
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

    build_main_pkg

    echo -e "\n⚠️ hypryou-utils is optional and must be installed manually with makepkg -si in hypryou-utils/"

    echo -n "👋 Install HyprYou Greeter (optional)? [y/N]: "
    read -r greeter_choice
    if [[ "$greeter_choice" =~ ^[Yy]$ ]]; then
        install_greeter
    fi

    echo -e "\n✅ Hyprland Material You installed successfully!"
    echo "→ You can now select 'HyprYou' in your display/login manager."
}

main "$@"
