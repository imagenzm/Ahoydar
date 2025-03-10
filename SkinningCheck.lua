if not Ahoydar then Ahoydar = {} end

local SkinningCheck = {}

-- Функция для проверки, изучена ли профессия "Снятие шкур"
function SkinningCheck:IsSkinningLearned()
    local profs = { GetProfessions() }
    for _, prof in ipairs(profs) do
        if prof then
            local name = select(1, GetProfessionInfo(prof))
            if name and type(name) == "string" and name:find("Снятие шкур") then
                return true
            end
        end
    end
    return false
end

-- Функция для проверки квестов и формирования строки с результатами с окраской
function SkinningCheck:CheckQuests()
    local skinQuest1 = C_QuestLog.IsQuestFlaggedCompleted(74235)
    local skinQuest2 = C_QuestLog.IsQuestFlaggedCompleted(84259)
    local quest1Color = skinQuest1 and "|cff00ff00" or "|cffff0000"
    local quest2Color = skinQuest2 and "|cff00ff00" or "|cffff0000"
    local reset = "|r"
    return string.format("Кожа Кобры: %s%s%s\nНа Клыка: %s%s%s", quest1Color, tostring(skinQuest1), reset, quest2Color, tostring(skinQuest2), reset)
end

-- Новая функция, возвращающая true, если оба квеста выполнены
function SkinningCheck:AreAllQuestsCompleted()
    local skinQuest1 = C_QuestLog.IsQuestFlaggedCompleted(74235)
    local skinQuest2 = C_QuestLog.IsQuestFlaggedCompleted(84259)
    return skinQuest1 and skinQuest2
end

-- Функция, отмечающая событие как выполненное только для текущего персонажа
function Ahoydar:MarkEventCompleted(eventTitle)
    local charName = UnitName("player") or "Unknown"
    if not AhoydarDB or not AhoydarDB.events then return end
    for key, events in pairs(AhoydarDB.events) do
        for _, ev in ipairs(events) do
            if ev.title == eventTitle then
                if type(ev.completed) ~= "table" then
                    ev.completed = {}
                end
                ev.completed[charName] = true
            end
        end
    end
    print("Событие '" .. eventTitle .. "' отмечено как выполненное для персонажа " .. charName .. ".")
    if Ahoydar.UpdateCalendar then
        Ahoydar:UpdateCalendar()
    end
end

-- Функция для создания всплывающего окна с данными о выполнении
function SkinningCheck:ShowSkinningPopup()
    if not Ahoydar.skinningPopup then
        local frame = CreateFrame("Frame", "AhoydarSkinningPopup", UIParent, "BackdropTemplate")
        frame:SetSize(400, 150)
        if Ahoydar.todayPopup and Ahoydar.todayPopup:IsShown() then
            frame:SetPoint("BOTTOM", Ahoydar.todayPopup, "TOP", 0, 10)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        end
        frame:SetFrameStrata("HIGH")
        frame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 32, edgeSize = 32,
            insets   = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        frame:SetBackdropColor(0, 0, 0, 0.8)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:EnableKeyboard(true)
        frame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then self:Hide() end
        end)
        
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOP", frame, "TOP", 0, -20)
        header:SetText("Сбор ценных ресурсов снятие кожи")
        header:SetTextColor(0, 0.75, 1, 1)
        frame.header = header
        
        frame.description = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.description:SetPoint("TOP", header, "BOTTOM", 0, -10)
        frame.description:SetText("А ты не забыл снять шкуры с кобры и получить превосходный клык?")
        frame.description:SetTextColor(1, 1, 1, 1)
        
        frame.results = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.results:SetPoint("TOP", frame.description, "BOTTOM", 0, -10)
        frame.results:SetTextColor(1, 1, 1, 1)
        
        local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        closeBtn:SetSize(80, 25)
        closeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
        closeBtn:SetText("Закрыть")
        closeBtn:SetScript("OnClick", function() frame:Hide() end)
        frame.closeBtn = closeBtn

        Ahoydar.skinningPopup = frame
    end

    if self:AreAllQuestsCompleted() then
        -- Если все квесты выполнены, окно не показываем
        return
    end

    Ahoydar.skinningPopup.results:SetText(self:CheckQuests())
    Ahoydar.skinningPopup:Show()
end

-- Основная функция, вызываемая при входе в игру
function SkinningCheck:OnPlayerEnteringWorld()
    if self:IsSkinningLearned() and not self:AreAllQuestsCompleted() then
        self:ShowSkinningPopup()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, ...)
    SkinningCheck:OnPlayerEnteringWorld()
end)

Ahoydar.SkinningCheck = SkinningCheck
