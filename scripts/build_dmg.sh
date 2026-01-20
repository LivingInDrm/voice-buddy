#!/bin/bash

# Configuration
APP_NAME="Voice Studio"
SCHEME="VoiceStudio"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
EXPORT_OPTIONS="ExportOptions.plist"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "🚀 Starting build process for $APP_NAME..."

# 1. Archive
echo "📦 Archiving..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=macOS' \
    -quiet || { echo "❌ Archive failed"; exit 1; }

# 2. Export
echo "📤 Exporting .app..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -quiet || { echo "❌ Export failed"; exit 1; }

APP_PATH="$EXPORT_PATH/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Exported app not found at $APP_PATH"
    exit 1
fi

echo "✅ App exported to: $APP_PATH"

# 3. Create DMG
echo "💿 Creating DMG..."
# Create a temporary directory for DMG contents
DMG_SRC="$BUILD_DIR/dmg_source"
rm -rf "$DMG_SRC"
mkdir -p "$DMG_SRC"

# Copy app to DMG source
cp -r "$APP_PATH" "$DMG_SRC/"

# Create link to Applications folder
ln -s /Applications "$DMG_SRC/Applications"

# Create DMG using hdiutil
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_SRC" \
    -ov -format UDZO \
    "$DMG_PATH" \
    -quiet || { echo "❌ DMG creation failed"; exit 1; }

# Clean up Export directory to avoid path confusion
# (Only keep the app in dmg_source to ensure consistent path for testing)
rm -rf "$EXPORT_PATH"

echo "🎉 Build complete!"
echo "📂 DMG location: $DMG_PATH"
echo "📂 App location: $DMG_SRC/$APP_NAME.app"

# Optional: Notarization instructions
echo ""
echo "⚠️  Note: To distribute this DMG to users without 'Malware' warnings, you should notarize it."
echo "   Run the following command manually:"
echo "   xcrun notarytool submit \"$DMG_PATH\" --apple-id YOUR_EMAIL --team-id UM84M3QTSD --password APP_SPECIFIC_PASSWORD --wait"
echo "   xcrun stapler staple \"$DMG_PATH\""
