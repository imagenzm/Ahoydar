if not Ahoydar then Ahoydar = {} end

local Ahoydar = Ahoydar

----------------------------------------------------------------
-- ПАРАМЕТРЫ ОКНА И ЯЧЕЕК
----------------------------------------------------------------
local WINDOW_WIDTH  = 900
local WINDOW_HEIGHT = 820

local DAY_CELL_WIDTH  = 110
local DAY_CELL_HEIGHT = 110

local CELL_GAP = 5

local NUM_COLUMNS = 7
local NUM_ROWS    = 6

local WEEKDAYS = { "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье" }

-- Таблица русских названий месяцев
local ruMonths = {
    [1] = "Январь",
    [2] = "Февраль",
    [3] = "Март",
    [4] = "Апрель",
    [5] = "Май",
    [6] = "Июнь",
    [7] = "Июль",
    [8] = "Август",
    [9] = "Сентябрь",
    [10] = "Октябрь",
    [11] = "Ноябрь",
    [12] = "Декабрь",
}

-- Используем стандартную текстуру рамки
local BORDER_TEXTURE = "Interface\\DialogFrame\\UI-DialogBox-Border"

----------------------------------------------------------------
-- СОЗДАНИЕ ОСНОВНОГО ОКНА
----------------------------------------------------------------
if not Ahoydar.uiFrame then
    Ahoydar.uiFrame = CreateFrame("Frame", "AhoydarUIFrame", UIParent, "BackdropTemplate")
    Ahoydar.uiFrame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    Ahoydar.uiFrame:SetPoint("CENTER")
    Ahoydar.uiFrame:SetMovable(true)
    Ahoydar.uiFrame:EnableMouse(true)
    Ahoydar.uiFrame:RegisterForDrag("LeftButton")
    Ahoydar.uiFrame:SetScript("OnDragStart", Ahoydar.uiFrame.StartMoving)
    Ahoydar.uiFrame:SetScript("OnDragStop", Ahoydar.uiFrame.StopMovingOrSizing)
    Ahoydar.uiFrame:EnableKeyboard(true)
		Ahoydar.uiFrame:SetScript("OnKeyDown", function(self, key)
			if key == "ESCAPE" then
			self:Hide()
		end
	end)
    -- Заголовок "Ахойдарь" по центру
    local titleText = Ahoydar.uiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", Ahoydar.uiFrame, "TOP", 0, -10)
    titleText:SetText("Ахойдарь")
    titleText:SetFont(titleText:GetFont(), 18, "OUTLINE")
    
    local skinCheckButton = CreateFrame("Button", nil, Ahoydar.uiFrame, "UIPanelButtonTemplate")
    skinCheckButton:SetSize(120, 25)
    skinCheckButton:SetPoint("TOPLEFT", Ahoydar.uiFrame, "TOPLEFT", 10, -10)
    skinCheckButton:SetText("SkinCheck")
    skinCheckButton:SetScript("OnClick", function()
        if Ahoydar.SkinningCheck then
            Ahoydar.SkinningCheck:ShowSkinningPopup()
        else
            print("SkinningCheck модуль не найден!")
        end
    end)
    
    local closeButton = CreateFrame("Button", nil, Ahoydar.uiFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(70, 25)
    closeButton:SetPoint("TOPRIGHT", Ahoydar.uiFrame, "TOPRIGHT", -10, -10)
    closeButton:SetText("Закрыть")
    closeButton:SetScript("OnClick", function()
        Ahoydar.uiFrame:Hide()
    end)
    
    Ahoydar.uiFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = BORDER_TEXTURE,
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    Ahoydar.uiFrame:SetScript("OnHide", function()
        if Ahoydar.editFrame and Ahoydar.editFrame:IsShown() then
            Ahoydar.editFrame:Hide()
        end
        if Ahoydar.viewFrame and Ahoydar.viewFrame:IsShown() then
            Ahoydar.viewFrame:Hide()
        end
        if Ahoydar.iconPickerFrame and Ahoydar.iconPickerFrame:IsShown() then
            Ahoydar.iconPickerFrame:Hide()
        end
    end)
    
    Ahoydar.monthLabel = Ahoydar.uiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    Ahoydar.monthLabel:SetPoint("TOP", Ahoydar.uiFrame, "TOP", 0, -60)
    Ahoydar.monthLabel:SetText(ruMonths[date("*t").month] .. " " .. date("*t").year)
    
    local prevButton = CreateFrame("Button", nil, Ahoydar.uiFrame, "UIPanelButtonTemplate")
    prevButton:SetSize(30, 22)
    prevButton:SetPoint("TOPLEFT", Ahoydar.uiFrame, "TOPLEFT", 350, -60)
    prevButton:SetText("<")
    prevButton:SetScript("OnClick", function()
        Ahoydar:ChangeMonth(-1)
    end)

    local nextButton = CreateFrame("Button", nil, Ahoydar.uiFrame, "UIPanelButtonTemplate")
    nextButton:SetSize(30, 22)
    nextButton:SetPoint("TOPRIGHT", Ahoydar.uiFrame, "TOPRIGHT", -350, -60)
    nextButton:SetText(">")
    nextButton:SetScript("OnClick", function()
        Ahoydar:ChangeMonth(1)
    end)

    Ahoydar.weekdayLabels = {}
    do
        local totalGridWidth = NUM_COLUMNS * DAY_CELL_WIDTH + (NUM_COLUMNS - 1) * CELL_GAP
        local startX = (WINDOW_WIDTH - totalGridWidth) / 2
        for i = 1, NUM_COLUMNS do
            local label = Ahoydar.uiFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            local xPos = startX + (i - 1) * (DAY_CELL_WIDTH + CELL_GAP) + (DAY_CELL_WIDTH / 2)
            label:SetPoint("TOP", Ahoydar.uiFrame, "TOPLEFT", xPos, -90)
            label:SetText(WEEKDAYS[i])
            Ahoydar.weekdayLabels[i] = label
        end
    end

    Ahoydar.dayCells = {}
    do
        local totalGridWidth = NUM_COLUMNS * DAY_CELL_WIDTH + (NUM_COLUMNS - 1) * CELL_GAP
        local startX = (WINDOW_WIDTH - totalGridWidth) / 2
        local startY = -110
        for row = 1, NUM_ROWS do
            for col = 1, NUM_COLUMNS do
                local index = (row - 1) * NUM_COLUMNS + col
                local cell = CreateFrame("Frame", nil, Ahoydar.uiFrame, "BackdropTemplate")
                cell:SetSize(DAY_CELL_WIDTH, DAY_CELL_HEIGHT)
                local xPos = startX + (col - 1) * (DAY_CELL_WIDTH + CELL_GAP)
                local yPos = startY - (row - 1) * (DAY_CELL_HEIGHT + CELL_GAP)
                cell:SetPoint("TOPLEFT", Ahoydar.uiFrame, "TOPLEFT", xPos, yPos)
                local commonBackdrop = {
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = BORDER_TEXTURE,
                    tile = false, tileSize = 16, edgeSize = 8,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 },
                }
                cell:SetBackdrop(commonBackdrop)
                cell:SetBackdropColor(0, 0, 0, 0.5)
                cell:SetBackdropBorderColor(1, 1, 1, 1)
                cell.dayNumber = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                cell.dayNumber:SetPoint("TOPLEFT", 5, -5)
                cell.dayNumber:SetText("")
                cell.eventsFrame = CreateFrame("Frame", nil, cell, "BackdropTemplate")
                cell.eventsFrame:SetSize(DAY_CELL_WIDTH - 10, DAY_CELL_HEIGHT - 25)
                cell.eventsFrame:SetPoint("TOPLEFT", cell, "TOPLEFT", 5, -20)
                cell.eventsFrame:EnableMouse(false)
                cell.eventIcons = {}
                cell:EnableMouse(true)
                
                cell:SetScript("OnEnter", function(self)
                    self:SetBackdropBorderColor(1, 1, 1, 1)
                    if self.realDay and self.realDay > 0 then
                        local events = Ahoydar:GetEvents(self.realDay)
                        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                        GameTooltip:ClearLines()
                        if events and #events > 0 then
                            GameTooltip:AddLine("События на " .. self.realDay, 1, 1, 1)
                            for i, event in ipairs(events) do
                                GameTooltip:AddLine(event.title, 1, 1, 1)
                            end
                        else
                            GameTooltip:AddLine("Нет событий", 1, 1, 1)
                        end
                        GameTooltip:AddLine("ЛКМ: просмотр событий\nПКМ: редактирование", 1, 1, 1)
                        GameTooltip:Show()
                    end
                end)

                cell:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                    local realDate = date("*t")
                    local todayKey = string.format("%04d-%02d-%02d", realDate.year, realDate.month, realDate.day)
                    local cellKey = string.format("%04d-%02d-%02d", Ahoydar.currentYear, Ahoydar.currentMonth, self.realDay or 0)
                    if cellKey == todayKey then
                        self:SetBackdropBorderColor(0, 0.75, 1, 1)
                    else
                        self:SetBackdropBorderColor(1, 1, 1, 1)
                    end
                end)

                cell:SetScript("OnMouseDown", function(self, button)
                    if self.realDay and self.realDay > 0 then
                        if button == "LeftButton" then
                            Ahoydar:OpenViewEventWindow(self.realDay)
                        elseif button == "RightButton" then
                            Ahoydar:OpenEditEventWindow(self.realDay)
                        end
                    end
                end)
                Ahoydar.dayCells[index] = cell
            end
        end
    end

    Ahoydar.uiFrame:Hide()
