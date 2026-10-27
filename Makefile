MOD_ID       := om_console-language
MOD_NAME     := Options Menu - Console Language
MOD_CATEGORY := Options Menu - Addons

LUAJIT_FILES := native-menu/sys_option_languages.lua:mod/etc/options_menu/console_language/assets/native/927b4cd97f045ce30f73e50f50ef8550.lua

all: hmod

clean:
	rm -rf out/ $(dir $(LUAJIT_OUT))

include vendor/hmod-build/luajit.mk
include vendor/hmod-build/hmod.mk

.PHONY: all clean
