-- sys_option_languages.lua of the SNES UI (stock md5 927b4cd97f045ce30f73e50f50ef8550), decompiled and
-- changed so the Languages screen lists the Console Language languages; build.sh compiles it.
require("/scripts/core/core.lua")
require("/scripts/app/clover_autocancel.lua")

sys_option_languages = class(gui_container)

local var_0_0 = {
    {
        language = "en",
        caption = "English",
        region = PLATFORM_REGION_AMERICA
    },
    {
        language = "fr",
        caption = "French",
        region = PLATFORM_REGION_EUROPE
    },
    {
        language = "de",
        caption = "German",
        region = PLATFORM_REGION_EUROPE
    },
    {
        language = "it",
        caption = "Italian",
        region = PLATFORM_REGION_EUROPE
    },
    {
        language = "es",
        caption = "Spanish",
        region = PLATFORM_REGION_EUROPE
    },
    {
        language = "nl",
        caption = "Dutch",
        region = PLATFORM_REGION_EUROPE
    },
    {
        language = "pt",
        caption = "Portuguese",
        region = PLATFORM_REGION_EUROPE
    },
    {
        language = "ru",
        caption = "Russian",
        region = PLATFORM_REGION_EUROPE
    }
}

local clBooted
local CL_DIR = "/etc/options_menu/console_language/"
local CL_LIST = "/var/console_language_native/list"
local CL_ACTIVE = CL_DIR .. "active.snes"
local CL_UI = "/var/console_language_ui"

-- one "code<TAB>name" per line, written by Console Language for the installed languages
local function clReadList()
    local entries = {}

    if FileUtils.fileExists(CL_LIST) then
        for line in string.gmatch(FileUtils.readFile(CL_LIST), "[^\r\n]+") do
            local code, name = string.match(line, "^(%S+)\t(.+)$")

            if code and name then
                entries[#entries + 1] = {
                    language = code,
                    caption = name,
                    region = PLATFORM_REGION_EUROPE,
                    extra = true
                }
            end
        end
    end

    return entries
end

local clNames = {
    Japanese = "日本語",
    English = "English",
    French = "Français",
    German = "Deutsch",
    Spanish = "Español",
    Italian = "Italiano",
    Dutch = "Nederlands",
    Portuguese = "Português (Europeu)",
    Russian = "Русский"
}
local clColumns = {
    {"English", "French", "German", "Spanish", "Japanese"},
    {"Italian", "Dutch", "Portuguese", "Russian"}
}

-- the firmware's own jpn_ja is the ninth language; it is remembered like an extra because the
-- firmware only accepts its eight in lang.txt
var_0_0[#var_0_0 + 1] = {
    language = "ja",
    caption = "Japanese",
    region = PLATFORM_REGION_JAPAN,
    extra = true
}