end

----------------------------------------------------------------
-- ОБНОВЛЕНИЕ КАЛЕНДАРЯ
----------------------------------------------------------------
function Ahoydar:UpdateCalendar()
    if not self.currentYear or not self.currentMonth then
        local currentDate = date("*t")
        self.currentYear = currentDate.year
        self.currentMonth = currentDate.month
    end

    local monthTime = time{year = self.currentYear, month = self.currentMonth, day = 1}
    self.monthLabel:SetText(ruMonths[self.currentMonth] .. " " .. self.currentYear)
    local firstDayInfo = date("*t", monthTime)
    local wdayEU = (firstDayInfo.wday == 1) and 7 or (firstDayInfo.wday - 1)
    local daysInMonth = date("*t", time{year = self.currentYear, month = self.currentMonth + 1, day = 0}).day
    local realDate = date("*t")
    local todayKey = string.format("%04d-%02d-%02d", realDate.year, realDate.month, realDate.day)
    for i, cell in ipairs(self.dayCells) do
        cell.dayNumber:SetText("")
        cell.realDay = 0
        cell:Hide()
        cell.isToday = false
        for _, icon in ipairs(cell.eventIcons) do
            icon:Hide()
        end
        wipe(cell.eventIcons)
    end
    local startIndex = wdayEU
    local dayCounter = 1
    for i = startIndex, startIndex + daysInMonth - 1 do
        local cell = self.dayCells[i]
        if not cell then break end
        cell:Show()
        cell.dayNumber:SetText(dayCounter)
        cell.realDay = dayCounter
        local cellKey = string.format("%04d-%02d-%02d", self.currentYear, self.currentMonth, dayCounter)
        local backdrop = {
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = BORDER_TEXTURE,
            tile = false, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        }
        cell:SetBackdrop(backdrop)
        if cellKey == todayKey then
            cell.isToday = true
            cell:SetBackdropColor(0, 0.75, 1, 0.3)  -- Фон чуть прозрачный
            cell:SetBackdropBorderColor(0, 0.75, 1, 1)  -- Голубая рамка для сегодняшнего дня
            cell.dayNumber:SetTextColor(0, 0.75, 1, 1)   -- Номер дня голубой
        else
            cell:SetBackdropColor(0, 0, 0, 0.5)
            cell:SetBackdropBorderColor(1, 1, 1, 1)
            cell.dayNumber:SetTextColor(1, 1, 1, 1)
        end
        local eventsForDay = self:GetEvents(dayCounter)
        if eventsForDay and #eventsForDay > 0 then
            self:FillDayCellWithEvents(cell, eventsForDay)
            if cellKey == todayKey then
                cell:SetBackdropBorderColor(0, 0.75, 1, 1)
                for _, icon in ipairs(cell.eventIcons) do
                    if icon.text then
                        icon.text:SetTextColor(0, 0.75, 1, 1)
                    end
                end
            end
        end
        dayCounter = dayCounter + 1
    end
