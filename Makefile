MOD_ID       := om_console-language
MOD_NAME     := Options Menu - Console Language
MOD_CATEGORY := Options Menu - Addons

NATIVE_DIR   := mod/etc/options_menu/console_language/assets/native
LUAJIT_FILES := native-menu/sys_option_languages.lua:$(NATIVE_DIR)/927b4cd97f045ce30f73e50f50ef8550.lua \
                native-menu/sys_option_languages.lua:$(NATIVE_DIR)/3d3bae3b044fe5afaf75cecd8b735d4c.lua \
                native-menu/helper_nodes.lua:$(NATIVE_DIR)/139f8a0e2335b7d0954d2a9c03d47e36.lua \
                native-menu/sys_menubaru.lua:$(NATIVE_DIR)/5fbe9d6a4f5b9b7f118117bebb20f2cf.lua \
                native-menu/sys_menubaru_shonen.lua:$(NATIVE_DIR)/e09559563454b200f423867e8463d4c3.lua

all: hmod

clean:
	rm -rf out/ $(dir $(LUAJIT_OUT))

include vendor/hmod-build/luajit.mk
include vendor/hmod-build/hmod.mk

.PHONY: all clean
