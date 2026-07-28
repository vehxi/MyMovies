#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/MyMovies.xcodeproj"
SCHEME="My Movies"
BUILD_ROOT="${BUILD_ROOT:-$ROOT_DIR/build/release}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
DERIVED_DATA="$BUILD_ROOT/DerivedData"
STAGING_DIR="$BUILD_ROOT/dmg-root"
APP_PATH="$DERIVED_DATA/Build/Products/Release/My Movies.app"
VERSION="${VERSION:-}"
SIGNING_IDENTITY="${DEVELOPER_ID_APPLICATION:--}"

if [[ -z "$VERSION" ]]; then
    VERSION="$(
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -showBuildSettings |
        awk '/ MARKETING_VERSION = / { print $3; exit }'
    )"
fi

DMG_PATH="$DIST_DIR/MyMovies-$VERSION.dmg"

mkdir -p "$BUILD_ROOT" "$DIST_DIR"
rm -rf "$DERIVED_DATA" "$STAGING_DIR"

build_settings=(
    -project "$PROJECT_PATH"
    -scheme "$SCHEME"
    -configuration Release
    -destination "generic/platform=macOS"
    -derivedDataPath "$DERIVED_DATA"
    ARCHS="arm64 x86_64"
    ONLY_ACTIVE_ARCH=NO
    CODE_SIGN_STYLE=Manual
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY"
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO
)

if [[ "$SIGNING_IDENTITY" != "-" ]]; then
    if [[ -z "${APPLE_TEAM_ID:-}" ]]; then
        echo "APPLE_TEAM_ID is required for Developer ID signing." >&2
        exit 1
    fi
    build_settings+=(
        DEVELOPMENT_TEAM="$APPLE_TEAM_ID"
        OTHER_CODE_SIGN_FLAGS="--timestamp"
    )
fi

xcodebuild "${build_settings[@]}" clean build

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/My Movies.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "My Movies" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

if [[ "$SIGNING_IDENTITY" != "-" ]]; then
    codesign \
        --force \
        --timestamp \
        --sign "$SIGNING_IDENTITY" \
        "$DMG_PATH"
fi

if [[ -n "${APPLE_ID:-}" || -n "${APPLE_APP_PASSWORD:-}" ]]; then
    if [[ "$SIGNING_IDENTITY" == "-" ]]; then
        echo "Notarization requires DEVELOPER_ID_APPLICATION." >&2
        exit 1
    fi
    if [[ -z "${APPLE_ID:-}" || -z "${APPLE_APP_PASSWORD:-}" || -z "${APPLE_TEAM_ID:-}" ]]; then
        echo "APPLE_ID, APPLE_APP_PASSWORD, and APPLE_TEAM_ID are all required." >&2
        exit 1
    fi

    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --team-id "$APPLE_TEAM_ID" \
        --wait
    xcrun stapler staple "$DMG_PATH"
    xcrun stapler validate "$DMG_PATH"
fi

hdiutil verify "$DMG_PATH"
shasum -a 256 "$DMG_PATH"
echo "Created $DMG_PATH"