end

----------------------------------------------------------------
-- ChangeMonth
----------------------------------------------------------------
function Ahoydar:ChangeMonth(delta)
    if not self.currentYear or not self.currentMonth then
        local currentDate = date("*t")
        self.currentYear = currentDate.year
        self.currentMonth = currentDate.month
    end

    self.currentMonth = self.currentMonth + delta
    if self.currentMonth < 1 then
        self.currentMonth = 12
        self.currentYear = self.currentYear - 1
    elseif self.currentMonth > 12 then
        self.currentMonth = 1
        self.currentYear = self.currentYear + 1
    end
    self:UpdateCalendar()
end

----------------------------------------------------------------
-- ЗАПОЛНЕНИЕ ЯЧЕЕК (СОБЫТИЯ)
----------------------------------------------------------------
function Ahoydar:FillDayCellWithEvents(cell, eventsForDay)
    local numEvents = #eventsForDay
    if numEvents == 2 and WhitelistEvents and type(WhitelistEvents) == "table" then
        local whitelistBg1, whitelistBg2 = nil, nil
        for _, wEvent in ipairs(WhitelistEvents) do
            if eventsForDay[1].title == wEvent.title and wEvent.cellBackground then
                whitelistBg1 = wEvent.cellBackground
            end
            if eventsForDay[2].title == wEvent.title and wEvent.cellBackground then
                whitelistBg2 = wEvent.cellBackground
            end
        end
        if whitelistBg1 and whitelistBg2 then
            local tex1 = cell:CreateTexture(nil, "BACKGROUND")
            tex1:SetPoint("TOPLEFT", cell, "TOPLEFT", 1, -1)
            tex1:SetPoint("BOTTOMRIGHT", cell, "CENTER", -1, 1)
            tex1:SetTexture(whitelistBg1)
            table.insert(cell.eventIcons, tex1)  -- добавляем в список, чтобы потом очищать

            local tex2 = cell:CreateTexture(nil, "BACKGROUND")
            tex2:SetPoint("TOPLEFT", cell, "CENTER", 1, -1)
            tex2:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -1, 1)
            tex2:SetTexture(whitelistBg2)
            table.insert(cell.eventIcons, tex2)  -- добавляем в список
        else
            local whitelistBg = whitelistBg1 or whitelistBg2
            if whitelistBg then
                local currentBackdrop = cell:GetBackdrop() or {}
                currentBackdrop.bgFile = whitelistBg
                cell:SetBackdrop(currentBackdrop)
            end
        end
    else
        local whitelistBg = nil
        if WhitelistEvents and type(WhitelistEvents) == "table" then
            for _, eventData in ipairs(eventsForDay) do
                for _, wEvent in ipairs(WhitelistEvents) do
                    if eventData.title == wEvent.title and wEvent.cellBackground then
                        whitelistBg = wEvent.cellBackground
                        break
                    end
                end
                if whitelistBg then break end
            end
        end
        if whitelistBg then
            local currentBackdrop = cell:GetBackdrop() or {}
            currentBackdrop.bgFile = whitelistBg
            cell:SetBackdrop(currentBackdrop)
        end
    end

    local offsetFromBottom = 0
    for i, eventData in ipairs(eventsForDay) do
        if offsetFromBottom + 20 > cell.eventsFrame:GetHeight() then break end
        local iconFrame = CreateFrame("Frame", nil, cell.eventsFrame, "BackdropTemplate")
        iconFrame:SetSize(cell.eventsFrame:GetWidth(), 20)
        iconFrame:SetPoint("BOTTOMLEFT", cell.eventsFrame, "BOTTOMLEFT", 0, offsetFromBottom)
        iconFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
        })
        iconFrame:SetBackdropColor(0, 0, 0, 0)
        local text = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", iconFrame, "LEFT", 3, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        local originalTitle = eventData.title or "Событие"
        local maxChars = 33
        local truncatedTitle = originalTitle
        if #originalTitle > maxChars then
            truncatedTitle = string.sub(originalTitle, 1, maxChars - 3) .. "..."
        end
        text:SetText(truncatedTitle)
        iconFrame.text = text
        offsetFromBottom = offsetFromBottom + 22
        table.insert(cell.eventIcons, iconFrame)
    end

    local realDate = date("*t")
    local todayKey = string.format("%04d-%02d-%02d", realDate.year, realDate.month, realDate.day)
    local cellKey = string.format("%04d-%02d-%02d", self.currentYear, self.currentMonth, cell.realDay or 0)
    if cellKey == todayKey then
        cell:SetBackdropBorderColor(0, 0.75, 1, 1)
    end
end

----------------------------------------------------------------
-- parseDate (разбор даты в формате dd.mm.yyyy)
----------------------------------------------------------------
local function parseDate(dateStr)
    local d, m, y = dateStr:match("(%d%d)%.(%d%d)%.(%d%d%d%d)")
    if d and m and y then
        return tonumber(d), tonumber(m), tonumber(y)
    end
end

