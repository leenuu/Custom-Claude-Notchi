#!/bin/bash
set -euo pipefail

# ─── Configuration ───
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCODE_PROJECT="$PROJECT_DIR/notchi/notchi.xcodeproj"
SCHEME="notchi"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="notchi"
APPCAST="$PROJECT_DIR/docs/appcast.xml"
GITHUB_REPO="leenuu/Custom-Claude-Notchi"

# ─── Parse arguments ───
VERSION=""
NOTES=""
while getopts "v:n:" opt; do
    case $opt in
        v) VERSION="$OPTARG" ;;
        n) NOTES="$OPTARG" ;;
        *) echo "Usage: $0 -v <version> [-n <release notes>]"; exit 1 ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo "Error: Version is required."
    echo "Usage: $0 -v <version> [-n <release notes>]"
    echo "Example: $0 -v 1.2.0 -n \"Weekly usage bar added\""
    exit 1
fi

if [ -z "$NOTES" ]; then
    NOTES="Release v$VERSION"
fi

echo "=== Building $APP_NAME v$VERSION ==="

# ─── Step 0: Ensure gh CLI is available ───
if ! command -v gh &>/dev/null; then
    echo "[0] gh CLI not found. Installing via Homebrew..."
    if ! command -v brew &>/dev/null; then
        echo "Error: Homebrew is required to install gh. Install from https://brew.sh"
        exit 1
    fi
    brew install gh
fi

if ! gh auth status &>/dev/null; then
    echo "[0] gh not authenticated. Starting login..."
    gh auth login
fi

# ─── Step 1: Update version in Xcode project ───
echo "[1/7] Updating version to $VERSION..."
PBXPROJ="$XCODE_PROJECT/project.pbxproj"
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION;/g" "$PBXPROJ"
echo "  MARKETING_VERSION → $VERSION"

# ─── Step 2: Build archive ───
echo "[2/7] Building archive..."
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
rm -rf "$ARCHIVE_PATH"

xcodebuild archive \
    -project "$XCODE_PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -quiet

echo "  Archive created at $ARCHIVE_PATH"

# ─── Step 3: Export app from archive ───
echo "[3/7] Exporting app..."
EXPORT_DIR="$BUILD_DIR/export"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi
cp -R "$APP_PATH" "$EXPORT_DIR/$APP_NAME.app"
echo "  App exported to $EXPORT_DIR/$APP_NAME.app"

# ─── Step 4: Create DMG ───
echo "[4/7] Creating DMG..."
DMG_PATH="$BUILD_DIR/${APP_NAME}-${VERSION}.dmg"
rm -f "$DMG_PATH"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$EXPORT_DIR/$APP_NAME.app" \
    -ov \
    -format UDZO \
    "$DMG_PATH" \
    -quiet

echo "  DMG created at $DMG_PATH"

# ─── Step 5: Sign DMG with Sparkle ───
echo "[5/7] Signing DMG with Sparkle..."
SPARKLE_SIGN="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*/artifacts/sparkle/Sparkle/bin/sign_update" -print -quit 2>/dev/null)"

ED_SIGNATURE=""
if [ -n "$SPARKLE_SIGN" ] && [ -x "$SPARKLE_SIGN" ]; then
    SIGN_OUTPUT=$("$SPARKLE_SIGN" "$DMG_PATH")
    # sign_update outputs: sparkle:edSignature="..." length="..."
    ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | sed 's/sparkle:edSignature="//;s/"//')
    echo "  Sparkle signature: $ED_SIGNATURE"
else
    echo "  Warning: Sparkle sign_update not found. Skipping signing."
    echo "  Build Sparkle in Xcode first, then re-run."
fi

# ─── Step 6: Update appcast.xml ───
echo "[6/7] Updating appcast.xml..."
DMG_SIZE=$(stat -f%z "$DMG_PATH")
PUB_DATE=$(date -R)
DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/v$VERSION/${APP_NAME}-${VERSION}.dmg"

SIGNATURE_ATTR=""
if [ -n "$ED_SIGNATURE" ]; then
    SIGNATURE_ATTR="sparkle:edSignature=\"$ED_SIGNATURE\""
fi

NEW_ITEM="        <item>
            <title>$VERSION</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:version>$VERSION</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
            <enclosure url=\"$DOWNLOAD_URL\" length=\"$DMG_SIZE\" type=\"application/octet-stream\" $SIGNATURE_ATTR/>
            <sparkle:hardwareRequirements>arm64</sparkle:hardwareRequirements>
        </item>"

# Insert new item before the first existing <item>
sed -i '' "/<item>/i\\
$(echo "$NEW_ITEM" | sed 's/$/\\/' | sed '$ s/\\$//')
" "$APPCAST"

# Remove duplicate blank lines
sed -i '' '/^$/N;/^\n$/d' "$APPCAST"

echo "  appcast.xml updated with v$VERSION"
echo "  Download URL: $DOWNLOAD_URL"

# ─── Step 7: Create GitHub release ───
echo "[7/7] Creating GitHub release..."
gh release create "v$VERSION" \
    "$DMG_PATH" \
    --repo "$GITHUB_REPO" \
    --title "v$VERSION" \
    --notes "$NOTES" \
    --latest

echo "  GitHub release v$VERSION created with DMG uploaded"

# ─── Cleanup ───
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"

echo ""
echo "=== Done! ==="
echo "DMG: $DMG_PATH"
echo "Version: $VERSION"
echo "Release: https://github.com/$GITHUB_REPO/releases/tag/v$VERSION"