-- the extras fill the shorter column first
for _, entry in ipairs(clReadList()) do
    var_0_0[#var_0_0 + 1] = entry
    table.insert(clColumns[#clColumns[1] <= #clColumns[2] and 1 or 2], entry.caption)
end

-- the Options Menu names its languages like the flags: Brazilian Portuguese is pt_br
local function clUiLanguage(code)
    if code == "pb" then
        return "pt_br"
    end

    return code
end

local function clActiveCode()
    if FileUtils.fileExists(CL_ACTIVE) then
        return (string.match(FileUtils.readFile(CL_ACTIVE), "%S+"))
    end
end

local function clApplyLocale(entry)
    Localization.setLocale(entry.language, "", entry.region)
    Localization.reloadStrings()
    LabelComponent.refreshTextAll()

    for _, hud in pairs(system.hud) do
        hud:refresh()
    end
end

local function clCurrentCaption()
    local lang, _, region = Localization.getLocale()
    local idx = table_find_if(var_0_0, function(entry)
        return entry.language == lang and entry.region == region
    end)

    return idx and var_0_0[idx].caption
end

local function clLabelOf(element)
    local node = element:getChildByName("Label")

    return node and node:getAllComponents()[1]
end

-- the scene declares the slots of a column in "row"; the first-run screen adds a confirm
-- button to each column. Any other shape is left as the firmware made it.
local function clGeometry(self)
    local stride = self.row

    if not stride or #self.elementArray ~= 2 * stride then
        return
    end

    local rows = self.isFirstMode and stride - 1 or stride

    if rows >= 1 then
        return stride, rows
    end
end

local function clMaxOffset(rows)
    return math.max(0, math.max(#clColumns[1], #clColumns[2]) - rows)
end

-- the last row of a column that has an entry at this offset
local function clLastRow(col, offset, rows)
    return math.max(0, math.min(rows, #clColumns[col] - offset))
end

-- every slot shows the entry of its column at the shared offset; slots without one are disabled
local function clRefresh(self, stride, rows)
    local current = clCurrentCaption()
    local selected

    for col = 1, 2 do
        for row = 1, rows do
            local element = self.elementArray[(col - 1) * stride + row]
            local caption = clColumns[col][self.clOffset + row]

            if element then
                if caption then
                    element:enable()
                    element.language = caption

                    local label = clLabelOf(element)

                    if label then
                        label:setText(clNames[caption] or caption)
                    end

                    element:setChecked(false)

                    if caption == current then
                        selected = element
                    end
                else
                    element:setChecked(false)
                    element:disable()
                end
            end
        end
    end

    if selected then
        self.radiogroup:selectButton(selected)
    end
end

local function clScrollIntoView(self, rows)
    local current = clCurrentCaption()

    for col = 1, 2 do
        for pos, caption in ipairs(clColumns[col]) do
            if caption == current then
                local offset = self.clOffset

                if pos <= offset then
                    offset = pos - 1
                elseif pos > offset + rows then
                    offset = pos - rows
                end

                self.clOffset = math.max(0, math.min(offset, clMaxOffset(rows)))
            end
        end
    end
end

function sys_option_languages.start(arg_1_0)
    gui_container.start(arg_1_0)

    do
        local lang, _, region = Localization.getLocale()

        if table_find_if(var_0_0, function(entry)
            return entry.extra and entry.language == lang and entry.region == region
        end) then
            return
        end
    end

    if HOST_PLATFORM_IS_WINDOWS then
        local var_1_0 = table_find_if(var_0_0, function(arg_2_0)
            return arg_2_0.caption == debug_store.language
        end)

        if var_1_0 then
            local var_1_1 = var_0_0[var_1_0]

            system.setLocale(var_1_1.language, "", var_1_1.region)
        end
    end

    local var_1_2, var_1_3, var_1_4 = Localization.getLocale()

    if system.is_nes() then
        if store.language_selected then
            local var_1_5
            local var_1_6
            local var_1_7 = table_find_if(var_0_0, function(arg_3_0)
                return arg_3_0.language == var_1_2 and arg_3_0.region == var_1_4
            end)

            if var_1_7 then
                var_1_5 = var_0_0[var_1_7]
                var_1_6 = table_find_if(arg_1_0.elementArray, function(arg_4_0)
                    return arg_4_0.language == var_1_5.caption
                end)
            end

            if var_1_6 then
                local var_1_8 = arg_1_0.elementArray[var_1_6]

                arg_1_0.radiogroup:selectButton(var_1_8)

                arg_1_0.current = var_1_8
            else
                store.language_selected = false

                local var_1_9 = arg_1_0.elementArray[1]

                arg_1_0.radiogroup:selectButton(var_1_9)

                arg_1_0.current = var_1_9

                local var_1_10 = var_0_0[1]

                system.setLocale(var_1_10.language, "", var_1_10.region)
            end
        else
            local var_1_11 = arg_1_0.elementArray[1]

            arg_1_0.radiogroup:selectButton(var_1_11)

            arg_1_0.current = var_1_11

            local var_1_12 = var_0_0[1]

            system.setLocale(var_1_12.language, "", var_1_12.region)
        end
    else
        system.setLocale("ja", "", PLATFORM_REGION_JAPAN)
    end

    if not arg_1_0.isFirstMode and not clBooted then
        clBooted = true

        local code = clActiveCode()
        local idx = code and table_find_if(var_0_0, function(entry)
            return entry.extra and entry.language == code
        end)

        if idx then
            clApplyLocale(var_0_0[idx])
        end
    end
end

function sys_option_languages.activate(arg_5_0)
    local var_5_0, var_5_1, var_5_2 = Localization.getLocale()

    local clStride, clRows = clGeometry(arg_5_0)

    if clStride then
        arg_5_0.clOffset = arg_5_0.clOffset or 0

        clScrollIntoView(arg_5_0, clRows)
        clRefresh(arg_5_0, clStride, clRows)

        if not arg_5_0.isFirstMode then
            local var_5_5 = table_find_if(arg_5_0.elementArray, function(arg_7_0)
                return arg_7_0.language == clCurrentCaption()
            end)

            arg_5_0.current = arg_5_0.elementArray[var_5_5 or 1]
        end
    else
        if not arg_5_0.isFirstMode then
            local var_5_3 = table_find_if(var_0_0, function(arg_6_0)
                return arg_6_0.language == var_5_0 and arg_6_0.region == var_5_2
            end)
            local var_5_4 = var_0_0[var_5_3]
            local var_5_5 = table_find_if(arg_5_0.elementArray, function(arg_7_0)
                return arg_7_0.language == var_5_4.caption
            end)

            if var_5_5 then
                arg_5_0.current = arg_5_0.elementArray[var_5_5]
            else
                arg_5_0.current = arg_5_0.elementArray[1]
            end

            arg_5_0.radiogroup:selectButton(arg_5_0.current)
        end
    end

    gui_container.activate(arg_5_0)

    if not arg_5_0.isFirstMode then
        CloverAutoCancel.Set("sys_option_languages", arg_5_0)
    end
end

function sys_option_languages.onRadioSelectionChanged(arg_8_0, arg_8_1)
    local var_8_0 = arg_8_0.radiogroup:getSelectedButton()
    local var_8_1 = table_find_if(var_0_0, function(arg_9_0)
        return arg_9_0.caption == var_8_0.language
    end)

    debug_store.language = var_0_0[var_8_1].caption
    arg_8_0.current = var_8_0
end

function sys_option_languages.onContainerCanceled(arg_10_0, arg_10_1)
    if not arg_10_0.isFirstMode then
        CloverAutoCancel.Set("sys_option_languages", nil)
        Main:toHomeMenu()

        if arg_10_0.cancelSound then
            arg_10_0.cancelSound:stop()
            arg_10_0.cancelSound:play()
        end
    end
end

function sys_option_languages.onElementCommand(arg_11_0, arg_11_1, arg_11_2)
    local clStride, clRows = clGeometry(arg_11_0)

    if clStride and arg_11_0.clOffset and arg_11_2.id == GUI_COMMAND_KEYPRESS then
        local idx = table_find(arg_11_0.elementArray, arg_11_1)

        if idx then
            local col = idx <= clStride and 1 or 2
            local row = idx - (col - 1) * clStride
            local base = (col - 1) * clStride

            if row <= clRows then
                if CloverPadUI.pressed.down and row == clLastRow(col, arg_11_0.clOffset, clRows) then
                    if arg_11_0.clOffset < clMaxOffset(clRows) then
                        arg_11_0.clOffset = arg_11_0.clOffset + 1
                        clRefresh(arg_11_0, clStride, clRows)

                        local last = clLastRow(col, arg_11_0.clOffset, clRows)

                        if row > last then
                            GUI:focusElement(arg_11_0.elementArray[base + last])
                        end

                        return true
                    elseif not arg_11_0.isFirstMode and arg_11_0.clOffset > 0 then
                        arg_11_0.clOffset = 0
                        clRefresh(arg_11_0, clStride, clRows)
                        GUI:focusElement(arg_11_0.elementArray[base + 1])

                        return true
                    end
                elseif CloverPadUI.pressed.up and row == 1 then
                    if arg_11_0.clOffset > 0 then
                        arg_11_0.clOffset = arg_11_0.clOffset - 1
                        clRefresh(arg_11_0, clStride, clRows)

                        return true
                    elseif not arg_11_0.isFirstMode and clMaxOffset(clRows) > 0 then
                        arg_11_0.clOffset = clMaxOffset(clRows)
                        clRefresh(arg_11_0, clStride, clRows)
                        GUI:focusElement(arg_11_0.elementArray[base + clLastRow(col, arg_11_0.clOffset, clRows)])

                        return true
                    end
                elseif CloverPadUI.pressed.left or CloverPadUI.pressed.right then
                    local other = 3 - col
                    local last = clLastRow(other, arg_11_0.clOffset, clRows)

                    if last > 0 then
                        GUI:focusElement(arg_11_0.elementArray[(other - 1) * clStride + math.min(row, last)])
                    end

                    return true
                end
            end
        end
    end

    return gui_container.onElementCommand(arg_11_0, arg_11_1, arg_11_2)
end

function sys_option_languages.onElementFocus(arg_12_0, arg_12_1)
    gui_container.onElementFocus(arg_12_0, arg_12_1)

    if arg_12_1 and arg_12_1 ~= arg_12_0 then
        local var_12_0 = table_find(arg_12_0.elementArray, arg_12_1)

        if arg_12_0.isFirstMode and arg_12_0.decideButton then
            if var_12_0 == 5 or var_12_0 == 10 then
                arg_12_0.disabledVertical = true

                arg_12_0.decideButton:activate()
            else
                arg_12_0.disabledVertical = false

                arg_12_0.decideButton:deactivate()
            end
        end
    end
end

function sys_option_languages.onButtonClick(arg_13_0, arg_13_1)
    if arg_13_1 and arg_13_1 ~= arg_13_0 then
        local var_13_0 = table_find(arg_13_0.elementArray, arg_13_1)

        if arg_13_0.isFirstMode then
            if var_13_0 == 5 or var_13_0 == 10 then
                store.language_selected = true

                Main:toHomeMenu()

                return
            elseif var_13_0 >= 5 then
                var_13_0 = var_13_0 - 1
            end
        end

        local var_13_1 = arg_13_0.radiogroup:getSelectedButton()

        if arg_13_0.isFirstMode or var_13_1 == arg_13_1 then
            local var_13_2 = table_find_if(var_0_0, function(arg_14_0)
                return arg_14_0.caption == var_13_1.language
            end)
            local var_13_3 = var_0_0[var_13_2]

            if var_13_3.extra then
                clApplyLocale(var_13_3)
                mcp.write_file_atomic(CL_ACTIVE, var_13_3.language)
                mcp.write_file_atomic(CL_UI, clUiLanguage(var_13_3.language))
            else
                if FileUtils.fileExists(CL_ACTIVE) then
                    FileUtils.deleteFile(CL_ACTIVE)
                end

                if FileUtils.fileExists(CL_UI) then
                    FileUtils.deleteFile(CL_UI)
                end

                system.setLocale(var_13_3.language, "", var_13_3.region)
            end

            local clStride, clRows = clGeometry(arg_13_0)

            if clStride and arg_13_0.clOffset then
                clRefresh(arg_13_0, clStride, clRows)
            end

            if arg_13_0.isFirstMode then
                if var_13_0 < 5 then
                    GUI:focusElement(arg_13_0.elementArray[5], true)
                else
                    GUI:focusElement(arg_13_0.elementArray[10], true)
                end
            end
        end
    end
end

function sys_option_languages.onCheckToggle(arg_15_0, arg_15_1, arg_15_2)
    arg_15_0.radiogroup:onCheckToggle(arg_15_1, arg_15_2)
end
