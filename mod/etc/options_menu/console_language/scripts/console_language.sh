#!/bin/sh
# shellcheck disable=SC2154,SC1091,SC1090,SC3043,SC2034,SC3046,SC2086
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
# Usage: console_language.sh apply <code> | revert | install <code> | installall | nonet
source $mountpoint/etc/options_menu/console_language/scripts/cl_vars

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

cl_revert() {
  rm -f "$cl_home/active.$cl_system"
  case "$cl_system" in
  shonen | hvc | shvc) cl_reboot CL_REVERTING ;;
  *) cl_reboot CL_RESTORING ;;
  esac
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

# the active language's files are in use: it goes to <code>.new, swapped in at boot
cl_install() {
  local dest="$cl_home/custom/$cl_pack/$1"
  local stage="/tmp/cl_stage"
  translate CL_DOWNLOADING
  if [ "$1" = "$cl_code" ]; then
    rm -rf "$stage" && mkdir -p "$stage"
    cl_fetch "$cl_pack-$1.tar.gz" "$stage" || exit 1
    rm -rf "$dest.new"
    mv "$stage/custom/$cl_pack/$1" "$dest.new"
    rm -rf "$stage"
    translate CL_REPLACE_AT_REBOOT
  else
    cl_fetch "$cl_pack-$1.tar.gz" "$cl_home" || exit 1
    cl_menu_entries
    translate CL_DOWNLOADED
  fi
}

cl_install_all() {
  local code name missing=0
  while read -r code name; do
    { [ -z "$code" ] || [ -d "$cl_home/custom/$cl_pack/$code" ]; } && continue
    missing=1
    cl_fetch "$cl_pack-$code.tar.gz" "$cl_home" || exit 1
  done <"$cl_home/download/catalog.list"
  if [ "$missing" = 0 ]; then
    translate CL_ALL_INSTALLED
    return
  fi
  cl_menu_entries
  translate CL_DOWNLOADED
}

case "$1" in
apply) cl_apply "$2" ;;
revert) cl_revert ;;
install) cl_install "$2" ;;
installall) cl_install_all ;;
nonet) netChecker ;;
*) exit 1 ;;
esac