----------------------------------------------------------------
-- ОКНО ПРОСМОТРА СОБЫТИЙ
----------------------------------------------------------------
function Ahoydar:OpenViewEventWindow(day)
    if self.editFrame and self.editFrame:IsShown() then
        self.editFrame:Hide()
    end
    if not self.viewFrame then
        self.viewFrame = CreateFrame("Frame", "AhoydarViewEventFrame", UIParent, "BackdropTemplate")
        self.viewFrame:SetSize(400, 700)
        self.viewFrame:SetPoint("TOPLEFT", Ahoydar.uiFrame, "TOPRIGHT", 10, 0)
        self.viewFrame:SetMovable(true)
        self.viewFrame:EnableMouse(true)
        self.viewFrame:RegisterForDrag("LeftButton")
        self.viewFrame:SetScript("OnDragStart", self.viewFrame.StartMoving)
        self.viewFrame:SetScript("OnDragStop", self.viewFrame.StopMovingOrSizing)
        self.viewFrame:EnableKeyboard(true)
        self.viewFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then self:Hide() end
        end)
        
        self.viewFrame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = BORDER_TEXTURE,
            tile     = true, tileSize = 32, edgeSize = 32,
            insets   = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        self.viewFrame:SetBackdropColor(0, 0, 0, 1)
        
        local headerBg = self.viewFrame:CreateTexture(nil, "BACKGROUND")
        headerBg:SetPoint("TOPLEFT", 4, -4)
        headerBg:SetPoint("TOPRIGHT", -4, -4)
        headerBg:SetHeight(30)
        
        local header = self.viewFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        header:SetPoint("CENTER", headerBg, "CENTER", 0, 0)
        header:SetText("События на " .. day .. "." .. self.currentMonth .. "." .. self.currentYear)
        
        self.viewFrame.listFrame = CreateFrame("Frame", nil, self.viewFrame)
        self.viewFrame.listFrame:SetSize(360, 620)
        self.viewFrame.listFrame:SetPoint("TOP", self.viewFrame, "TOP", 0, -40)
        
        self.viewFrame.closeButton = CreateFrame("Button", nil, self.viewFrame, "UIPanelButtonTemplate")
        self.viewFrame.closeButton:SetSize(100, 25)
        self.viewFrame.closeButton:SetPoint("BOTTOM", self.viewFrame, "BOTTOM", 0, 10)
        self.viewFrame.closeButton:SetText("Закрыть")
        self.viewFrame.closeButton:SetNormalFontObject("GameFontNormal")
        self.viewFrame.closeButton:SetHighlightFontObject("GameFontHighlight")
        self.viewFrame.closeButton:SetScript("OnClick", function() self.viewFrame:Hide() end)
        
        self.viewFrame.eventList = {}
    end
    
    self.viewFrame.currentDay = day
    for _, entry in ipairs(self.viewFrame.eventList) do
        if entry.text then entry.text:Hide() end
        if entry.deleteButton then entry.deleteButton:Hide() end
        if entry.editButton then entry.editButton:Hide() end
        if entry.bg then entry.bg:Hide() end
    end
    wipe(self.viewFrame.eventList)
    
    local events = self:GetEvents(day)
    local yOffset = 0
    if events and #events > 0 then
        for i, event in ipairs(events) do
            local entry = {}
            entry.text = self.viewFrame.listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            entry.text:SetPoint("LEFT", self.viewFrame.listFrame, "TOPLEFT", 10, -yOffset - 5)
            entry.text:SetText(event.title or "Без названия")
            entry.text:SetTextColor(1, 1, 1, 1)
            
            entry.bg = self.viewFrame.listFrame:CreateTexture(nil, "BACKGROUND")
            entry.bg:SetSize(390, 25)
            entry.bg:SetPoint("LEFT", entry.text, "LEFT", -25, 0)
            entry.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
            entry.bg:Hide()
            
            entry.text:EnableMouse(true)
            entry.text:SetScript("OnEnter", function(self)
                entry.bg:Show()
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(event.title or "Без названия", 1, 1, 1)
                if event.description and event.description ~= "" then
                    GameTooltip:AddLine(event.description, 1, 1, 1, true)
                else
                    GameTooltip:AddLine("Нет описания", 1, 1, 1)
                end
                GameTooltip:Show()
            end)
            entry.text:SetScript("OnLeave", function(self)
                entry.bg:Hide()
                GameTooltip:Hide()
            end)
            
            entry.editButton = CreateFrame("Button", nil, self.viewFrame.listFrame, "UIPanelButtonTemplate")
            entry.editButton:SetSize(80, 20)
            entry.editButton:SetText("Редактировать")
            entry.editButton:SetPoint("RIGHT", self.viewFrame.listFrame, "TOPRIGHT", -90, -yOffset - 5)
            entry.editButton:SetScript("OnClick", function()
                Ahoydar:OpenEditEventWindow(day, i)
            end)
            
            entry.deleteButton = CreateFrame("Button", nil, self.viewFrame.listFrame, "UIPanelButtonTemplate")
            entry.deleteButton:SetSize(80, 20)
            entry.deleteButton:SetText("Удалить")
            entry.deleteButton:SetPoint("RIGHT", self.viewFrame.listFrame, "TOPRIGHT", -5, -yOffset - 5)
            entry.deleteButton:SetScript("OnClick", function()
                if event.id then
                    Ahoydar:DeleteEventByID(event.id)
                else
                    Ahoydar:DeleteEvent(day, i)
                end
                Ahoydar:UpdateCalendar()
                Ahoydar:OpenViewEventWindow(day)
            end)
            
            yOffset = yOffset + 25
            table.insert(self.viewFrame.eventList, entry)
        end
    else
        local entry = {}
        entry.text = self.viewFrame.listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        entry.text:SetPoint("CENTER", self.viewFrame.listFrame, "CENTER", 0, 0)
        entry.text:SetText("Нет событий")
        entry.text:SetTextColor(1, 1, 1, 1)
        table.insert(self.viewFrame.eventList, entry)
    end
    
    self.viewFrame:Show()
end

