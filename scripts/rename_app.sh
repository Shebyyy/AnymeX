#!/usr/bin/env bash
set -e

###############################################
# CROSS PLATFORM SAFE RENAME & ICON SCRIPT
# Works on: Linux, macOS (bash 3.2), Windows
# NO associative arrays, NO convert.exe issues
###############################################

# Color helpers
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
log() { echo -e "${GREEN}➡${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }
success() { echo -e "${GREEN}✔${NC} $1"; }

# Detect sed inline flag
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_I=(-i '')
else
  SED_I=(-i)
fi

# Detect ImageMagick binary (avoid Windows convert.exe)
if [ "$RUNNER_OS" = "Windows" ]; then
  CONVERT_BIN="magick"
else
  CONVERT_BIN="convert"
fi

###############################################
# VALIDATE INPUT
###############################################
if [ -z "$1" ]; then
  error "Usage: $0 <new_version>"
fi
NEW_VERSION="$1"

OLD_PKG="com.ryan.anymex"
NEW_PKG="com.ryan.anymexbeta"

OLD_APP_NAME="AnymeX"
NEW_APP_NAME="AnymeX β"

BASE_ICON="assets/images/logo.png"
BETA_ICON="assets/images/logo_beta.png"

BASE_TRANSPARENT="assets/images/logo_transparent.png"
BETA_TRANSPARENT="assets/images/logo_transparent_beta.png"

###############################################
# PRINT HEADER
###############################################
echo "════════════════════════════════════════════"
echo "  CROSS-PLATFORM RENAME START"
echo "════════════════════════════════════════════"
echo "  Version: $NEW_VERSION"
echo "════════════════════════════════════════════"

###############################################
# ANDROID CONFIG
###############################################
if [ -d "android" ]; then
  log "ANDROID: Updating configuration..."

  BUILD_GRADLE=""
  if [ -f "android/app/build.gradle.kts" ]; then
    BUILD_GRADLE="android/app/build.gradle.kts"
  elif [ -f "android/app/build.gradle" ]; then
    BUILD_GRADLE="android/app/build.gradle"
  fi

  if [ -n "$BUILD_GRADLE" ]; then
    sed "${SED_I[@]}" "s|applicationId .*|applicationId \"$NEW_PKG\"|g" "$BUILD_GRADLE"
    sed "${SED_I[@]}" "s|namespace .*|namespace \"$NEW_PKG\"|g" "$BUILD_GRADLE"
  fi

  sed "${SED_I[@]}" "s|android:label=\"$OLD_APP_NAME\"|android:label=\"$NEW_APP_NAME\"|g" android/app/src/main/AndroidManifest.xml || true

  # Update Kotlin package folder
  if [ -d "android/app/src/main/kotlin/com/ryan/anymex" ]; then
    mkdir -p android/app/src/main/kotlin/com/ryan/anymexbeta
    find android/app/src/main/kotlin/com/ryan/anymex -type f -name "*.kt" \
      -exec sed "${SED_I[@]}" "s|package $OLD_PKG|package $NEW_PKG|g" {} \;
    cp -r android/app/src/main/kotlin/com/ryan/anymex/* android/app/src/main/kotlin/com/ryan/anymexbeta/
    rm -rf android/app/src/main/kotlin/com/ryan/anymex
  fi

  success "Android updated"
fi

###############################################
# iOS CONFIG
###############################################
if [ -d "ios" ]; then
  log "iOS: Updating configuration..."

  sed "${SED_I[@]}" "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" ios/Runner.xcodeproj/project.pbxproj || true
  sed "${SED_I[@]}" "s|<string>$OLD_APP_NAME</string>|<string>$NEW_APP_NAME</string>|g" ios/Runner/Info.plist || true

  success "iOS updated"
fi

###############################################
# macOS CONFIG
###############################################
if [ -d "macos" ]; then
  log "macOS: Updating configuration..."

  sed "${SED_I[@]}" "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" macos/Runner/Configs/AppInfo.xcconfig || true
  sed "${SED_I[@]}" "s|<string>$OLD_APP_NAME</string>|<string>$NEW_APP_NAME</string>|g" macos/Runner/Info.plist || true

  success "macOS updated"
fi

###############################################
# WINDOWS CONFIG
###############################################
if [ -d "windows" ]; then
  log "Windows: Updating configuration..."

  sed "${SED_I[@]}" "s|anymex\"|anymex_beta\"|g" windows/runner/Runner.rc || true
  sed "${SED_I[@]}" "s|AnymeX|AnymeX β|g" windows/runner/Runner.rc || true

  success "Windows updated"
fi

###############################################
# LINUX CONFIG
###############################################
if [ -d "linux" ]; then
  log "Linux: Updating configuration..."

  sed "${SED_I[@]}" "s|\"AnymeX\"|\"AnymeX β\"|g" linux/my_application.cc || true

  success "Linux updated"
fi

###############################################
# OVERRIDE LOGOS
###############################################
log "Applying Beta Logos..."

if [ -f "$BETA_ICON" ]; then cp "$BETA_ICON" "$BASE_ICON"; fi
if [ -f "$BETA_TRANSPARENT" ]; then cp "$BETA_TRANSPARENT" "$BASE_TRANSPARENT"; fi

success "Logos replaced"

###############################################
# ANDROID ICON GENERATION (SAFE)
###############################################
log "Generating Android mipmaps..."

DPI_ENTRIES=(
  "mipmap-mdpi:48"
  "mipmap-hdpi:72"
  "mipmap-xhdpi:96"
  "mipmap-xxhdpi:144"
  "mipmap-xxxhdpi:192"
)

for entry in "${DPI_ENTRIES[@]}"; do
  FOLDER=$(echo "$entry" | cut -d":" -f1)
  SIZE=$(echo "$entry" | cut -d":" -f2)
  DEST="android/app/src/main/res/$FOLDER"

  if [ -d "$DEST" ]; then
    log "Android: $FOLDER ($SIZE px)"
    "$CONVERT_BIN" "$BASE_ICON" -resize "${SIZE}x${SIZE}" "$DEST/ic_launcher.png"
    "$CONVERT_BIN" "$BASE_ICON" -resize "${SIZE}x${SIZE}" "$DEST/ic_rounded_launcher.png"
  fi
done

success "Android icons generated"

###############################################
# iOS / MACOS ICONS (ONLY IF FOLDERS EXIST)
###############################################
if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
  log "Generating iOS icons..."
  for size in 20 29 40 60 76 83.5 1024; do
    "$CONVERT_BIN" "$BASE_ICON" -resize "${size}x${size}" \
      "ios/Runner/Assets.xcassets/AppIcon.appiconset/${size}.png"
  done
  success "iOS icons generated"
fi

if [ -d "macos/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
  log "Generating macOS icons..."
  for size in 16 32 64 128 256 512 1024; do
    "$CONVERT_BIN" "$BASE_ICON" -resize "${size}x${size}" \
      "macos/Runner/Assets.xcassets/AppIcon.appiconset/${size}.png"
  done
  success "macOS icons generated"
fi

###############################################
# WINDOWS ICO (SAFE)
###############################################
if [ -d "windows/runner/resources" ]; then
  log "Generating Windows ICO..."
  "$CONVERT_BIN" "$BASE_ICON" -define ico:bits=32 \
    -resize 256x256 windows/runner/resources/app_icon.ico
  success "Windows ICO generated"
fi

###############################################
# CLEAN
###############################################
log "Cleaning Flutter cache..."
flutter clean >/dev/null 2>&1 || true

success "All done!"

echo ""
echo "════════════════════════════════════════════"
success "CROSS-PLATFORM RENAME COMPLETE!"
echo "════════════════════════════════════════════"
