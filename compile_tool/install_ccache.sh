#!/usr/bin/env bash
set -euo pipefail

DEFAULT_SIZE="5G"
CCACHE_DIR="${CCACHE_DIR:-$HOME/.cache/ccache}"
LOCAL_BIN="${HOME}/.local/bin"
SYMLINKS=(gcc g++ cc c++ clang clang++)

usage(){
  cat <<EOF
Usage: $0 [--size SIZE] [--no-symlinks]
  --size SIZE      Set ccache maximum cache size (default ${DEFAULT_SIZE})
  --no-symlinks    Do not create compiler symlinks in ${HOME}/.local/bin
EOF
  exit 1
}

OPT_SIZE="${DEFAULT_SIZE}"
DO_SYMLINKS=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --size) OPT_SIZE="$2"; shift 2;;
    --no-symlinks) DO_SYMLINKS=0; shift;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

msg(){ echo -e "[install_ccache] $*"; }

has_cmd(){ command -v "$1" >/dev/null 2>&1; }

install_via_pm(){
  if has_cmd apt-get; then
    msg "Using apt to install ccache"
    sudo apt-get update && sudo apt-get install -y ccache
    return 0
  fi
  if has_cmd dnf; then
    msg "Using dnf to install ccache"
    sudo dnf install -y ccache
    return 0
  fi
  if has_cmd yum; then
    msg "Using yum to install ccache"
    sudo yum install -y ccache
    return 0
  fi
  if has_cmd pacman; then
    msg "Using pacman to install ccache"
    sudo pacman -Syu --noconfirm ccache
    return 0
  fi
  if has_cmd zypper; then
    msg "Using zypper to install ccache"
    sudo zypper install -y ccache
    return 0
  fi
  if has_cmd apk; then
    msg "Using apk to install ccache"
    sudo apk add ccache
    return 0
  fi
  return 1
}

build_from_source(){
  TMP_SRC=$(mktemp -d)
  TMP_BUILD=$(mktemp -d)
  msg "Building ccache from source (requires git, cmake, make, a compiler)"
  if ! has_cmd git || ! has_cmd cmake || ! has_cmd make; then
    msg "Missing build tools: ensure git, cmake and make are installed"
    return 1
  fi
  git clone --depth 1 https://github.com/ccache/ccache.git "$TMP_SRC"
  cmake -S "$TMP_SRC" -B "$TMP_BUILD" -DCMAKE_BUILD_TYPE=Release
  cmake --build "$TMP_BUILD" -j"$(nproc)"
  msg "Installing ccache (may require sudo)"
  sudo cmake --install "$TMP_BUILD"
  rm -rf "$TMP_SRC" "$TMP_BUILD"
}

ensure_ccache(){
  if has_cmd ccache; then
    msg "ccache already installed: $(ccache --version | head -n1)"
    return 0
  fi

  if install_via_pm; then
    if has_cmd ccache; then
      msg "Installed ccache via package manager"
      return 0
    fi
  fi

  msg "Package manager install failed or not available, trying to build from source"
  if build_from_source; then
    if has_cmd ccache; then
      msg "Built and installed ccache"
      return 0
    fi
  fi
  return 1
}

init_ccache(){
  mkdir -p "$CCACHE_DIR"
  msg "Setting ccache dir: $CCACHE_DIR"
  export CCACHE_DIR="$CCACHE_DIR"

  msg "Setting max cache size to ${OPT_SIZE}"
  ccache -M "${OPT_SIZE}"

  msg "Current ccache stats:"
  ccache -s || true

  if [[ $DO_SYMLINKS -eq 1 ]]; then
    mkdir -p "$LOCAL_BIN"
    CCACHE_PATH="$(command -v ccache)"
    for name in "${SYMLINKS[@]}"; do
      ln -sf "$CCACHE_PATH" "$LOCAL_BIN/$name"
    done
    # ensure PATH contains LOCAL_BIN
    if ! echo "$PATH" | tr ':' '\n' | grep -xq "$LOCAL_BIN"; then
      ADDED=0
      for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]]; then
          if ! grep -Fq "export PATH=\"$LOCAL_BIN:\$PATH\"" "$rc" 2>/dev/null; then
            echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >> "$rc"
            msg "Added $LOCAL_BIN to PATH in $rc"
            ADDED=1
          fi
        fi
      done
      if [[ $ADDED -eq 0 ]]; then
        msg "Please add '$LOCAL_BIN' to your PATH manually (e.g. export PATH=\"$LOCAL_BIN:\$PATH\")"
      fi
    fi
    msg "Created symlinks in $LOCAL_BIN. Ensure it's in your PATH."
  else
    msg "Skipping symlink creation as requested"
  fi
}

main(){
  if [[ "$(uname -s)" != "Linux" ]]; then
    msg "This script currently supports Linux only. Exiting."
    exit 1
  fi

  if ! ensure_ccache; then
    echo "Failed to install ccache. Aborting." >&2
    exit 2
  fi

  init_ccache
  msg "Done. Run 'ccache -s' to view statistics. To use ccache wrappers, restart your shell or ensure ${LOCAL_BIN} is in PATH."
}

main "$@"
