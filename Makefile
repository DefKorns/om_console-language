MOD_ID       := om_console-language
MOD_NAME     := Options Menu - Console Language
MOD_CATEGORY := Options Menu - Addons
LANGUAGES    := language_pack

all: hmod

compile:

# server files for the download entry: customlangs/<pack>-<code>.tar.gz
packs: customlangs

customlangs:
	mkdir -p out/customlangs
	for pack in $(notdir $(wildcard $(LANGUAGES)/*)); do \
		for lang in $$(ls $(LANGUAGES)/$$pack); do \
			tar -czf out/customlangs/$$pack-$$lang.tar.gz -C $(LANGUAGES)/$$pack/$$lang custom; \
		done; \
	done

clean:
	rm -rf out/

include hmod-build/hmod.mk

.PHONY: all compile packs customlangs clean