----------------------------------------------------------------
-- ОКНО РЕДАКТИРОВАНИЯ (Создание/Редактирование)
----------------------------------------------------------------
function Ahoydar:OpenEditEventWindow(day, index)
    if self.viewFrame and self.viewFrame:IsShown() then
        self.viewFrame:Hide()
    end
    if self.editFrame and self.editFrame:IsShown() and self.editFrame.currentDay == day and self.editFrame.currentIndex == index then
        self.editFrame:Hide()
        return
    end
    if not self.editFrame then
        self.editFrame = CreateFrame("Frame", "AhoydarEditFrame", UIParent, "BackdropTemplate")
        self.editFrame:SetSize(400, 700)
        self.editFrame:SetPoint("TOPLEFT", Ahoydar.uiFrame, "TOPRIGHT", 10, 0)
        self.editFrame:SetMovable(true)
        self.editFrame:EnableMouse(true)
        self.editFrame:RegisterForDrag("LeftButton")
        self.editFrame:SetScript("OnDragStart", self.editFrame.StartMoving)
        self.editFrame:SetScript("OnDragStop", self.editFrame.StopMovingOrSizing)
        self.editFrame:EnableKeyboard(true)
        self.editFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then self:Hide() end
        end)
        
        self.editFrame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = BORDER_TEXTURE,
            tile     = true, tileSize = 32, edgeSize = 32,
            insets   = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        self.editFrame:SetBackdropColor(0, 0, 0, 1)
        
        self.editFrame:SetScript("OnHide", function()
            if Ahoydar.datePickerFrame and Ahoydar.datePickerFrame:IsShown() then
                Ahoydar.datePickerFrame:Hide()
            end
        end)
        
        local header = self.editFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        header:SetPoint("TOP", self.editFrame, "TOP", 0, -10)
        header:SetText("Создать/Редактировать событие")
        
        local titleLabel = self.editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleLabel:SetPoint("TOPLEFT", self.editFrame, "TOPLEFT", 20, -50)
        titleLabel:SetText("Заголовок:")
        
        self.editFrame.titleBox = CreateFrame("EditBox", nil, self.editFrame, "InputBoxTemplate")
        self.editFrame.titleBox:SetSize(360, 30)
        self.editFrame.titleBox:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 0, -5)
        self.editFrame.titleBox:SetAutoFocus(true)
        self.editFrame.titleBox:SetScript("OnTextChanged", function(editBox, userInput)
            if not userInput then return end
            local newTitle = editBox:GetText()
            local foundDescription = nil
            if WhitelistEvents and type(WhitelistEvents) == "table" then
                for _, wEvent in ipairs(WhitelistEvents) do
                    if wEvent.title == newTitle then
                        foundDescription = wEvent.description
                        break
                    end
                end
            end
            if foundDescription then
                self.editFrame.descEditBox:SetText(foundDescription)
            else
                self.editFrame.descEditBox:SetText("")
            end
        end)
        
        local startDateLabel = self.editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        startDateLabel:SetPoint("TOPLEFT", self.editFrame.titleBox, "BOTTOMLEFT", 0, -40)
        startDateLabel:SetText("Начало:")
        
        self.editFrame.startDateBox = CreateFrame("EditBox", nil, self.editFrame, "InputBoxTemplate")
        self.editFrame.startDateBox:SetSize(150, 30)
        self.editFrame.startDateBox:SetPoint("TOPLEFT", startDateLabel, "BOTTOMLEFT", 0, -5)
        self.editFrame.startDateBox:SetAutoFocus(false)
        
        local endDateLabel = self.editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        endDateLabel:SetPoint("TOPLEFT", self.editFrame.startDateBox, "TOPRIGHT", 20, 0)
        endDateLabel:SetText("Окончание:")
        
        self.editFrame.endDateBox = CreateFrame("EditBox", nil, self.editFrame, "BackdropTemplate, InputBoxTemplate")
        self.editFrame.endDateBox:SetSize(150, 30)
        self.editFrame.endDateBox:SetPoint("TOPLEFT", endDateLabel, "BOTTOMLEFT", 0, -5)
        self.editFrame.endDateBox:SetAutoFocus(false)
        self.editFrame.endDateBox:SetScript("OnMouseDown", function()
            self:ShowDatePicker(self.editFrame.endDateBox)
        end)
        
        local descLabel = self.editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descLabel:SetPoint("TOPLEFT", self.editFrame.startDateBox, "BOTTOMLEFT", 0, -20)
        descLabel:SetText("Описание:")
        
        self.editFrame.descScroll = CreateFrame("ScrollFrame", nil, self.editFrame, "UIPanelScrollFrameTemplate, BackdropTemplate")
        self.editFrame.descScroll:SetSize(345, 400)
        self.editFrame.descScroll:SetPoint("TOPLEFT", descLabel, "BOTTOMLEFT", 0, -10)
        self.editFrame.descScroll:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true,
            tileSize = 16,
            edgeSize = 16,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        self.editFrame.descScroll:SetBackdropColor(0, 0, 0, 0.5)
        self.editFrame.descScroll:SetBackdropBorderColor(1, 1, 1, 1)
        
        self.editFrame.descEditBox = CreateFrame("EditBox", nil, self.editFrame.descScroll)
        self.editFrame.descEditBox:SetMultiLine(true)
        self.editFrame.descEditBox:SetSize(345, 400)
        self.editFrame.descEditBox:SetAutoFocus(false)
        self.editFrame.descEditBox:SetFontObject("ChatFontNormal")
        self.editFrame.descEditBox:SetJustifyH("LEFT")
        self.editFrame.descEditBox:SetJustifyV("TOP")
        self.editFrame.descEditBox:SetTextInsets(5, 5, 5, 5)
        self.editFrame.descEditBox:EnableMouse(true)
        self.editFrame.descEditBox:SetScript("OnMouseDown", function(editBox, button)
            editBox:SetFocus()
        end)
        
        self.editFrame.descScroll:EnableMouse(true)
        self.editFrame.descScroll:SetScript("OnMouseDown", function(scrollFrame, button)
            self.editFrame.descEditBox:SetFocus()
        end)
        self.editFrame.descScroll:SetScrollChild(self.editFrame.descEditBox)
        
        self.editFrame.doneCheckbox = CreateFrame("CheckButton", nil, self.editFrame, "UICheckButtonTemplate")
        self.editFrame.doneCheckbox:SetSize(24, 24)
        self.editFrame.doneCheckbox:SetPoint("TOPLEFT", self.editFrame.descScroll, "BOTTOMLEFT", 0, -10)
        self.editFrame.doneCheckbox.text = self.editFrame.doneCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.editFrame.doneCheckbox.text:SetPoint("LEFT", self.editFrame.doneCheckbox, "RIGHT", 5, 0)
        self.editFrame.doneCheckbox.text:SetText("Сделано данным персонажем")
        
        self.editFrame.saveButton = CreateFrame("Button", nil, self.editFrame, "UIPanelButtonTemplate")
        self.editFrame.saveButton:SetSize(100, 25)
        self.editFrame.saveButton:SetPoint("BOTTOMLEFT", self.editFrame, "BOTTOMLEFT", 20, 20)
        self.editFrame.saveButton:SetText("Сохранить")
        self.editFrame.saveButton:SetScript("OnClick", function()
            local titleText = self.editFrame.titleBox:GetText()
            local startDate = self.editFrame.startDateBox:GetText()
            local endDate   = self.editFrame.endDateBox:GetText()
            local descText  = self.editFrame.descEditBox:GetText()
            local done = self.editFrame.doneCheckbox:GetChecked()
            
            if titleText == "" then
                print("Заголовок не может быть пустым.")
                return
            end
            
            local sD, sM, sY = parseDate(startDate)
            local eD, eM, eY = parseDate(endDate)
            if not sD or not eD then
                print("Неверный формат даты. Используйте dd.mm.yyyy")
                return
            end
            
            local startTS = time({year=sY, month=sM, day=sD})
            local endTS   = time({year=eY, month=sM, day=eD})
            if endTS < startTS then
                print("Дата окончания не может быть раньше начала.")
                return
            end
            
            if self.editFrame.currentIndex then
                Ahoydar:EditEvent(day, self.editFrame.currentIndex, titleText, startDate, descText, endDate)
                local events = Ahoydar:GetEvents(day)
                if events and events[self.editFrame.currentIndex] then
                    events[self.editFrame.currentIndex].completed = done
                end
            else
                local daySec = 86400
                local eventId = nil
                if startTS < endTS then
                    eventId = "multi_" .. tostring(GetTime())
                end
                for t = startTS, endTS, daySec do
                    local dt = date("*t", t)
                    Ahoydar:AddEvent(dt.day, titleText, "Нет иконки", "Нет повторения", startDate, descText, endDate, dt.year, dt.month, eventId)
                    local key = string.format("%04d-%02d-%02d", dt.year, dt.month, dt.day)
                    if AhoydarDB.events[key] and #AhoydarDB.events[key] > 0 then
                        AhoydarDB.events[key][#AhoydarDB.events[key]].completed = done
                    end
                end
            end
            self:UpdateCalendar()
            self.editFrame:Hide()
        end)
        
        self.editFrame.deleteButton = CreateFrame("Button", nil, self.editFrame, "UIPanelButtonTemplate")
        self.editFrame.deleteButton:SetSize(100, 25)
        self.editFrame.deleteButton:SetPoint("BOTTOM", self.editFrame, "BOTTOM", 0, 20)
        self.editFrame.deleteButton:SetText("Удалить")
        self.editFrame.deleteButton:Hide()
        self.editFrame.deleteButton:SetScript("OnClick", function()
            if self.editFrame.currentIndex then
                local events = Ahoydar:GetEvents(day)
                local ev = events[self.editFrame.currentIndex]
                if ev and ev.id then
                    Ahoydar:DeleteEventByID(ev.id)
                    Ahoydar:UpdateCalendar()
                    Ahoydar:OpenViewEventWindow(day)
                else
                    Ahoydar:DeleteEvent(day, self.editFrame.currentIndex)
                    Ahoydar:UpdateCalendar()
                    Ahoydar:OpenViewEventWindow(day)
                end
            else
                print("Новое событие — нечего удалять.")
            end
        end)
        
        self.editFrame.cancelButton = CreateFrame("Button", nil, self.editFrame, "UIPanelButtonTemplate")
        self.editFrame.cancelButton:SetSize(100, 25)
        self.editFrame.cancelButton:SetPoint("BOTTOMRIGHT", self.editFrame, "BOTTOMRIGHT", -20, 20)
        self.editFrame.cancelButton:SetText("Отмена")
        self.editFrame.cancelButton:SetScript("OnClick", function()
            self.editFrame:Hide()
        end)
    end
    
    self.editFrame.currentDay = day
    self.editFrame.currentIndex = index
    
    local defaultDate = string.format("%02d.%02d.%04d", day, self.currentMonth, self.currentYear)
    self.editFrame.startDateBox:SetText(defaultDate)
    self.editFrame.endDateBox:SetText(defaultDate)
    self.editFrame.titleBox:SetText("")
    self.editFrame.descEditBox:SetText("")
    self.editFrame.selectedIcon = "Interface\\ICONS\\INV_Misc_QuestionMark"
    self.editFrame.deleteButton:Hide()
    
    if index then
        local events = Ahoydar:GetEvents(day)
        local ev = events[index]
        if ev then
            self.editFrame.titleBox:SetText(ev.title or "")
            if ev.startDate then
                self.editFrame.startDateBox:SetText(ev.startDate)
            end
            if ev.endDate then
                self.editFrame.endDateBox:SetText(ev.endDate)
            end
            local whitelistDesc = nil
            if WhitelistEvents and type(WhitelistEvents) == "table" then
                for _, wEvent in ipairs(WhitelistEvents) do
                    if wEvent.title == ev.title then
                        whitelistDesc = wEvent.description
                        break
                    end
                end
            end
            if whitelistDesc then
                self.editFrame.descEditBox:SetText(whitelistDesc)
            else
                self.editFrame.descEditBox:SetText(ev.description)
            end
            self.editFrame.selectedIcon = ev.icon or "Interface\\ICONS\\INV_Misc_QuestionMark"
            if ev.completed then
                self.editFrame.doneCheckbox:SetChecked(true)
            else
                self.editFrame.doneCheckbox:SetChecked(false)
            end
            self.editFrame.deleteButton:Show()
        end
    else
        self.editFrame.doneCheckbox:SetChecked(false)
    end
    
    self.editFrame:Show()
end

----------------------------------------------------------------
-- DATE PICKER
----------------------------------------------------------------
function Ahoydar:ShowDatePicker(targetEditBox)
    if not self.datePickerFrame then
        self.datePickerFrame = CreateFrame("Frame", "AhoydarDatePickerFrame", UIParent, "BackdropTemplate")
        self.datePickerFrame:SetSize(220, 200)
        self.datePickerFrame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile     = true, tileSize = 32, edgeSize = 32,
            insets   = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        self.datePickerFrame:SetFrameStrata("DIALOG")
        self.datePickerFrame:EnableKeyboard(true)
        self.datePickerFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then self:Hide() end
        end)
        self.datePickerFrame.dayButtons = {}
        local columns = 7
        local rows = 6
        local btnSize = 25
        local gap = 2
        local startX, startY = 10, -30
        for row = 1, rows do
            for col = 1, columns do
                local idx = (row - 1) * columns + col
                local btn = CreateFrame("Button", nil, self.datePickerFrame, "UIPanelButtonTemplate")
                btn:SetSize(btnSize, btnSize)
                btn:SetPoint("TOPLEFT", self.datePickerFrame, "TOPLEFT", startX + (col-1)*(btnSize+gap), startY - (row-1)*(btnSize+gap))
                btn:SetText("")
                btn:SetScript("OnClick", function()
                    if btn.dayNum and btn.dayNum > 0 then
                        local d = string.format("%02d.%02d.%04d", btn.dayNum, self.datePickerFrame.month, self.datePickerFrame.year)
                        targetEditBox:SetText(d)
                        self.datePickerFrame:Hide()
                    end
                end)
                self.datePickerFrame.dayButtons[idx] = btn
            end
        end
        self.datePickerFrame.header = self.datePickerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self.datePickerFrame.header:SetPoint("TOP", self.datePickerFrame, "TOP", 0, -5)
        self.datePickerFrame.header:SetText("Выберите дату")
        local prevBtn = CreateFrame("Button", nil, self.datePickerFrame, "UIPanelButtonTemplate")
        prevBtn:SetSize(20, 20)
        prevBtn:SetPoint("LEFT", self.datePickerFrame.header, "RIGHT", 10, 0)
        prevBtn:SetText("<")
        prevBtn:SetScript("OnClick", function()
            self:PopulateDatePicker(self.datePickerFrame.year, self.datePickerFrame.month - 1)
        end)
        local nextBtn = CreateFrame("Button", nil, self.datePickerFrame, "UIPanelButtonTemplate")
        nextBtn:SetSize(20, 20)
        nextBtn:SetPoint("LEFT", prevBtn, "RIGHT", 5, 0)
        nextBtn:SetText(">")
        nextBtn:SetScript("OnClick", function()
            self:PopulateDatePicker(self.datePickerFrame.year, self.datePickerFrame.month + 1)
        end)
        self.datePickerFrame:Hide()
    end

    self.datePickerFrame:ClearAllPoints()
    self.datePickerFrame:SetPoint("TOPLEFT", targetEditBox, "BOTTOMLEFT", 0, -2)
    self.datePickerFrame:Show()

    local now = date("*t")
    self:PopulateDatePicker(now.year, now.month)
