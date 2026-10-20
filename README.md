# OM Console Language
**This addon requires [DefKorns' fork of the Options Menu](https://github.com/DefKorns/OptionsMenu/releases) v2.0.0 or newer.**

![English Translation](https://hakchiresources.com/wp-content/uploads/2018/09/shonen_hvcj.png)

Based on [Advokaten's](https://github.com/advokaten) *Shonen Jump Hack*, this addon enables the hidden languages on the Japanese systems (Famicom Shonen Jump, Famicom Mini and Super Famicom Mini) and downloads custom languages for every system, including the USA and EUR consoles.

English is built in. The other languages come either as separate hmods from that repository (`om_console-language_<system>_<code>`, one per console type, plus `om_console-language_hvc` for the Famicom Mini's languages; also in the hakchi-repo *Language Packs* tab), installed with hakchi like any other mod, or from the menu's *Download more languages*, which fetches the same files from the [languages-v1](https://github.com/DefKorns/om_console-language-packs/releases/tag/languages-v1) release of [om_console-language-packs](https://github.com/DefKorns/om_console-language-packs). The Famicom Mini downloads its languages the first time one is picked.

The game titles on the home screen use the extended `title.fnt` of **Font Remount**, so install it with this addon to see accented letters and the Rōmaji titles.

Each firmware keeps its own language, so multi-booting needs no `.hsqs`: hakchi switches firmware and the choice follows it.

Open **Console Language** in the Options Menu, pick a language and leave the menu. *Download more languages* shows up when the console is online.

On the Japanese systems, **Rōmaji titles** shows the games' names in rōmaji instead of kana and kanji. It reboots the console to apply and works the same way to turn off.

## Building
```sh
git submodule update --init
make
make packs     # out/catalog/*.tar.gz
```
The language hmods and the catalog are published in [om_console-language-packs](https://github.com/DefKorns/om_console-language-packs) with `sh tools/publish_packs.sh catalog` (the `languages-v1` release the download entry reads) and `sh tools/publish_packs.sh hmods <tag>` (a release with the hmods). `--check` lists what would be sent.

## Credits
* Advokaten (Original HMODS and Idea)
* DefKorns (Developer)

## Thanks to
* bslenul
* CompCom
* darkdev1
