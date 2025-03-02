-- TodayPopup.lua
if not Ahoydar then Ahoydar = {} end

-- Вспомогательная функция для обрезания пробелов по краям строки
local function strtrim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Функция для разбиения строки на подстроки по символам перевода строки
local function SplitLines(str)
    local t = {}
    for line in string.gmatch(str, "([^\r\n]+)") do
        local trimmed = strtrim(line)
        if trimmed ~= "" then
            table.insert(t, trimmed)
        end
    end
    return t
end

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
        frame:SetSize(400, 250)
        frame:SetPoint("CENTER")
        frame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 32, edgeSize = 16,
            insets   = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        frame:SetBackdropColor(0, 0, 0, 1)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        -- При закрытии основного окна закрываем и окно подтверждения, если оно открыто
        frame:SetScript("OnHide", function(self)
            if Ahoydar.linkConfirmPopup and Ahoydar.linkConfirmPopup:IsShown() then
                Ahoydar.linkConfirmPopup:Hide()
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

        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(360, 60)
        scrollFrame:SetPoint("TOP", descText, "BOTTOM", 0, -10)
        frame.scrollFrame = scrollFrame

        local container = CreateFrame("Frame", nil, scrollFrame)
        container:SetSize(360, 60)
        scrollFrame:SetScrollChild(container)
        frame.linkContainer = container

        local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        closeButton:SetSize(80, 25)
        closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
        closeButton:SetText("Закрыть")
        closeButton:SetScript("OnClick", function() frame:Hide() end)
        frame.closeButton = closeButton

        Ahoydar.todayPopup = frame
    end

    local popup = Ahoydar.todayPopup
    popup.line2:SetText('Не пропусти "' .. whitelistEvent.title .. '".')
    local fullDesc = whitelistEvent.description or ""
    local firstLine = fullDesc:match("^(.-)\n") or fullDesc
    popup.descText:SetText(firstLine)

    for _, child in ipairs({ popup.linkContainer:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    popup.linkList = {}

    local yOffset = -5
    for i, link in ipairs(whitelistEvent.links or {}) do
        local btn = CreateFrame("Button", nil, popup.linkContainer, "UIPanelButtonTemplate")
        btn:SetSize(340, 20)
        btn:SetPoint("TOPLEFT", popup.linkContainer, "TOPLEFT", 10, yOffset)
        btn:SetText("|cff00ff00[Смотреть видео " .. i .. "]|r")
        btn:SetScript("OnClick", function()
            Ahoydar:ConfirmLink(link)
        end)
        yOffset = yOffset - 25
        table.insert(popup.linkList, link)
    end
    popup.linkContainer:SetHeight(math.max(60, math.abs(yOffset)))

    popup:Show()
end

-- Функция, создающая окно подтверждения для ссылки (с возможностью копирования)
function Ahoydar:ConfirmLink(link)
    if not self.linkConfirmPopup then
        local frame = CreateFrame("Frame", "AhoydarLinkConfirmPopup", UIParent, "BackdropTemplate")
        frame:SetSize(400, 150)
        if Ahoydar.todayPopup and Ahoydar.todayPopup:IsShown() then
            frame:SetPoint("TOP", Ahoydar.todayPopup, "BOTTOM", 0, -10)
        else
            frame:SetPoint("CENTER")
        end
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        frame:SetBackdropColor(0, 0, 0, 1)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        
        local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        infoText:SetPoint("TOP", frame, "TOP", 0, -20)
        infoText:SetText("Перейти по ссылке?")
        frame.infoText = infoText
        
        local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        editBox:SetSize(360, 25)
        editBox:SetPoint("TOP", infoText, "BOTTOM", 0, -10)
        editBox:SetAutoFocus(false)
        frame.linkEditBox = editBox
        
        local okButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        okButton:SetSize(80, 25)
        okButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 10)
        okButton:SetText("ОК")
        okButton:SetScript("OnClick", function() frame:Hide() end)
        frame.okButton = okButton
        
        local copyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        copyButton:SetSize(80, 25)
        copyButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 10)
        copyButton:SetText("Скопировать")
        copyButton:SetScript("OnClick", function()
            print("Скопируйте ссылку: " .. frame.linkEditBox:GetText())
            frame:Hide()
        end)
        frame.copyButton = copyButton
        
        self.linkConfirmPopup = frame
    end
    self.linkConfirmPopup.linkEditBox:SetText(link)
    self.linkConfirmPopup:Show()
end

local popupFrame = CreateFrame("Frame")
popupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
popupFrame:SetScript("OnEvent", function(self, event, ...)
    C_Timer.After(11, function()
        Ahoydar:ShowTodayWhitelistPopup()
    end)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)
