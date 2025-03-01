-- Minimap.lua
if not Ahoydar then Ahoydar = {} end

local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
local LDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)

if not LDB or not LDBIcon then
    print("Ahoydar: Ошибка! Библиотеки LibDataBroker-1.1 и LibDBIcon-1.0 не найдены.")
    return
end

local broker = LDB:NewDataObject("Ahoydar", {
    type = "launcher",
    text = "Ahoydar",
    icon = "Interface\\AddOns\\Ahoydar\\Textures\\Ahoydar_icon.tga",
    OnClick = function(_, button)
        if button == "LeftButton" then
            if Ahoydar and Ahoydar.ToggleUI then
                Ahoydar:ToggleUI()
            else
                print("Ahoydar: ToggleUI не определена!")
            end
        elseif button == "RightButton" then
            -- Проверяем и инициализируем AhoydarDB, если его нет
            if not AhoydarDB then
                AhoydarDB = { settings = { showMinimap = true } }
            elseif not AhoydarDB.settings then
                AhoydarDB.settings = { showMinimap = true }
            end
            AhoydarDB.settings.showMinimap = not AhoydarDB.settings.showMinimap
            LDBIcon:Refresh("Ahoydar")
        end
    end,
})

function Ahoydar:SetupMinimapButton()
    -- Проверяем, зарегистрирован ли объект 'Ahoydar' перед регистрацией
    if not LDBIcon:IsRegistered("Ahoydar") then
        -- Проверяем и инициализируем AhoydarDB, если его нет
        if not AhoydarDB then
            AhoydarDB = { settings = { showMinimap = true } }
        elseif not AhoydarDB.settings then
            AhoydarDB.settings = { showMinimap = true }
        end
        LDBIcon:Register("Ahoydar", broker, AhoydarDB.settings)
    end
end
