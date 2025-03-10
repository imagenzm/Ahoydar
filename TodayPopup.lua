if not Ahoydar then Ahoydar = {} end

----------------------------------------------------------
-- ФУНКЦИЯ ПОИСКА ВСЕХ СОБЫТИЙ ИЗ БЕЛОГО СПИСКА НА СЕГОДНЯ
----------------------------------------------------------
function Ahoydar:GetTodayWhitelistEvents()
    local charName = UnitName("player") or "Unknown"
    local today = date("*t")
    local todayKey = string.format("%04d-%02d-%02d", today.year, today.month, today.day)
    local eventsFound = {}
    if AhoydarDB and AhoydarDB.events and AhoydarDB.events[todayKey] then
        for _, ev in ipairs(AhoydarDB.events[todayKey]) do
            local isCompleted = false
            if ev.completed then
                if type(ev.completed) == "table" then
                    isCompleted = ev.completed[charName]
                else
                    isCompleted = ev.completed
                end
            end
            if not isCompleted then
                if WhitelistEvents and type(WhitelistEvents) == "table" then
                    for _, wEvent in ipairs(WhitelistEvents) do
                        if ev.title == wEvent.title then
                            table.insert(eventsFound, wEvent)
                        end
                    end
                end
            end
        end
    end

    -- Дополнительное условие для события "Зов Скарабея" (уведомление за 5 дней до)
    for key, events in pairs(AhoydarDB.events or {}) do
        for _, ev in ipairs(events) do
            local isCompleted = false
            if ev.completed then
                if type(ev.completed) == "table" then
                    isCompleted = ev.completed[charName]
                else
                    isCompleted = ev.completed
                end
            end
            if ev.title and string.find(ev.title, "Зов Скарабея") and not isCompleted then
                local d, m, y = ev.startDate:match("(%d%d)%.(%d%d)%.(%d%d%d%d)")
                if d and m and y then
                    local eventTime = time({year = tonumber(y), month = tonumber(m), day = tonumber(d)})
                    local notifyTime = eventTime - (5 * 86400)
                    local notifyDate = date("*t", notifyTime)
                    local notifyKey = string.format("%04d-%02d-%02d", notifyDate.year, notifyDate.month, notifyDate.day)
                    local todayKey = string.format("%04d-%02d-%02d", today.year, today.month, today.day)
                    if todayKey == notifyKey then
                        if WhitelistEvents and type(WhitelistEvents) == "table" then
                            for _, wEvent in ipairs(WhitelistEvents) do
                                if ev.title == wEvent.title then
                                    table.insert(eventsFound, wEvent)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return eventsFound
end

