MOD_ID       := om_console-language
MOD_NAME     := Options Menu - Console Language
MOD_CATEGORY := Options Menu - Addons

all: hmod

compile:

clean:
	rm -rf out/

include vendor/hmod-build/hmod.mk

.PHONY: all compile clean
