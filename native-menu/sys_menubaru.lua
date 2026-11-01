-- sys_menubaru.lua of the NES and Famicom Mini UIs (stock md5 5fbe9d6a), changed to give the Famicom Mini the 5-button bar
require("/scripts/core/core.lua")
require("/scripts/helper_index.lua")
require("/scripts/helper_nodes.lua")

sys_menubarU = class(gui_container)

function sys_menubarU.start(arg_1_0)
    gui_container.start(arg_1_0)

    if system.is_hvc() or system.is_nes() then
        if arg_1_0.bar_hvc then
            arg_1_0.bar_hvc:disable()
        end

        if arg_1_0.bar_nes then
            arg_1_0.bar_nes:enable()
        end
    end
end

function sys_menubarU.activate(arg_2_0)
    gui_container.activate(arg_2_0)

    if arg_2_0.active_position then
        arg_2_0.active_position:changeAnimation()
    end

    if arg_2_0.menu then
        arg_2_0.menu:hudSelect("menubar")
    end
end

function sys_menubarU.deactivate(arg_3_0)
    gui_container.deactivate(arg_3_0)

    if arg_3_0.active_position then
        arg_3_0.active_position:revertAnimation()
    end
end

function sys_menubarU.onButtonClick(arg_4_0, arg_4_1)
    local var_4_0 = table_find(arg_4_0.elementArray, arg_4_1)

    if var_4_0 then
        if var_4_0 == 1 then
            Main:toDisplay()
        elseif var_4_0 == 2 then
            Main:toSettings()
        elseif var_4_0 == 3 then
            Main:toLanguages()
        elseif var_4_0 == 4 then
            Main:toCopyRight()
        elseif var_4_0 == 5 then
            Main:toManual()
        end
    end
end

function sys_menubarU.onContainerCanceled(arg_5_0, arg_5_1)
    GUI:focusElement(arg_5_0.downElement)
    arg_5_0:deactivate()
end
