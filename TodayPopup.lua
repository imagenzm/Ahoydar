-- TodayPopup.lua
if not Ahoydar then Ahoydar = {} end

-- Функция для поиска события из белого списка в AhoydarDB для сегодняшней даты
function Ahoydar:GetTodayWhitelistEvent()
    local today = date("*t")
    local key = string.format("%04d-%02d-%02d", today.year, today.month, today.day)
    if not AhoydarDB or not AhoydarDB.events or not AhoydarDB.events[key] then
        return nil
    end

    local eventsToday = AhoydarDB.events[key]
    if not WhitelistEvents or type(WhitelistEvents) ~= "table" then
        return nil
    end

    for _, event in ipairs(eventsToday) do
        for _, whitelistEntry in ipairs(WhitelistEvents) do
            if event.title == whitelistEntry.title then
                return whitelistEntry
            end
        end
    end
    return nil
end

-- Функция, показывающая всплывающее окно для события из белого списка
function Ahoydar:ShowTodayWhitelistPopup()
    local whitelistEvent = self:GetTodayWhitelistEvent()
    if not whitelistEvent then return end

    if not Ahoydar.todayPopup then
        local frame = CreateFrame("Frame", "AhoydarTodayPopup", UIParent, "BackdropTemplate")
        frame:SetSize(400, 300)
        frame:SetPoint("CENTER")
frame:SetBackdrop({
  bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile     = true, tileSize = 32, edgeSize = 32,
  insets   = { left = 8, right = 8, top = 8, bottom = 8 },
})
frame:SetBackdropColor(0, 0, 0, 1)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        
        -- Позволяем закрытие окна по ESC
        frame:EnableKeyboard(true)
        frame:SetPropagateKeyboardInput(true)
        frame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:Hide()
            end
        end)

        local line1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        line1:SetPoint("TOP", frame, "TOP", 0, -20)
        line1:SetText("Amoraloff спешит на помощь!")
        frame.line1 = line1

        local line2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        line2:SetPoint("TOP", line1, "BOTTOM", 0, -10)
        frame.line2 = line2

        local descText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        descText:SetPoint("TOP", line2, "BOTTOM", 0, -10)
        descText:SetJustifyH("CENTER")
        frame.descText = descText

        -- Контейнер для полей ввода ссылок
        local linksContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        linksContainer:SetSize(360, 100)
        linksContainer:SetPoint("TOP", descText, "BOTTOM", 0, -10)
        frame.linksContainer = linksContainer

        local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        closeButton:SetSize(80, 25)
        closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
        closeButton:SetText("Закрыть")
        closeButton:SetScript("OnClick", function() frame:Hide() end)
        frame.closeButton = closeButton

        -- Надпись-подсказка под ссылками
        local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOP", linksContainer, "BOTTOM", 0, 10)
        hint:SetText("скопируй ссылку в бразуер")
        hint:SetJustifyH("CENTER")
        frame.hint = hint
		
        Ahoydar.todayPopup = frame
    end

    local popup = Ahoydar.todayPopup
    popup:Show()
    popup.line2:SetText('Не пропусти "' .. whitelistEvent.title .. '".')

    -- Берём только первую строку из описания
    local fullDesc = whitelistEvent.description or ""
    local firstLine = fullDesc:match("^[^\r\n]+") or ""
    popup.descText:SetText(firstLine)

    -- Заполняем ссылки
    local container = popup.linksContainer
    for _, child in ipairs({ container:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = 0
    for i, linkEntry in ipairs(whitelistEvent.links or {}) do
        local linkName = "Ссылка " .. i
        local linkURL  = ""

        if type(linkEntry) == "table" then
            linkName = linkEntry.name or linkName
            linkURL  = linkEntry.url or ""
        else
            linkURL  = tostring(linkEntry)
        end

        -- Создаём текст ярлыка, выравниваем по центру
        local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetWidth(360)                   -- чтобы текст мог быть центрирован
        label:SetJustifyH("CENTER")
        label:SetPoint("TOP", container, "TOP", 0, -yOffset)
        label:SetText(linkName)
        yOffset = yOffset + 15

        -- Создаём поле ввода, выравниваем по центру
        local input = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
        input:SetSize(300, 25)                -- чуть уже контейнера, чтобы было видно края
        input:SetPoint("TOP", container, "TOP", 0, -yOffset)
        input:SetAutoFocus(false)
        -- Выравниваем текст в поле ввода по центру
        input:SetJustifyH("CENTER")
        input:SetText(linkURL)
        input:SetCursorPosition(0)

        yOffset = yOffset + 35
    end
    container:SetHeight(yOffset)
end

-- Фрейм для автоматической проверки при входе в игру (задержка 11 сек)
local popupFrame = CreateFrame("Frame")
popupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
popupFrame:SetScript("OnEvent", function(self, event, ...)
    C_Timer.After(11, function()
        Ahoydar:ShowTodayWhitelistPopup()
    end)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)
