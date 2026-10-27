# OM Console Language

**This addon requires [DefKorns' fork of the Options Menu](https://github.com/DefKorns/OptionsMenu/releases) v2.1.0 or newer.**

![English Translation](https://hakchiresources.com/wp-content/uploads/2018/09/shonen_hvcj.png)

Based on [Advokaten's](https://github.com/advokaten) *Shonen Jump Hack*, this addon enables the hidden languages on the Japanese systems (Famicom Shonen Jump, Famicom Mini and Super Famicom Mini) and downloads custom languages for every system, including the USA and EUR consoles.

English is built in. The other languages come either as separate hmods from that repository (`om_console-language_<system>_<code>`, one per console type; also in the hakchi-repo *Language Packs* tab), installed with hakchi like any other mod, or from the menu's *Download more languages*, which fetches the same files from the [languages-v1](https://github.com/DefKorns/om_console-language-packs/releases/tag/languages-v1) release of [om_console-language-packs](https://github.com/DefKorns/om_console-language-packs). The Famicom Mini's languages come with the addon.

The game titles on the home screen use the extended `title.fnt` of **Font Remount**, so install it with this addon to see accented letters and the Rōmaji titles.

Each firmware keeps its own language, so multi-booting needs no `.hsqs`: hakchi switches firmware and the choice follows it.

Open **Console Language** in the Options Menu, pick a language and the menu reloads with it applied, with no reboot. *Download more languages* shows up when the console is online.

On the USA and EUR SNES the languages you download are listed in the console's own Languages screen instead, after the eight it ships with; the list scrolls, and the choice is kept across reboots. The Options Menu then only downloads and deletes them. A firmware whose language script this release doesn't know falls back to choosing from the Options Menu.

On the Japanese systems, **Rōmaji titles** shows the games' names in rōmaji instead of kana and kanji. It is independent of the applied language and, like the languages, reloads the menu instead of rebooting.

## Building

```sh
git submodule update --init
make
```

The language packs and their build live in [om_console-language-packs](https://github.com/DefKorns/om_console-language-packs), which only holds the releases.

The Languages screen script of the SNES firmware menu is kept as source in [native-menu/](native-menu/) and compiled during the build to the LuaJIT 2.0 bytecode the console loads, by `luajit-bc.sh` from [hmod-build](https://github.com/DefKorns/hmod-build). Building needs `git`, `gcc` and `make`; the first build fetches LuaJIT at a fixed commit into `out/luajit`.

## Contributing

[Report a bug](https://github.com/DefKorns/om_console-language/issues/new?template=bug_report.yml) or [suggest a feature](https://github.com/DefKorns/om_console-language/issues/new?template=feature_request.yml); pull requests are welcome too:

- **Formatting:** [`.editorconfig`](.editorconfig) sets it: UTF-8, LF line endings, a final newline, no trailing whitespace, 4 spaces for C/C++, 2 for shell scripts, tabs only in the Makefile.
- **Checks before each commit:** [pre-commit](https://pre-commit.com/) runs the same checks on the files you stage. Set it up once per clone with `pip install pre-commit` and `pre-commit install`; `pre-commit run --all-files` checks everything.
- **Only change what you need:** don't reformat, re-indent or strip whitespace in lines you aren't changing. The **Style** check on pull requests looks only at the lines you add.
- Everything else follows the Options Menu's [code style](https://github.com/DefKorns/OptionsMenu#code-style).

## Credits

- Advokaten (Original HMODS and Idea)
- DefKorns (Developer)

## Thanks to

- bslenul
- CompCom
- darkdev1
