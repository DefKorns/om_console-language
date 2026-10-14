#!/bin/sh
# shellcheck disable=SC2154,SC1091,SC1090,SC3043,SC2034
#  Copyright (c) 2026 DefKorns (https://defkorns.github.io/LICENSE)
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Usage: console_language.sh apply <code> | state <code|patches> | revert | get | patches
. "$mountpoint/etc/options_menu/scripts/om_functions"
cl_lib=1
. "$preinitpath/p8020_console_language"
cl_init

# writes go through "/" ($cl_home); the preinit reads the same files from $rootfs ($cl_dir)
cl_home="$options_menu/console_language"
cl_urls="http://hakchicloud.com/Hakchi_Themes/options_menu http://classicmods.net/Hakchi_Themes/options_menu"
cl_ips="$cl_home/patches_ips"

# code:native_name, "_" for spaces; packs are built from language_pack/<pack>/<code>
cl_catalog() {
  case "$cl_pack" in
  shonen) echo "as_id:Bahasa_Indonesia cst_cw:Spurdo eur_gr:Ελληνικά eur_nor:Norsk eur_swe:Svenska" ;;
  nes) echo "eur_swe:Svenska" ;;
  snes) echo "eur_gr:Ελληνικά eur_nor:Norsk eur_swe:Svenska por_br:Português_(Brasil)" ;;
  esac
}

cl_available() {
  local builtin
  if [ -f "$cl_dir/custom/$1/strings.lng" ] || [ -d "$cl_dir/custom/$1/strings" ]; then
    return 0
  fi
  builtin="$(cl_builtin "$1")" && [ -f "$builtin" ]
}

cl_apply() {
  if ! cl_available "$1"; then
    translate CL_NOT_FOUND
    exit 1
  fi
  translate CL_APPLYING
  cl_umount_lang
  echo "$1" >"$cl_home/active.$cl_system"
  cl_init
  cl_mount_lang
  translate CL_APPLIED
}

cl_state() {
  if [ "$1" = "patches" ] && [ -f "$cl_dir/patches.$cl_system" ]; then
    echo 1
  elif [ "$1" != "patches" ] && [ "$cl_code" = "$1" ]; then
    echo 1
  else
    echo 0
  fi
}

cl_revert() {
  translate CL_REVERTING
  cl_umount_lang
  rm -f "$cl_home/active.$cl_system"
  translate CL_REVERTED
}

cl_fetch() {
  local url
  local pkg
  pkg="/tmp/cl_$(basename "$1")"
  for url in $cl_urls; do
    if wget -q -O "$pkg" "$url/$1" && tar -xzf "$pkg" -C "$2"; then
      rm -f "$pkg"
      return 0
    fi
  done
  rm -f "$pkg"
  return 1
}

cl_get() {
  local entry
  local code
  local cmd
  local n=100
  translate CL_DOWNLOADING
  for entry in $(cl_catalog); do
    code="${entry%%:*}"
    cl_fetch "customlangs/$cl_pack-$code.tar.gz" "$cl_home" || {
      netChecker
      exit 1
    }
    cmd="$cl_home/commands/c0${n}_$code"
    printf '%s\n' \
      "COMMAND_NAME=$(echo "${entry#*:}" | tr '_' ' ')" \
      "COMMAND_TYPE=INTERNAL" \
      "COMMAND_STR=sh %script_dir%/console_language.sh apply $code" \
      "STATE_STR=sh %script_dir%/console_language.sh state $code" >"$cmd"
    [ -f "$cl_home/images/$code.png" ] && echo "PREVIEW_IMAGE=/etc/options_menu/console_language/images/$code.png" >>"$cmd"
    n=$((n + 1))
  done
  translate CL_DOWNLOADED
}

# RetroArch soft-patches <rom>.ips next to the rom (NES) and, for roms unpacked
# to /tmp/rom, copies any .ips from <roms>/<ID>/<ID> (SNES); the overlay puts them there
cl_ips_tree() {
  local f
  local id
  local upper="$cl_home/ips_overlay/$cl_system"
  rm -rf "$upper"
  for f in "$cl_ips"/*.ips; do
    id="${f##*/}"
    id="${id%%.*}"
    [ -d "$cl_roms/$id" ] || continue
    case "$sftype" in
    snes)
      mkdir -p "$upper/$id/$id"
      ln -sf "$f" "$upper/$id/$id/${f##*/}"
      ;;
    *)
      mkdir -p "$upper/$id"
      ln -sf "$f" "$upper/$id/$id.ips"
      ;;
    esac
  done
}

# toggle; each pack is fetched once
cl_patches() {
  local tmp="/tmp/cl_patches"
  if [ -f "$cl_dir/patches.$cl_system" ]; then
    cl_umount_patches
    rm -f "$cl_home/patches.$cl_system"
    translate CL_PATCHES_OFF
    return
  fi
  if [ ! -f "$cl_ips/.$cl_patch_pack" ]; then
    translate CL_DOWNLOADING
    rm -rf "$tmp"
    mkdir -p "$tmp" "$cl_ips"
    if ! cl_fetch "$cl_patch_pack-patches.tar.gz" "$tmp"; then
      rm -rf "$tmp"
      netChecker
      exit 1
    fi
    find "$tmp" -type f -name '*.ips' -exec mv {} "$cl_ips/" \;
    rm -rf "$tmp"
    touch "$cl_ips/.$cl_patch_pack"
  fi
  cl_ips_tree
  touch "$cl_home/patches.$cl_system"
  cl_mount_patches
  translate CL_PATCHES_ON
}

case "$1" in
apply) cl_apply "$2" ;;
state) cl_state "$2" ;;
revert) cl_revert ;;
get) cl_get ;;
patches) cl_patches ;;
*) exit 1 ;;
esac
