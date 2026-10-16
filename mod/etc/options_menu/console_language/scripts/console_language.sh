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
# Usage: console_language.sh apply <code> | state <code> | revert | get
. "$mountpoint/etc/options_menu/scripts/om_functions"
cl_lib=1
. "$preinitpath/p8020_console_language"
cl_init

# writes go through "/" ($cl_home); the preinit reads the same files from $rootfs ($cl_dir)
cl_home="$options_menu/console_language"
cl_url="https://github.com/DefKorns/om_console-language/releases/download/languages-v1"

# languages-v1 has <pack>-<code>.tar.gz for each, built from language_pack/<code>/<pack>
cl_catalog() {
  case "$cl_pack" in
  shonen) echo "as_id cst_cw eur_gr eur_nor eur_swe" ;;
  nes) echo "eur_swe" ;;
  snes) echo "eur_gr eur_nor eur_swe por_br" ;;
  esac
}

# the binds go in at boot, ahead of fontFix and copyleft
cl_reboot() {
  "$om_scripts/gen_splash" /tmp/om_splash.png "$1_LINE1" "$1_LINE2" && decodepng /tmp/om_splash.png >/dev/fb0
  sleep 1
  hakchi reboot
}

cl_available() {
  local builtin
  if [ -f "$cl_dir/custom/$cl_pack/$1/strings.lng" ] || [ -d "$cl_dir/custom/$cl_pack/$1/strings" ]; then
    return 0
  fi
  builtin="$(cl_builtin "$1")" && [ -f "$builtin" ]
}

cl_apply() {
  # the Famicom's other languages are downloaded on first use
  if ! cl_available "$1" && [ "$cl_system" = "hvc" ] && [ "$1" != "usa_en" ]; then
    cl_fetch hvc-strings.tar.gz "$cl_home" || exit 1
  fi
  if ! cl_available "$1"; then
    translate CL_NOT_FOUND
    exit 1
  fi
  echo "$1" >"$cl_home/active.$cl_system"
  cl_reboot CL_APPLYING
}

cl_state() {
  if [ "$cl_code" = "$1" ]; then
    echo 1
  else
    echo 0
  fi
}

cl_revert() {
  rm -f "$cl_home/active.$cl_system"
  cl_reboot CL_REVERTING
}

cl_fetch() {
  local pkg="/tmp/cl_$1"
  local rc
  if [ ! -x "$om_scripts/downloader" ]; then
    translate CL_DOWNLOADER_MISSING
    return 1
  fi
  omDownload "$pkg" "$cl_url/$1" || {
    rm -f "$pkg"
    return 1
  }
  tar -xzf "$pkg" -C "$2"
  rc=$?
  rm -f "$pkg"
  return "$rc"
}

cl_get() {
  local code
  translate CL_DOWNLOADING
  for code in $(cl_catalog); do
    cl_fetch "$cl_pack-$code.tar.gz" "$cl_home" || exit 1
  done
  translate CL_DOWNLOADED
}

case "$1" in
apply) cl_apply "$2" ;;
state) cl_state "$2" ;;
revert) cl_revert ;;
get) cl_get ;;
*) exit 1 ;;
esac
