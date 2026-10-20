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
# Usage: console_language.sh apply <code> | revert | romaji | romaji-state | install <code> | installall | nonet
source $mountpoint/etc/options_menu/console_language/scripts/cl_vars

# the binds go in at boot, ahead of fontFix and copyleft
# the boot script only exists while a language is applied on some firmware
clSyncPreinit() {
  local dest="$mountpoint/etc/preinit.d/p8020_console_language"
  if ls "$cl_home"/active.* >/dev/null 2>&1; then
    cp -f "$cl_home/preinit/p8020_console_language" "$dest"
  else
    rm -f "$dest"
  fi
}

# the menu stays paused behind the splash until the console reboots
clReboot() {
  clSplash "$1_LINE1" "$1_LINE2"
  sleep 1
  hakchi reboot >/dev/null 2>&1
  sleep 30
}

clFail() {
  clSplash "$1"
  sleep 3
  sh "$om_scripts/ResumeUI.sh"
  exit 1
}

clAvailable() {
  local builtin
  if [ -f "$cl_dir/custom/$cl_pack/$1/strings.lng" ] || [ -d "$cl_dir/custom/$cl_pack/$1/strings" ]; then
    return 0
  fi
  builtin="$(clBuiltin "$1")" && [ -f "$builtin" ]
}

clApply() {
  # the Famicom's other languages are downloaded on first use
  if ! clAvailable "$1" && [ "$cl_system" = "hvc" ] && [ "$1" != "usa_en" ]; then
    clSplash CL_DOWNLOADING
    clFetch hvc-strings.tar.gz "$cl_home" || clFail CL_DOWNLOAD_FAILED
  fi
  clAvailable "$1" || clFail CL_NOT_FOUND
  echo "$1" >"$cl_home/active.$cl_system"
  clSyncPreinit
  clReboot CL_APPLYING
}

clRevert() {
  rm -f "$cl_home/active.$cl_system" "$cl_home/romaji.$cl_system"
  clSyncPreinit
  case "$cl_system" in
  shonen | hvc | shvc) clReboot CL_REVERTING ;;
  *) clReboot CL_RESTORING ;;
  esac
}

clRomaji() {
  [ -f "$cl_home/active.$cl_system" ] || clFail CL_ROMAJI_NEEDS_LANGUAGE
  if [ -f "$cl_home/romaji.$cl_system" ]; then
    rm -f "$cl_home/romaji.$cl_system"
    clReboot CL_ROMAJI_OFF
  else
    : >"$cl_home/romaji.$cl_system"
    clReboot CL_ROMAJI_ON
  fi
}

clRomajiState() {
  [ -f "$cl_home/romaji.$cl_system" ] && echo 1 || echo 0
}

clFreeKb() {
  df -Pk "$1" | awk 'NR==2 {print $4}'
}

clUnpackedKb() {
  local size_kb=$(($(tail -c4 "$1" | od -An -tu4) / 1024 + 1))
  echo $((size_kb + size_kb / 10))
}

# unpacks a downloaded tarball into $2: 0 ok, 1 broken, 3 no space left
clUnpack() {
  local rc=0
  if [ "$(clFreeKb "$2")" -lt "$(clUnpackedKb "$1")" ]; then
    rc=3
    gzip -t "$1" 2>/dev/null || rc=1
  elif ! tar -xzf "$1" -C "$2"; then
    rc=1
    [ "$(clFreeKb "$2")" -lt 1024 ] && rc=3
  fi
  rm -f "$1"
  return "$rc"
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
  clUnpack "$pkg" "$2"
  rc=$?
  downloadError "$rc"
  return "$rc"
}

# the menu closes after a delete and the entry relaunches it, so this never fails;
# the language in use is blocked by the menu, this is the safety net
clDelete() {
  [ -n "$1" ] && [ "$1" != "$cl_code" ] || return 0
  rm -rf "$cl_home/custom/$cl_pack/$1" "$cl_home/custom/$cl_pack/$1.new"
}

# the active language's files are in use: it goes to <code>.new, swapped in at boot
clInstall() {
  local dest="$cl_home/custom/$cl_pack/$1"
  local stage="/tmp/cl_stage"
  trap clAbort TERM INT HUP
  translate CL_DOWNLOADING
  if [ "$1" = "$cl_code" ]; then
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
    clMenuEntries
    translate CL_DOWNLOADED
  fi
}

# handler of omDownloadAll: <rc> <downloaded file>
clInstalled() {
  local code="${2#/tmp/cl_$cl_pack-}"
  local rc="$1"
  code="${code%.tar.gz}"
  if [ "$rc" = 0 ]; then
    clUnpack "$2" "$cl_home"
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
  clMenuEntries
  if [ -n "$cl_failed" ]; then
    translate CL_FAILED
    echo "$cl_failed"
    return 1
  fi
  [ "$rc" = 0 ] && translate CL_DOWNLOADED
  return "$rc"
}

case "$1" in
apply) clApply "$2" ;;
revert) clRevert ;;
romaji) clRomaji ;;
delete) clDelete "$2" ;;
romaji-state) clRomajiState ;;
install) clInstall "$2" ;;
installall) clInstallAll ;;
nonet) netChecker ;;
*) exit 1 ;;
esac