----------------------------------------------------------
-- ФУНКЦИЯ ПОКАЗА ОКНА ДЛЯ ВСЕХ СОБЫТИЙ ИЗ БЕЛОГО СПИСКА
----------------------------------------------------------
function Ahoydar:ShowTodayWhitelistPopup()
    local whitelistEvents = self:GetTodayWhitelistEvents()
    if not whitelistEvents or #whitelistEvents == 0 then 
        return 
    end

    if not Ahoydar.todayPopup then
        local frame = CreateFrame("Frame", "AhoydarTodayPopup", UIParent, "BackdropTemplate")
        frame:SetSize(300, 300)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("TOOLTIP")
        frame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true,
            tileSize = 32,
            edgeSize = 32,
            insets   = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        frame:SetBackdropColor(0, 0, 0, 1)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:EnableKeyboard(true)
        frame:SetPropagateKeyboardInput(true)
        frame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then self:Hide() end
        end)

        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOP", frame, "TOP", 0, -10)
        header:SetText("Ахой! Amoraloff спешит на помощь!")
        header:SetJustifyH("CENTER")
        frame.header = header

        -- Контейнер для блоков событий с отступом 10 пикселей между заголовком и первым событием
        local blocksContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        blocksContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -20-10)
        blocksContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -20-10)
        blocksContainer:SetSize(280, 1)
        frame.blocksContainer = blocksContainer

        local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        closeButton:SetSize(80, 25)
        closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
        closeButton:SetText("Закрыть")
        closeButton:SetScript("OnClick", function() frame:Hide() end)
        frame.closeButton = closeButton

        Ahoydar.todayPopup = frame
    end

    local popup = Ahoydar.todayPopup
    popup:Show()

    local container = popup.blocksContainer
    for _, child in ipairs({ container:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = 0
    for i, wEvent in ipairs(whitelistEvents) do
        local eventBlock = CreateFrame("Frame", nil, container, "BackdropTemplate")
        eventBlock:SetSize(container:GetWidth(), 1)
        eventBlock:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -yOffset)

        local title = eventBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", eventBlock, "TOP", 0, -20)
        title:SetJustifyH("CENTER")
        title:SetText(wEvent.title or "Событие")

        local desc = eventBlock:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        desc:SetWidth(container:GetWidth() - 20)
        desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
        desc:SetJustifyH("CENTER")
        local firstLine = (wEvent.description or ""):match("^[^\r\n]+") or ""
        desc:SetText(firstLine)

        local linkOffset = 0
        if wEvent.links and #wEvent.links > 0 then
            for linkIndex, linkData in ipairs(wEvent.links) do
                local linkName = linkData.name or ("Ссылка " .. linkIndex)
                local linkURL  = linkData.url or ""
                
                local linkLabel = eventBlock:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                linkLabel:SetWidth(container:GetWidth() - 20)
                linkLabel:SetJustifyH("CENTER")
                linkLabel:SetPoint("TOP", desc, "BOTTOM", 0, -(15 + linkOffset))
                linkLabel:SetText(linkName)

                local editBox = CreateFrame("EditBox", nil, eventBlock, "InputBoxTemplate")
                editBox:SetSize(container:GetWidth() - 40, 25)
                editBox:SetPoint("TOP", linkLabel, "BOTTOM", 0, -2)
                editBox:SetAutoFocus(false)
                editBox:SetJustifyH("CENTER")
                editBox:SetText(linkURL)
                editBox:SetCursorPosition(0)

                local note = eventBlock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                note:SetWidth(container:GetWidth() - 40)
                note:SetJustifyH("CENTER")
                note:SetPoint("TOP", editBox, "BOTTOM", 0, -2)
                note:SetText("скопируй ссылку в браузер")

                linkOffset = linkOffset + 60
            end
        end

        local blockHeight = 60 + linkOffset + 30
        eventBlock:SetHeight(blockHeight)

        -- Чекбокс "Выполнено" перемещён под ссылки, его надпись теперь слева от чекбокса
        local completedCheckbox = CreateFrame("CheckButton", nil, eventBlock, "UICheckButtonTemplate")
        completedCheckbox:SetSize(20, 20)
        completedCheckbox:SetPoint("BOTTOMRIGHT", eventBlock, "BOTTOMRIGHT", -10, 5)
        completedCheckbox.text = completedCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        completedCheckbox.text:SetPoint("RIGHT", completedCheckbox, "LEFT", -5, 0)
        completedCheckbox.text:SetText("Выполнено")
        completedCheckbox:SetScript("OnClick", function(self)
            if self:GetChecked() then
                Ahoydar:MarkEventCompleted(wEvent.title)
            end
        end)

        yOffset = yOffset + blockHeight + 5
        if i < #whitelistEvents then
            local line = container:CreateTexture(nil, "ARTWORK")
            line:SetColorTexture(1, 1, 1, 0.3)
            line:SetSize(container:GetWidth(), 1)
            line:SetPoint("TOPLEFT", eventBlock, "BOTTOMLEFT", 0, -2)
            yOffset = yOffset + 3
        end
    end

    container:SetHeight(yOffset)
    local totalHeight = 10 + yOffset + 30
    popup:SetHeight(math.max(totalHeight, 300))
end

----------------------------------------------------------------
-- Автоматический вызов при входе в игру
----------------------------------------------------------------
local popupFrame = CreateFrame("Frame")
popupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
popupFrame:SetScript("OnEvent", function(self, event, ...)
    C_Timer.After(11, function()
        Ahoydar:ShowTodayWhitelistPopup()
    end)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)
