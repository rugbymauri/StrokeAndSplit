#!/usr/bin/env bash
# Packs the Linux release bundle (`make build-linux`) into an AppImage.
#
#   tool/build_appimage.sh [VERSION]
#
# Writes build/appimage/${APP_NAME}-${VERSION}-x86_64.AppImage. VERSION defaults to the
# version name in pubspec.yaml. APP_NAME (binary and file name) and APPLICATION_ID are taken
# from the environment, so a rename only has to change them here, in CI and in CMakeLists.txt.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="${APP_NAME:-strokesplit}"
APPLICATION_ID="${APPLICATION_ID:-ch.strokesplit.strokesplit}"
VERSION="${1:-$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)}"

# Pinned tools, verified by checksum. appimagetool would otherwise fetch the latest runtime.
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage"
APPIMAGETOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"
RUNTIME_URL="https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64"
RUNTIME_SHA256="2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d"

BUNDLE="build/linux/x64/release/bundle"
WORK="build/appimage"
APPDIR="$WORK/$APP_NAME.AppDir"
OUTPUT="$WORK/$APP_NAME-$VERSION-x86_64.AppImage"
TOOLS="$WORK/tools"

if [[ ! -x "$BUNDLE/$APP_NAME" ]]; then
  echo "error: $BUNDLE/$APP_NAME not found, run 'make build-linux' first" >&2
  exit 1
fi

fetch() { # url sha256 target
  if [[ -f "$3" ]] && echo "$2  $3" | sha256sum --check --status; then
    return
  fi
  curl --fail --silent --show-error --location --output "$3.part" "$1"
  if ! echo "$2  $3.part" | sha256sum --check --status; then
    echo "error: checksum mismatch for $1" >&2
    exit 1
  fi
  mv "$3.part" "$3"
}

mkdir -p "$TOOLS"
fetch "$APPIMAGETOOL_URL" "$APPIMAGETOOL_SHA256" "$TOOLS/appimagetool"
fetch "$RUNTIME_URL" "$RUNTIME_SHA256" "$TOOLS/runtime-x86_64"
chmod +x "$TOOLS/appimagetool"

substitute() { # template target
  sed -e "s|@APP_NAME@|$APP_NAME|g" -e "s|@APPLICATION_ID@|$APPLICATION_ID|g" "$1" > "$2"
}

# Start from an empty AppDir so files of an earlier build don't end up in the package.
if [[ -d "$APPDIR" ]]; then
  find "$APPDIR" -mindepth 1 -delete
fi
mkdir -p "$APPDIR/usr/bin"
cp -a "$BUNDLE/." "$APPDIR/usr/bin/"
substitute linux/packaging/AppRun "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"
substitute linux/packaging/app.desktop.in "$APPDIR/$APP_NAME.desktop"
cp linux/packaging/icon.png "$APPDIR/$APP_NAME.png"
ln -sf "$APP_NAME.png" "$APPDIR/.DirIcon"

# Docker runners have no FUSE, so appimagetool runs extracted.
APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 "$TOOLS/appimagetool" --no-appstream \
  --runtime-file "$TOOLS/runtime-x86_64" "$APPDIR" "$OUTPUT"

echo "$OUTPUT"
