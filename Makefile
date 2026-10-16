MOD_ID       := om_console-language
MOD_NAME     := Options Menu - Console Language
MOD_CATEGORY := Options Menu - Addons
LANGUAGES    := language_pack
HVC_STRINGS  := language_assets/hvc-strings
CL_PATH      := etc/options_menu/console_language
CODES        := $(notdir $(wildcard $(LANGUAGES)/*))
STAGE        := out/stage

all: hmod languages

compile:

# out/stage/<code>/$(CL_PATH)/custom/<system>/<code>, shared by the language hmods and the catalog
stage:
	rm -rf $(STAGE)
	for code in $(CODES); do \
		for sys in $$(cd $(LANGUAGES)/$$code && ls -d */ | tr -d /); do \
			dest=$(STAGE)/$$code/$(CL_PATH)/custom/$$sys/$$code; \
			mkdir -p $$dest && cp -r $(LANGUAGES)/$$code/$$sys/. $(LANGUAGES)/$$code/name $$dest/; \
		done; \
		echo "Adds $$(cat $(LANGUAGES)/$$code/name) to Options Menu - Console Language." > $(STAGE)/$$code/readme.md; \
	done
	mkdir -p $(STAGE)/hvc/$(CL_PATH)
	cp -r $(HVC_STRINGS)/assets $(STAGE)/hvc/$(CL_PATH)/
	echo "Adds the Famicom Mini's other languages to Options Menu - Console Language." > $(STAGE)/hvc/readme.md

# one hmod per extra language, plus one with the Famicom Mini's languages
languages: stage
	for code in $(CODES); do \
		$(MAKE) --no-print-directory hmod MOD_ID=om_console-language_$$code MOD_DIR=$(STAGE)/$$code \
			MOD_NAME="Console Language - $$(cat $(LANGUAGES)/$$code/name)" || exit 1; \
	done
	$(MAKE) --no-print-directory hmod MOD_ID=om_console-language_hvc MOD_DIR=$(STAGE)/hvc \
		MOD_NAME="Console Language - Famicom Mini languages"

# assets of the languages-v1 release the download entry reads: out/catalog/*.tar.gz
packs: stage
	mkdir -p out/catalog
	rm -f out/catalog/*.list
	for code in $(CODES); do \
		for sys in $$(ls $(STAGE)/$$code/$(CL_PATH)/custom); do \
			tar -czf out/catalog/$$sys-$$code.tar.gz -C $(STAGE)/$$code/$(CL_PATH) custom/$$sys/$$code; \
			echo "$$code $$(cat $(LANGUAGES)/$$code/name)" >> out/catalog/$$sys.list; \
		done; \
	done
	tar -czf out/catalog/hvc-strings.tar.gz -C $(STAGE)/hvc/$(CL_PATH) assets

clean:
	rm -rf out/

include vendor/hmod-build/hmod.mk

.PHONY: all compile stage languages packs clean
