#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Package the iphoneos/15.1 SOFTWARE-renderer runtime for Andarium into the
# XCFrameworks the Xcode project expects, under .build/kernarium-xcframeworks.
#
# Unlike the upstream package-ios-frameworks.sh, the device stack here renders
# on Mesa llvmpipe/softpipe (no Vulkan, no KosmicKrisp, no Metal 4), because
# Metal 4 is unavailable on iOS 15. Consequently:
#   - MesaEGL/MesaGallium XCFrameworks carry the device slice from the
#     ios-device-software-arm64 GPU prefix.
#   - KosmicKrisp.xcframework is NOT produced (the app embeds it optionally).
#   - The Android runtime framework is taken from the ios15-device build tree.
#   - A verification of the software prefix runs before anything is packaged.
#
# Offline: consumes only prefixes/frameworks already built by the deps and
# runtime build steps. It does not download or sign anything.
set -eu

fail() { printf '%s\n' "package-ios15-frameworks.sh: $*" >&2; exit 1; }

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

find_tool()
{
	variable=$1; shift
	for candidate in "$@"; do
		tool_path=$(command -v "$candidate" 2>/dev/null || true)
		if [ -n "$tool_path" ]; then
			eval "$variable=\$tool_path"; return
		fi
	done
	fail "required packaging tool is unavailable: $*"
}
find_tool XCODEBUILD xcodebuild
find_tool STRIP strip
find_tool DSYMUTIL dsymutil

OUTPUT=${KERNARIUM_XCFRAMEWORK_OUTPUT:-"$ROOT_DIR/.build/kernarium-xcframeworks"}
GPU_PREFIX=${KERNARIUM_IOS15_GPU_PREFIX:-"$ROOT_DIR/.build/dependencies/apple-gpu-vulkan-experiment/ios-device-software-arm64"}
RUNTIME_TREE=${KERNARIUM_IOS15_RUNTIME_TREE:-"$ROOT_DIR/.build/kernarium-runtime-ios15-device-android"}
RUNTIME_FRAMEWORK_NAME=KRuntime_Android_6_18_4K
RUNTIME_FRAMEWORK="$RUNTIME_TREE/Kernarium/Runtime/$RUNTIME_FRAMEWORK_NAME.framework"
PRIVACY_MANIFESTS="$ROOT_DIR/Kernarium/PrivacyManifests"
GL_FRAMEWORKS="MesaEGL MesaGallium"
# Independently built static XCFrameworks the app also embeds.
STORAGE_XCF="$ROOT_DIR/.build/dependencies/ios-storage/GPTFDisk.xcframework"
ZSTD_XCF="$ROOT_DIR/.build/dependencies/ios-zstd/LibZstd.xcframework"

[ -d "$GPU_PREFIX/Frameworks" ] || fail "missing GPU prefix Frameworks: $GPU_PREFIX"
[ -d "$RUNTIME_FRAMEWORK" ] || fail "missing runtime framework: $RUNTIME_FRAMEWORK"
[ -d "$STORAGE_XCF" ] || fail "missing storage XCFramework: $STORAGE_XCF"
[ -d "$ZSTD_XCF" ] || fail "missing zstd XCFramework: $ZSTD_XCF"

# Re-verify the software GPU prefix against its device+software contract before
# consuming it. The build script names this platform "ios-software".
"$ROOT_DIR/dependencies/build-apple-gpu.sh" --platform ios-software \
	--prefix "$GPU_PREFIX" --verify-only ||
	fail "iOS 15.1 software GPU prefix failed verification"

