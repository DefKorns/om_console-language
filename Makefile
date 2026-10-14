MOD_ID       := om_console-language
MOD_NAME     := Options Menu - Console Language
MOD_CATEGORY := Options Menu - Addons
LANGUAGES    := language_pack
PATCHES      := patches

all: hmod

compile:

# server files for the download entries: customlangs/<pack>-<code>.tar.gz and <pack>-patches.tar.gz
packs: customlangs ipspatches

customlangs:
	mkdir -p out/customlangs
	for pack in $(notdir $(wildcard $(LANGUAGES)/*)); do \
		for lang in $$(ls $(LANGUAGES)/$$pack); do \
			tar -czf out/customlangs/$$pack-$$lang.tar.gz -C $(LANGUAGES)/$$pack/$$lang custom; \
		done; \
	done

ipspatches:
	mkdir -p out
	for pack in $(notdir $(wildcard $(PATCHES)/*)); do \
		tar -czf out/$$pack-patches.tar.gz -C $(PATCHES)/$$pack .; \
	done

clean:
	rm -rf out/

include hmod-build/hmod.mk

.PHONY: all compile packs customlangs ipspatches clean
