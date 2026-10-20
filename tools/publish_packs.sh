#!/bin/sh
#
#  Copyright (C) 2026 DefKorns
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

# Publishes the build in out/ to om_console-language-packs:
#   catalog      out/catalog/* into the rolling languages-v1 release
#   hmods <tag>  out/om_console-language_<system>_<code>.hmod and _hvc.hmod into a new release
#
# Usage: publish_packs.sh catalog
#        publish_packs.sh hmods <tag>
#        publish_packs.sh <catalog|hmods> --check   only list what would be sent
# Build first: sh vendor/hmod-build/docker-make.sh languages packs
set -e

mode="$1"
tag="$2"
repo="DefKorns/om_console-language-packs"
out_dir="$(cd "$(dirname "$0")/.." && pwd)/out"

dry=
for arg in "$@"; do [ "$arg" = --check ] && dry=1; done

case "$mode" in
  catalog) set -- "$out_dir"/catalog/* ;;
  hmods)
    case "$tag" in
      v[0-9]*) ;;
      --check) [ -n "$dry" ] ;;
      *)
        echo "usage: publish_packs.sh hmods <tag, like v1.0.0>" >&2
        exit 2
        ;;
    esac
    set -- "$out_dir"/om_console-language_*_*.hmod "$out_dir"/om_console-language_hvc.hmod
    ;;
  *)
    echo "usage: publish_packs.sh <catalog|hmods <tag>> [--check]" >&2
    exit 2
    ;;
esac

for file in "$@"; do
  [ -f "$file" ] || { echo "missing $file: build first" >&2; exit 1; }
done

if [ -n "$dry" ]; then
  printf '%s\n' "$@"
  exit 0
fi

if [ "$mode" = catalog ]; then
  gh release view languages-v1 -R "$repo" >/dev/null 2>&1 ||
    gh release create languages-v1 -R "$repo" --title "Language packs" --latest=false \
      --notes "Rolling catalog read by the Console Language download entry."
  gh release upload languages-v1 "$@" -R "$repo" --clobber
else
  prerelease=
  case "$tag" in *-*) prerelease=--prerelease ;; esac
  gh release create "$tag" "$@" -R "$repo" --title "Language Packs $tag" --generate-notes $prerelease
fi
