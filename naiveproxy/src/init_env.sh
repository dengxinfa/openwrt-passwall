#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org
# --------------------------------------------------------
# Init build dependencies for naiveproxy

# Read args from shell
target_arch="$1"
target_board="$2"
cpu_type="$3"
cpu_subtype="$4"
toolchain_dir="$5"

# Set arch info
naive_arch="${target_arch}"
[ "${target_arch}" == "i386" ] && naive_arch="x86"
[ "${target_arch}" == "x86_64" ] && naive_arch="x64"
[ "${target_arch}" == "aarch64" ] && naive_arch="arm64"
# ldso_path="/lib/$(find "${toolchain_dir}/" | grep -Eo "ld-musl-[a-z0-9_-]+\\.so\\.1")"

# OS detection
[ "$(uname)" != "Linux" -o "$(uname -m)" != "x86_64" ] && { echo -e "Support Linux AMD64 only."; exit 1; }

# Create TMP dir
mkdir -p "$PWD/tmp"
export TMPDIR="$PWD/tmp"

# Set ENV
export DEPOT_TOOLS_WIN_TOOLCHAIN=0
export naive_flags="
is_official_build=true
exclude_unwind_tables=true
enable_resource_allowlist_generation=false
symbol_level=0
is_clang=true
use_sysroot=false

use_allocator=\"none\"
use_allocator_shim=false

fatal_linker_warnings=false
treat_warnings_as_errors=false

enable_base_tracing=false
use_udev=false
use_aura=false
use_ozone=false
use_x11=false
use_gio=false
use_platform_icu_alternatives=true
use_glib=false

disable_file_support=true
enable_websockets=false
disable_ftp_support=true
use_kerberos=false
enable_mdns=false
enable_reporting=false
include_transport_security_state_preload_list=false

target_os=\"openwrt\"
target_cpu=\"${naive_arch}\"
target_sysroot=\"${toolchain_dir}\""
# ldso_path=\"${ldso_path}\""
[ "${target_arch}" == "arm" ] && {
	naive_flags="${naive_flags} arm_version=0 arm_cpu=\"${cpu_type}\""
	if [ -n "${cpu_subtype}" ]; then
		echo "${cpu_subtype}" | grep -q "neon" && neon_flag="arm_use_neon=true" || neon_flag="arm_use_neon=false"
		naive_flags="${naive_flags} arm_fpu=\"${cpu_subtype}\" arm_float_abi=\"hard\" ${neon_flag}"
	else
		naive_flags="${naive_flags} arm_float_abi=\"soft\" arm_use_neon=false"
	fi
}
[[ "mips mips64 mipsel mips64el" =~ (^|[[:space:]])"${target_arch}"($|[[:space:]]) ]] && {
	naive_flags="${naive_flags} use_gold=false is_cfi=false use_cfi_icall=false use_thin_lto=false mips_arch_variant=\"r2\""
	[[ "${target_arch}" =~ ^"mips"$|^"mipsel"$ ]] && naive_flags="${naive_flags} mips_float_abi=\"double\" mips_tune=\"${cpu_type}\""
}
