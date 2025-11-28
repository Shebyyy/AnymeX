#!/usr/bin/env bash
set -e

OLD_PKG="$1"
NEW_PKG="$2"
NEW_APP_NAME="$3"
NEW_VERSION="$4"

if [ -z "$OLD_PKG" ] || [ -z "$NEW_PKG" ]; then
  echo "Usage: rename_app.sh OLD_PKG NEW_PKG NEW_APP_NAME NEW_VERSION"
  exit 1
fi

echo "🔄 Renaming package:"
echo "  OLD: $OLD_PKG"
echo "  NEW: $NEW_PKG"

OLD_DIR=$(echo "$OLD_PKG" | tr "." "/")
NEW_DIR=$(echo "$NEW_PKG" | tr "." "/")

###############################################
# ANDROID PACKAGE + NAMESPACE
###############################################
echo "➡️ Updating Gradle applicationId & namespace…"

find android -type f \( -name "build.gradle" -o -name "*.gradle" \) -print0 | while IFS= read -r -d $'\0' f; do
  sed -i "s|applicationId \".*\"|applicationId \"$NEW_PKG\"|g" "$f"
  sed -i "s|namespace \".*\"|namespace \"$NEW_PKG\"|g" "$f"
done

###############################################
# ANDROID MANIFEST
###############################################
echo "➡️ Updating AndroidManifest package…"

find android -type f -name "AndroidManifest.xml" -print0 | while IFS= read -r -d $'\0' f; do
  sed -i "s|package=\"${OLD_PKG}\"|package=\"${NEW_PKG}\"|g" "$f"
  sed -i "s|android:label=\"[^\"]*\"|android:label=\"$NEW_APP_NAME\"|g" "$f"
done

###############################################
# MOVE KOTLIN/JAVA SOURCE FOLDERS
###############################################
echo "➡️ Moving Kotlin/Java package folders…"

SRC="android/app/src/main/kotlin"
if [ -d "$SRC/$OLD_DIR" ]; then
  mkdir -p "$SRC/$NEW_DIR"
  mv "$SRC/$OLD_DIR"/* "$SRC/$NEW_DIR"/
  rm -rf "$SRC/${OLD_PKG%%.*}"
fi

# Replace package declaration inside source files
find android/app/src/main -type f \( -name "*.kt" -o -name "*.java" \) -exec \
  sed -i "s|package $OLD_PKG|package $NEW_PKG|g" {} +

###############################################
# iOS BUNDLE IDENTIFIER
###############################################
echo "➡️ Updating iOS bundle identifier…"

PBX="ios/Runner.xcodeproj/project.pbxproj"
if [ -f "$PBX" ]; then
  sed -i "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" "$PBX"
fi

###############################################
# FLUTTER APP NAME + VERSION
###############################################
echo "➡️ Updating pubspec.yaml…"

if [ -n "$NEW_APP_NAME" ]; then
  sed -i "s|name: .*|name: $(echo "$NEW_APP_NAME" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')|g" pubspec.yaml
fi

if [ -n "$NEW_VERSION" ]; then
  sed -i "s|version: .*|version: $NEW_VERSION|g" pubspec.yaml
fi

echo "🎉 Rename completed successfully!"
