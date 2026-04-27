#!/usr/bin/env bash
# Surf Pick — full rebuild script
#
# Wipes build artifacts and rebuilds the project from source.
# Use this when:
#   - Xcode caches are giving stale errors
#   - You've changed the SurfShared package and want a clean rebuild
#   - You're handing off to a new machine or fresh checkout
#
# It does NOT touch:
#   - Source files (everything in /Users/user/SurfPick and /Users/user/SurfShared)
#   - The Xcode project file (.xcodeproj)
#   - The watchOS app at /Users/user/surfcheck (that's a separate project)
#
# Usage: ./rebuild.sh

set -euo pipefail

PROJECT_ROOT="/Users/user/SurfPick"
SHARED_PACKAGE="/Users/user/SurfShared"
XCODE_DIR="${PROJECT_ROOT}/SurfPick"
XCODEPROJ="${XCODE_DIR}/SurfPick.xcodeproj"

echo "=========================================="
echo "Surf Pick rebuild"
echo "=========================================="

# 1. Sanity checks
if [[ ! -d "${PROJECT_ROOT}" ]]; then
  echo "❌ Project folder not found at ${PROJECT_ROOT}"
  exit 1
fi
if [[ ! -d "${SHARED_PACKAGE}" ]]; then
  echo "❌ SurfShared package not found at ${SHARED_PACKAGE}"
  exit 1
fi
if [[ ! -d "${XCODEPROJ}" ]]; then
  echo "⚠️  Xcode project not found at ${XCODEPROJ}"
  echo "   You haven't created the Xcode project yet. See CLAUDE.md → 'Initial Xcode setup'."
  exit 1
fi

echo "✅ Project structure looks correct"
echo ""

# 2. Clean DerivedData for SurfPick & SurfShared
echo "🧹 Wiping Xcode DerivedData for SurfPick and SurfShared..."
DERIVED="${HOME}/Library/Developer/Xcode/DerivedData"
if [[ -d "${DERIVED}" ]]; then
  rm -rf "${DERIVED}"/SurfPick-* 2>/dev/null || true
  rm -rf "${DERIVED}"/SurfShared-* 2>/dev/null || true
  echo "   Done."
else
  echo "   No DerivedData folder found (fresh machine?), skipping."
fi
echo ""

# 3. Clean SwiftPM build cache
echo "🧹 Wiping SwiftPM caches..."
rm -rf "${PROJECT_ROOT}/.build" 2>/dev/null || true
rm -rf "${SHARED_PACKAGE}/.build" 2>/dev/null || true
rm -rf "${SHARED_PACKAGE}/.swiftpm" 2>/dev/null || true
echo "   Done."
echo ""

# 4. Build SurfShared package standalone first to catch package errors early
echo "🔨 Building SurfShared package for iOS..."
cd "${SHARED_PACKAGE}"
if xcodebuild -scheme SurfShared -destination 'generic/platform=iOS' build 2>&1 | tail -3 | grep -q "BUILD SUCCEEDED"; then
  echo "   ✅ SurfShared builds cleanly."
else
  echo "   ❌ SurfShared build failed. Run 'cd ${SHARED_PACKAGE} && xcodebuild -scheme SurfShared -destination generic/platform=iOS build' for details."
  exit 1
fi
echo ""

# 5. Build the SurfPick app
echo "🔨 Building SurfPick app for iOS..."
cd "${XCODE_DIR}"
BUILD_OUTPUT=$(xcodebuild -project SurfPick.xcodeproj -scheme SurfPick -destination 'generic/platform=iOS' -configuration Debug build 2>&1 | tail -10)
if echo "${BUILD_OUTPUT}" | grep -q "BUILD SUCCEEDED"; then
  echo "   ✅ SurfPick builds cleanly."
else
  echo "   ❌ SurfPick build failed. Last lines of output:"
  echo "${BUILD_OUTPUT}"
  exit 1
fi
echo ""

# 6. Done
echo "=========================================="
echo "✅ Rebuild complete."
echo "=========================================="
echo ""
echo "Next: open Xcode and ⌘R to run on iPhone."
echo "  open ${XCODEPROJ}"