end

function Ahoydar:PopulateDatePicker(year, month)
    if month < 1 then
        month = 12
        year = year - 1
    elseif month > 12 then
        month = 1
        year = year + 1
    end
    self.datePickerFrame.year = year
    self.datePickerFrame.month = month
    self.datePickerFrame.header:SetText(string.format("%s %d", date("%B", time{year=year, month=month, day=1}), year))
    local firstWeekday = date("*t", time{year=year, month=month, day=1}).wday
    local wdayEU = (firstWeekday == 1) and 7 or (firstWeekday - 1)
    local daysInMonth = date("*t", time{year=year, month=month+1, day=0}).day
    for i, btn in ipairs(self.datePickerFrame.dayButtons) do
        local dayNum = i - wdayEU
        if dayNum < 1 or dayNum > daysInMonth then
            btn:Hide()
            btn.dayNum = 0
        else
            btn:SetText(dayNum)
            btn.dayNum = dayNum
            btn:Show()
        end
    end
end

----------------------------------------------------------------
-- ToggleUI
----------------------------------------------------------------
function Ahoydar:ToggleUI()
    if self.uiFrame:IsShown() then
        self.uiFrame:Hide()
    else
        self.uiFrame:Show()
        self:UpdateCalendar()
    end
end

----------------------------------------------------------------
-- ФУНКЦИИ ПРЕДИМПОРТА С ОТБОРОМ ПО ТИПУ СОБЫТИЯ
----------------------------------------------------------------
function Ahoydar:LoadPreImportEvents(filterType)
    if not C_Calendar then
        print("Ahoydar: API календаря WoW недоступно!")
        return
    end

    local currentYear = date("*t").year
    local eventsToImport = {}

    local eventTypes = {"PvP", "PvE", "Праздники", "Прочее"}

    for month = 1, 12 do
        local daysInMonth = date("*t", time{year = currentYear, month = month + 1, day = 0}).day

        for day = 1, daysInMonth do
            local numEvents = C_Calendar.GetNumDayEvents(0, day)
            for eventIndex = 1, numEvents do
                local event = C_Calendar.GetDayEvent(0, day, eventIndex)
                if event then
                    local title = event.title or "Без названия"
                    local lowerTitle = string.lower(title)
                    local category = "Прочее"

                    if lowerTitle:find("pvp") or lowerTitle:find("полях боя") or lowerTitle:find("арене") then
                        category = "PvP"
                    elseif lowerTitle:find("подземелья") or lowerTitle:find("рейд") then
                        category = "PvE"
                    elseif lowerTitle:find("годовщина")
                        or lowerTitle:find("лунный фестиваль")
                        or lowerTitle:find("детская неделя")
                        or lowerTitle:find("любовная лихорадка")
                        or lowerTitle:find("хмельной фестиваль")
                        or lowerTitle:find("тыквовин")
                        or lowerTitle:find("сад чудес")
                        or lowerTitle:find("огненный солнцеворот")
                        or lowerTitle:find("день пирата")
                        or lowerTitle:find("зимний покров")
                        or lowerTitle:find("пиршество странника")
                        or lowerTitle:find("день мертвых")
                        or lowerTitle:find("праздник фейерверков")
                        or lowerTitle:find("неделя урожая") then
                        category = "Праздники"
                    end

                    if not filterType or filterType == category then
                        table.insert(eventsToImport, {
                            title = title,
                            description = event.description or "",
                            startDate = string.format("%02d.%02d.%04d", day, month, currentYear),
                            endDate = string.format("%02d.%02d.%04d", day, month, currentYear),
                            category = category,
                            selected = true,
                            eventType = event.eventType,
                        })
                    end
                end
            end
        end
    end

    self.preImportFrame.eventList = eventsToImport
    self:UpdatePreImportUI()
