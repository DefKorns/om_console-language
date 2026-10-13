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
# Usage: lang_hack.sh apply <code> | state <code|patches> | revert | get | patches
. "$mountpoint/etc/options_menu/scripts/om_functions"
lh_lib=1
. "$preinitpath/p8020_language_hack"
lh_init

# writes go through "/" ($lh_home); the preinit reads the same files from $rootfs ($lh_dir)
lh_home="$options_menu/language_hack"
lh_urls="http://hakchicloud.com/Hakchi_Themes/options_menu http://classicmods.net/Hakchi_Themes/options_menu"
lh_ips="$lh_home/patches_ips"

# code:native_name, "_" for spaces; packs are built from language_pack/<pack>/<code>
lh_catalog() {
  case "$lh_pack" in
  shonen) echo "as_id:Bahasa_Indonesia cst_cw:Spurdo eur_gr:Ελληνικά eur_nor:Norsk eur_swe:Svenska" ;;
  nes) echo "eur_swe:Svenska" ;;
  snes) echo "eur_gr:Ελληνικά eur_nor:Norsk eur_swe:Svenska por_br:Português_(Brasil)" ;;
  esac
}

lh_available() {
  local builtin
  if [ -f "$lh_dir/custom/$1/strings.lng" ] || [ -d "$lh_dir/custom/$1/strings" ]; then
    return 0
  fi
  builtin="$(lh_builtin "$1")" && [ -f "$builtin" ]
}

lh_apply() {
  if ! lh_available "$1"; then
    translate LH_NOT_FOUND
    exit 1
  fi
  translate LH_APPLYING
  lh_umount_lang
  echo "$1" >"$lh_home/active.$lh_system"
  lh_init
  lh_mount_lang
  translate LH_APPLIED
}

lh_state() {
  if [ "$1" = "patches" ] && [ -f "$lh_dir/patches.$lh_system" ]; then
    echo 1
  elif [ "$1" != "patches" ] && [ "$lh_code" = "$1" ]; then
    echo 1
  else
    echo 0
  fi
}

lh_revert() {
  translate LH_REVERTING
  lh_umount_lang
  rm -f "$lh_home/active.$lh_system"
  translate LH_REVERTED
}

lh_fetch() {
  local url
  local pkg
  pkg="/tmp/lh_$(basename "$1")"
  for url in $lh_urls; do
    if wget -q -O "$pkg" "$url/$1" && tar -xzf "$pkg" -C "$2"; then
      rm -f "$pkg"
      return 0
    fi
  done
  rm -f "$pkg"
  return 1
}

lh_get() {
  local entry
  local code
  local cmd
  local n=100
  translate LH_DOWNLOADING
  for entry in $(lh_catalog); do
    code="${entry%%:*}"
    lh_fetch "customlangs/$lh_pack-$code.tar.gz" "$lh_home" || {
      netChecker
      exit 1
    }
    cmd="$lh_home/commands/c0${n}_$code"
    printf '%s\n' \
      "COMMAND_NAME=$(echo "${entry#*:}" | tr '_' ' ')" \
      "COMMAND_TYPE=INTERNAL" \
      "COMMAND_STR=sh %script_dir%/lang_hack.sh apply $code" \
      "STATE_STR=sh %script_dir%/lang_hack.sh state $code" >"$cmd"
    [ -f "$lh_home/images/$code.png" ] && echo "PREVIEW_IMAGE=/etc/options_menu/language_hack/images/$code.png" >>"$cmd"
    n=$((n + 1))
  done
  translate LH_DOWNLOADED
}

# RetroArch soft-patches <rom>.ips next to the rom (NES) and, for roms unpacked
# to /tmp/rom, copies any .ips from <roms>/<ID>/<ID> (SNES); the overlay puts them there
lh_ips_tree() {
  local f
  local id
  local upper="$lh_home/ips_overlay/$lh_system"
  rm -rf "$upper"
  for f in "$lh_ips"/*.ips; do
    id="${f##*/}"
    id="${id%%.*}"
    [ -d "$lh_roms/$id" ] || continue
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
lh_patches() {
  local tmp="/tmp/lh_patches"
  if [ -f "$lh_dir/patches.$lh_system" ]; then
    lh_umount_patches
    rm -f "$lh_home/patches.$lh_system"
    translate LH_PATCHES_OFF
    return
  fi
  if [ ! -f "$lh_ips/.$lh_patch_pack" ]; then
    translate LH_DOWNLOADING
    rm -rf "$tmp"
    mkdir -p "$tmp" "$lh_ips"
    if ! lh_fetch "$lh_patch_pack-patches.tar.gz" "$tmp"; then
      rm -rf "$tmp"
      netChecker
      exit 1
    fi
    find "$tmp" -type f -name '*.ips' -exec mv {} "$lh_ips/" \;
    rm -rf "$tmp"
    touch "$lh_ips/.$lh_patch_pack"
  fi
  lh_ips_tree
  touch "$lh_home/patches.$lh_system"
  lh_mount_patches
  translate LH_PATCHES_ON
}

case "$1" in
apply) lh_apply "$2" ;;
state) lh_state "$2" ;;
revert) lh_revert ;;
get) lh_get ;;
patches) lh_patches ;;
*) exit 1 ;;
esac
