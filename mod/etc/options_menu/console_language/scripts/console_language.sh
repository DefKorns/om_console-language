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
# Usage: console_language.sh apply <code> | revert | romaji | reload <change> [code] | delete <code> | romaji-state | install <code> | installall | nonet
source $mountpoint/etc/options_menu/console_language/scripts/cl_vars

# the binds go in at boot, ahead of fontFix and copyleft
# the boot script stays: the firmware menu needs it before any language is installed, and another firmware may need it
clSyncPreinit() {
  cp -f "$cl_home/preinit/p8020_console_language" "$mountpoint/etc/preinit.d/p8020_console_language"
}

# the installed languages changed: the firmware menu reads them again when its screen opens
clAfterChange() {
  [ -n "$cl_native" ] && clNativeBuild "$cl_home"
  clSyncPreinit
}

# runs from omReloadMenu, with the UI stopped
clReload() {
  clUmountRomaji
  clUmountLang
  case "$1" in
  romaji-on) : >"$cl_home/romaji.$cl_system" ;;
  romaji-off) rm -f "$cl_home/romaji.$cl_system" ;;
  esac
  clSyncPreinit
  clInit
  clUiLang
  clRebind
  clMountRomaji
  fontFix
}

# runs in the background: the menu has to be gone before the splash, which stays on screen until the reload
clRomaji() {
  local state=on
  if clRomajiOn; then
    state=off
    rm -f "$cl_home/romaji.$cl_system"
  else
    : >"$cl_home/romaji.$cl_system"
  fi
  while pidof options >/dev/null; do
    usleep 100000
  done
  om_loading_keys="CL_ROMAJI_$(echo "$state" | tr '[:lower:]' '[:upper:]')_LINE1 CL_RELOADING"
  # shellcheck disable=SC2086
  omSplash $om_loading_keys
  omReloadMenuLater sh "$cl_home/scripts/console_language.sh" reload "romaji-$state"
}

clRomajiState() {
  [ -f "$cl_home/romaji.$cl_system" ] && echo 1 || echo 0
}

# cancelling mid-download leaves nothing behind
clAbort() {
  trap - TERM INT HUP
  rm -rf /tmp/cl_*.tar.gz /tmp/cl_stage /tmp/cl_pending
  exit 1
}

clFetch() {
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
  omUnpack "$pkg" "$2"
  rc=$?
  downloadError "$rc"
  return "$rc"
}

# the menu closes after a delete and the entry relaunches it, so this never fails;
# the language in use is blocked by the menu, this is the safety net
clDelete() {
  [ -n "$1" ] && [ "$(clNativeCode "$1")" != "$cl_code" ] || return 0
  rm -rf "$cl_home/custom/$cl_pack/$1" "$cl_home/custom/$cl_pack/$1.new"
  clAfterChange
}

# the active language's files are in use: it goes to <code>.new, swapped in at boot
clInstall() {
  local dest="$cl_home/custom/$cl_pack/$1"
  local stage="/tmp/cl_stage"
  trap clAbort TERM INT HUP
  translate CL_DOWNLOADING
  if [ "$(clNativeCode "$1")" = "$cl_code" ]; then
    rm -rf "$stage" && mkdir -p "$stage"
    clFetch "$cl_pack-$1.tar.gz" "$stage" || {
      rm -rf "$stage"
      exit 1
    }
    rm -rf "$dest.new"
    mv "$stage/custom/$cl_pack/$1" "$dest.new"
    rm -rf "$stage"
    translate CL_REPLACE_AT_REBOOT
  else
    clFetch "$cl_pack-$1.tar.gz" "$cl_home" || exit 1
    clAfterChange
    translate CL_DOWNLOADED
  fi
}

# handler of omDownloadAll: <rc> <downloaded file>
clInstalled() {
  local code="${2#/tmp/cl_"$cl_pack"-}"
  local rc="$1"
  code="${code%.tar.gz}"
  if [ "$rc" = 0 ]; then
    omUnpack "$2" "$cl_home"
    rc=$?
  fi
  case "$rc" in
  0) ;;
  3)
    downloadError 3
    return 3
    ;;
  *) cl_failed="$cl_failed $code" ;;
  esac
}

# every language this firmware doesn't have yet, two downloads at a time
clInstallAll() {
  local pending="/tmp/cl_pending"
  local code name rc
  if [ ! -x "$om_scripts/downloader" ]; then
    translate CL_DOWNLOADER_MISSING
    return 1
  fi
  trap clAbort TERM INT HUP
  : >"$pending"
  while read -r code name; do
    { [ -z "$code" ] || clSkipCode "$code" || [ -d "$cl_home/custom/$cl_pack/$code" ]; } && continue
    printf '%s\t%s\n' "/tmp/cl_$cl_pack-$code.tar.gz" "$cl_url/$cl_pack-$code.tar.gz" >>"$pending"
  done <"$cl_home/download/catalog.$cl_pack.list"
  if [ ! -s "$pending" ]; then
    rm -f "$pending"
    translate CL_ALL_INSTALLED
    return 0
  fi
  translate CL_DOWNLOADING
  cl_failed=""
  omDownloadAll "$pending" clInstalled 2
  rc=$?
  rm -f "$pending"
  clAfterChange
  if [ -n "$cl_failed" ]; then
    translate CL_FAILED
    echo "$cl_failed"
    return 1
  fi
  [ "$rc" = 0 ] && translate CL_DOWNLOADED
  return "$rc"
}

case "$1" in
romaji) clRomaji ;;
reload) clReload "$2" "$3" ;;
delete) clDelete "$2" ;;
romaji-state) clRomajiState ;;
install) clInstall "$2" ;;
installall) clInstallAll ;;
nonet) netChecker ;;
*) exit 1 ;;
esac
