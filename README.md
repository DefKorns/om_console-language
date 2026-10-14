# OM Console Language
**This addon requires [DefKorns' fork of the Options Menu](https://github.com/DefKorns/OptionsMenu/tree/modern-ui-ttf) (branch `modern-ui-ttf`).**

![English Translation](https://hakchiresources.com/wp-content/uploads/2018/09/shonen_hvcj.png)

Based on [Advokaten's](https://github.com/advokaten) *Shonen Jump Hack*, this addon enables the hidden languages on the Japanese systems (Famicom Shonen Jump, Famicom Mini and Super Famicom Mini) and downloads custom languages for every system, including the USA and EUR consoles.

*Game translation patches (IPS)* downloads translation and audio patches for the original games. Hold DOWN when starting a game to play it patched in RetroArch (KMFDManic's RetroArch 1.8.4 or 1.9.10 with the FCEUmm and SNES9x cores). Nothing in the game list is changed.

Each firmware keeps its own language, so multi-booting needs no `.hsqs`: hakchi switches firmware and the choice follows it.

Open **Console Language** in the Options Menu, pick a language and leave the menu. *Download more languages* shows up when the console is online.

## Building
```sh
git submodule update --init
make
make packs     # language and IPS packs for the download server
```

## Credits
* Advokaten (Original HMODS and Idea)
* DefKorns (Developer)

## Translation patches
* [BlackPaladin](https://github.com/BlackPaladin2022/Translation-Patches): Famicom Jump: Eiyuu Retsuden, Dragon Ball: Shenron no Nazo, Hokuto no Ken 3
  * Pisalo (Dragon Ball translation)
  * Zynk Oxhyde (Famicom Jump title screen, Hokuto no Ken 3 sprite fix)
  * Cyneprepou4uk (Hokuto no Ken 3 ROM expansion)
  * wave and Sensenic (Hokuto no Ken 3 Japanese-to-Spanish script)
* hayabusakun: Captain Tsubasa Vol. II: Super Striker
  * pacnsacdave (title screen)
* Alex W. Jackson, Neill Corlett and SoM2Freak: Final Fantasy III
* KingMike: Saint Seiya: Ougon Densetsu
* aishsha and Djinn: Saint Seiya: Ougon Densetsu Kanketsu Hen
* Polinym: Dragon Quest
  * Bregalad (alphanumeric password fix)
* Boojum Snark: Ankoku Shinwa: Yamato Takeru Densetsu
  * Proveaux (menu addendum)
* pacnsacdave: Sakigake!! Otokojuku: Shippuu Ichigou Sei
* The Stardust Crusaders: Hokuto no Ken
  * Stevemartin and aishsha (translation)
  * FlashPV (title screen and ending graphic)
* RedComet (Twilight Translations): Dragon Ball Z: Kyoushuu! Saiyajin
  * MukiMuki (Kamaitachii) (translation)
* Jordiway73: The Legend of Zelda (Famicom Disk System)
* AlanMidas: Metroid (Famicom Disk System)
* Columbo: Link no Bouken (Famicom Disk System)
  * masaru (title screen)
* Captain Tsubasa: replaced with the official US release (Tecmo Cup Soccer Game, Tecmo)
* Tenchi wo Kurau: replaced with the official US release (Destiny of an Emperor, Capcom)

## Tools
* [rhester72](https://github.com/rhester72/fdstool): fdstool (FDS to QD conversion for the Famicom Mini Disk System games)

## Thanks to
* bslenul
* CompCom
* darkdev1