end

function Ahoydar:OpenPreImportWindow(filterType)
    if self.preImportFrame then
        self.preImportFrame:Show()
        self:LoadPreImportEvents(filterType)
        return
    end
    self.preImportFrame = CreateFrame("Frame", "AhoydarPreImportFrame", UIParent, "BackdropTemplate")
    self.preImportFrame:SetSize(500, 600)
    self.preImportFrame:SetPoint("CENTER")
    self.preImportFrame:SetMovable(true)
    self.preImportFrame:EnableMouse(true)
    self.preImportFrame:RegisterForDrag("LeftButton")
    self.preImportFrame:SetScript("OnDragStart", self.preImportFrame.StartMoving)
    self.preImportFrame:SetScript("OnDragStop", self.preImportFrame.StopMovingOrSizing)
    self.preImportFrame:EnableKeyboard(true)
    self.preImportFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:Hide() end
    end)
    self.preImportFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    self.preImportFrame:SetFrameStrata("DIALOG")
    
    local title = self.preImportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", self.preImportFrame, "TOP", 0, -10)
    title:SetText("Предимпорт событий")
    
    local eventTypes = {"Все типы", "PvP", "PvE", "Праздники", "Прочее"}
    local eventTypeDropdown = CreateFrame("Frame", "AhoydarEventTypeDropdown", self.preImportFrame, "UIDropDownMenuTemplate")
    eventTypeDropdown:SetPoint("TOPLEFT", self.preImportFrame, "TOPLEFT", 10, -40)
    UIDropDownMenu_SetWidth(eventTypeDropdown, 150)
    UIDropDownMenu_SetText(eventTypeDropdown, "Все типы")
    local dropdown = eventTypeDropdown
    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for i, eventType in ipairs(eventTypes) do
            info.text = eventType
            info.value = eventType
            info.func = function(button)
                UIDropDownMenu_SetSelectedValue(dropdown, button.value)
                UIDropDownMenu_SetText(dropdown, button.value)
                local selectedType = button.value
                if selectedType == "Все типы" then
                    selectedType = nil
                end
                print("Выбран тип события:", button.value)
                Ahoydar:LoadPreImportEvents(selectedType)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    self.preImportFrame.eventTypeDropdown = dropdown

    local scanButton = CreateFrame("Button", nil, self.preImportFrame, "UIPanelButtonTemplate")
    scanButton:SetSize(120, 25)
    scanButton:SetPoint("TOPLEFT", eventTypeDropdown, "TOPRIGHT", 10, 0)
    scanButton:SetText("Сканировать")
    scanButton:SetScript("OnClick", function()
        Ahoydar:AutoImportCalendarEvents()
    end)
    self.preImportFrame.scanButton = scanButton

    local scrollFrame = CreateFrame("ScrollFrame", nil, self.preImportFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(460, 450)
    scrollFrame:SetPoint("TOP", 0, -70)
    
    local contentFrame = CreateFrame("Frame")
    contentFrame:SetSize(460, 450)
    scrollFrame:SetScrollChild(contentFrame)
    
    self.preImportFrame.scrollFrame = scrollFrame
    self.preImportFrame.contentFrame = contentFrame
    self.preImportFrame.eventList = {}
    
    local importButton = CreateFrame("Button", nil, self.preImportFrame, "UIPanelButtonTemplate")
    importButton:SetSize(120, 25)
    importButton:SetPoint("BOTTOMLEFT", 10, 10)
    importButton:SetText("Импортировать")
    importButton:SetScript("OnClick", function()
        Ahoydar:ImportSelectedEvents()
        self.preImportFrame:Hide()
    end)
    
    local cancelButton = CreateFrame("Button", nil, self.preImportFrame, "UIPanelButtonTemplate")
    cancelButton:SetSize(120, 25)
    cancelButton:SetPoint("BOTTOMRIGHT", -10, 10)
    cancelButton:SetText("Отмена")
    cancelButton:SetScript("OnClick", function()
        self.preImportFrame:Hide()
    end)
    
    self.preImportFrame.importButton = importButton
    self.preImportFrame.cancelButton = cancelButton
    
    self:LoadPreImportEvents(filterType)
end

function Ahoydar:UpdatePreImportUI()
    local contentFrame = self.preImportFrame.contentFrame
    local oldChildren = { contentFrame:GetChildren() }
    for _, child in ipairs(oldChildren) do
        child:Hide()
        child:SetParent(nil)
    end
    local yOffset = -10
    for index, event in ipairs(self.preImportFrame.eventList) do
        local rowFrame = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
        rowFrame:SetSize(460, 20)
        rowFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
        
        local checkBox = CreateFrame("CheckButton", nil, rowFrame, "UICheckButtonTemplate")
        checkBox:SetSize(20, 20)
        checkBox:SetPoint("LEFT", rowFrame, "LEFT", 10, 0)
        checkBox:SetChecked(event.selected)
        checkBox:SetScript("OnClick", function(self)
            event.selected = self:GetChecked()
        end)
        
        local text = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", checkBox, "RIGHT", 5, 0)
        text:SetText(event.title .. " (" .. event.startDate .. ")")
        
        yOffset = yOffset - 25
    end
    local totalHeight = math.abs(yOffset)
    if totalHeight < 450 then
        totalHeight = 450
    end
    contentFrame:SetSize(460, totalHeight)
    self.preImportFrame.scrollFrame:UpdateScrollChildRect()
end

----------------------------------------------------------------
-- СЛЕШ-КОМАНДА ДЛЯ ПРЕДИМПОРТА
----------------------------------------------------------------
SLASH_AHOYDARIMPORT1 = "/adimport"
SLASH_AHOYDARIMPORT2 = "/ahoydarimport"
SlashCmdList["AHOYDARIMPORT"] = function(msg)
    local filterType = nil
    if msg and msg ~= "" then
        filterType = msg
    end
    Ahoydar:OpenPreImportWindow(filterType)
end