OUTPUT_PARENT=$(CDPATH= cd -- "$(dirname -- "$OUTPUT")" && pwd -P)
OUTPUT="$OUTPUT_PARENT/$(basename -- "$OUTPUT")"
STAGE=$(mktemp -d "$OUTPUT_PARENT/.kernarium-xcframeworks.XXXXXX")
cleanup()
{
	[ -z "${STAGE:-}" ] || [ ! -d "$STAGE" ] || rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

create_device_xcframework()
{
	name=$1 framework_path=$2
	[ -d "$framework_path" ] || fail "missing framework: $framework_path"
	dSYM="$framework_path.dSYM"
	if [ ! -d "$dSYM" ]; then
		# The runtime CMake POST_BUILD dsymutil step only runs when the
		# framework is relinked. On a cached build the framework can be
		# present without its dSYM, so regenerate it here (the upstream
		# package-ios-frameworks.sh does the same for its AOT framework).
		binary="$framework_path/$name"
		if [ -f "$binary" ]; then
			"$DSYMUTIL" "$binary" -o "$dSYM" 2>/dev/null || true
		fi
	fi
	if [ -d "$dSYM" ]; then
		"$XCODEBUILD" -create-xcframework \
			-framework "$framework_path" -debug-symbols "$dSYM" \
			-output "$STAGE/$name.xcframework" ||
			fail "could not create $name XCFramework"
	else
		# -debug-symbols is optional; a stripped binary has no usable DWARF.
		# Package without dSYM rather than blocking the whole IPA build.
		printf '%s\n' \
			"package-ios15-frameworks.sh: warning: no dSYM for $name; packaging without debug symbols" >&2
		"$XCODEBUILD" -create-xcframework \
			-framework "$framework_path" \
			-output "$STAGE/$name.xcframework" ||
			fail "could not create $name XCFramework"
	fi
	[ -f "$STAGE/$name.xcframework/Info.plist" ] ||
		fail "$name XCFramework was not created"
}

# The runtime framework's dSYM sits beside the framework in the runtime tree.
create_device_xcframework "$RUNTIME_FRAMEWORK_NAME" "$RUNTIME_FRAMEWORK"
for framework in $GL_FRAMEWORKS; do
	create_device_xcframework "$framework" "$GPU_PREFIX/Frameworks/$framework.framework"
done

# Install privacy manifests and strip debug maps, matching the upstream rules.
install_privacy_manifest()
{
	for slice_framework in "$STAGE/$1.xcframework"/*/"$1.framework"; do
		[ -d "$slice_framework" ] || fail "$1 XCFramework has no framework slice"
		[ -f "$PRIVACY_MANIFESTS/$2.xcprivacy" ] ||
			fail "missing privacy manifest: $PRIVACY_MANIFESTS/$2.xcprivacy"
		cp -- "$PRIVACY_MANIFESTS/$2.xcprivacy" \
			"$slice_framework/PrivacyInfo.xcprivacy" ||
			fail "could not install the privacy manifest of $1"
	done
}
for framework in $GL_FRAMEWORKS; do
	install_privacy_manifest "$framework" "$framework"
done
install_privacy_manifest "$RUNTIME_FRAMEWORK_NAME" KRuntime

strip_debug_maps()
{
	for stripped_framework in "$@"; do
		for slice_framework in "$STAGE/$stripped_framework.xcframework"/*/"$stripped_framework.framework"; do
			[ -f "$slice_framework/$stripped_framework" ] ||
				fail "$stripped_framework XCFramework has no binary"
			"$STRIP" -S "$slice_framework/$stripped_framework" ||
				fail "could not strip the debug map of $slice_framework"
		done
	done
}
strip_debug_maps "$RUNTIME_FRAMEWORK_NAME" $GL_FRAMEWORKS

# Copy the independently built static XCFrameworks verbatim.
cp -R -- "$STORAGE_XCF" "$STAGE/GPTFDisk.xcframework" ||
	fail "could not copy GPTFDisk.xcframework"
cp -R -- "$ZSTD_XCF" "$STAGE/LibZstd.xcframework" ||
	fail "could not copy LibZstd.xcframework"

# Publish atomically: replace the output directory only after all slices pass.
rm -rf -- "$OUTPUT"
mv -- "$STAGE" "$OUTPUT"
STAGE=
printf '%s\n' "Packaged iOS 15.1 software-renderer frameworks into $OUTPUT"
for framework in "$RUNTIME_FRAMEWORK_NAME" $GL_FRAMEWORKS; do
	printf '  - %s.xcframework\n' "$framework"
done
