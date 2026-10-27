MOD_ID       := om_console-language
MOD_NAME     := Options Menu - Console Language
MOD_CATEGORY := Options Menu - Addons

NATIVE_DIR   := mod/etc/options_menu/console_language/assets/native
LUAJIT_FILES := native-menu/sys_option_languages.lua:$(NATIVE_DIR)/927b4cd97f045ce30f73e50f50ef8550.lua                 native-menu/sys_option_languages.lua:$(NATIVE_DIR)/3d3bae3b044fe5afaf75cecd8b735d4c.lua

all: hmod

clean:
	rm -rf out/ $(dir $(LUAJIT_OUT))

include vendor/hmod-build/luajit.mk
include vendor/hmod-build/hmod.mk

.PHONY: all clean
