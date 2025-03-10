if not Ahoydar then Ahoydar = {} end

Ahoydar = CreateFrame("Frame", "Ahoydar", UIParent)
Ahoydar:RegisterEvent("ADDON_LOADED")
Ahoydar:RegisterEvent("PLAYER_LOGIN")
Ahoydar:RegisterEvent("PLAYER_ENTERING_WORLD")

function Ahoydar:Initialize()
    print("Ahoydar загружен! Введите /ad или /ahoydar для открытия календаря.")
    self:LoadEvents()
    
    if self.SetupMinimapButton then
        self:SetupMinimapButton()
    else
        print("Ahoydar: Ошибка! Функция SetupMinimapButton не найдена.")
    end

    if self.UpdateCalendar then
        self:UpdateCalendar()
    else
        print("Ahoydar: Ошибка! Функция UpdateCalendar не найдена.")
    end
end

function Ahoydar:LoadEvents()
    if not AhoydarDB then 
        AhoydarDB = { 
            events = {}, 
            settings = { 
                showMinimap = true, 
                soundEnabled = true 
            } 
        } 
    end
    Ahoydar:AddDefaultEvents()
end

function Ahoydar:CheckEventNotifications()
    local today = date("%Y-%m-%d")
    if AhoydarDB.events[today] then
        for _, event in ipairs(AhoydarDB.events[today]) do
            print("|cffffcc00[Ahoydar] Сегодня запланировано событие:|r " .. event.title)
            if AhoydarDB.settings.soundEnabled then
                PlaySound(888) -- Стандартный звук уведомления
            end
        end
    end
end

---------------------------------------------------
-- Функция добавления события
---------------------------------------------------
function Ahoydar:AddEvent(day, title, icon, repeatOption, startDate, description, endDate, year, month, id)
    year = year or self.currentYear
    month = month or self.currentMonth
    local key = string.format("%04d-%02d-%02d", year, month, day)
    if not AhoydarDB.events[key] then
        AhoydarDB.events[key] = {}
    end
    table.insert(AhoydarDB.events[key], {
        id = id,  -- id для связи копий многодневного события (nil для однодневного)
        title = title,
        icon = icon,
        repeatOption = repeatOption,
        startDate = startDate,
        description = description or "",
        endDate = endDate,
    })
    print("Событие добавлено: " .. title .. " в дату " .. key)
end

---------------------------------------------------
-- Функция удаления события по id (удаляет все копии)
---------------------------------------------------
function Ahoydar:DeleteEventByID(eventID)
    for k, events in pairs(AhoydarDB.events) do
        for i = #events, 1, -1 do
            if events[i].id == eventID then
                table.remove(events, i)
            end
        end
    end
    print("Ahoydar: событие удалено!")
    Ahoydar:UpdateCalendar()
end

---------------------------------------------------
-- Функция удаления события
---------------------------------------------------
function Ahoydar:DeleteEvent(day, index)
    local key = string.format("%04d-%02d-%02d", self.currentYear, self.currentMonth, day)
    if AhoydarDB.events[key] and AhoydarDB.events[key][index] then
        local event = AhoydarDB.events[key][index]
        if event.id then
            Ahoydar:DeleteEventByID(event.id)
        else
            table.remove(AhoydarDB.events[key], index)
            print("Ahoydar: Событие '" .. event.title .. "' удалено!")
        end
        Ahoydar:UpdateCalendar()
    end
end

---------------------------------------------------
-- Функция редактирования события
---------------------------------------------------
function Ahoydar:EditEvent(day, index, newTitle, newStartDate, newDescription, newEndDate)
    local key = string.format("%04d-%02d-%02d", self.currentYear, self.currentMonth, day)
    if not AhoydarDB.events[key] or not AhoydarDB.events[key][index] then
        print("Ahoydar: Ошибка! Попытка редактирования несуществующего события.")
        return
    end

    local event = AhoydarDB.events[key][index]
    if event.id then
        for k, events in pairs(AhoydarDB.events) do
            for i, e in ipairs(events) do
                if e.id == event.id then
                    e.title = newTitle or e.title
                    e.startDate = newStartDate or e.startDate
                    e.description = newDescription or e.description
                    e.endDate = newEndDate or e.endDate
                end
            end
        end
        print("Ahoydar: Многодневное событие '" .. newTitle .. "' успешно обновлено!")
    else
        event.title = newTitle or event.title
        event.startDate = newStartDate or event.startDate
        event.description = newDescription or event.description
        event.endDate = newEndDate or event.endDate
        print("Ahoydar: Событие успешно обновлено!")
    end
end

---------------------------------------------------
-- Обработка событий аддона
---------------------------------------------------
Ahoydar:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == "Ahoydar" then
        if not AhoydarDB then
            AhoydarDB = { events = {}, settings = { showMinimap = true, soundEnabled = true } }
        end
    elseif event == "PLAYER_LOGIN" then
        self.currentYear, self.currentMonth = date("*t").year, date("*t").month
        if self.Initialize then
            self:Initialize()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:CheckEventNotifications()
    end
end)

---------------------------------------------------
-- SLASH-команды
---------------------------------------------------
SLASH_AHOYDAR1 = "/ad"
SLASH_AHOYDAR2 = "/ahoydar"
SlashCmdList["AHOYDAR"] = function()
    if Ahoydar.ToggleUI then
        Ahoydar:ToggleUI()
    else
        print("Ahoydar: Функция ToggleUI не найдена.")
    end
end

---------------------------------------------------
-- Импорт событий из стандартного календаря WoW
function Ahoydar:ImportWoWCalendarEvents(filterType, excludeSystemEvents)
    print("Ahoydar: Запущен импорт событий за год...")

    if not C_Calendar then
        print("Ahoydar: API календаря WoW недоступно!")
        return
    end

    local currentYear = date("*t").year

    for month = 1, 12 do
        local daysInMonth = date("*t", time{year = currentYear, month = month + 1, day = 0}).day
        print("Ahoydar: Импорт событий за " .. month .. "/" .. currentYear)
        for day = 1, daysInMonth do
            local numEvents = C_Calendar.GetNumDayEvents(0, day)
            for eventIndex = 1, numEvents do
                local event = C_Calendar.GetDayEvent(0, day, eventIndex)
                if event then
                    if not (excludeSystemEvents and event.calendarType == "SYSTEM") and 
                       (not filterType or filterType == event.eventType) then

                        local title = event.title or "Без названия"
                        local description = event.description or ""
                        local startTimeTable = event.startTime or {year = currentYear, month = month, day = day}
                        local endTimeTable = event.endTime or {year = currentYear, month = month, day = day, hour = 23, min = 59, sec = 59}

                        if not startTimeTable.day and startTimeTable.monthDay then startTimeTable.day = startTimeTable.monthDay end
                        if not endTimeTable.day and endTimeTable.monthDay then endTimeTable.day = endTimeTable.monthDay end

                        local startTS = time(startTimeTable)
                        local endTS = time(endTimeTable)
                        if endTS < startTS then
                            endTS = startTS
                        end

                        local multiDayID = nil
                        local daySec = 86400
                        if endTS > startTS then
                            multiDayID = "multi_" .. tostring(GetTime()) .. "_" .. math.random(1000,9999)
                        end

                        for t = startTS, endTS, daySec do
                            local dt = date("*t", t)
                            if dt.year == currentYear and dt.month == month then
                                local key = string.format("%04d-%02d-%02d", dt.year, dt.month, dt.day)
                                if not AhoydarDB.events[key] then
                                    AhoydarDB.events[key] = {}
                                end

                                local exists = false
                                for _, ev in ipairs(AhoydarDB.events[key]) do
                                    if ev.title == event.title then
                                        exists = true
                                        break
                                    end
                                end

                                if not exists then
                                    table.insert(AhoydarDB.events[key], {
                                        id = multiDayID,
                                        title = event.title or "Без названия",
                                        icon = event.icon or "Interface\\ICONS\\INV_Misc_QuestionMark",
                                        repeatOption = "Нет повторения",
                                        startDate = date("%d.%m.%Y %H:%M", startTS),
                                        description = event.description or "",
                                        endDate = date("%d.%m.%Y %H:%M", endTS),
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    print("Ahoydar: Импорт завершён. Все события за год добавлены.")
    self:UpdateCalendar()
end

SLASH_AHOYDARIMPORT1 = "/adimport"
SlashCmdList["AHOYDARIMPORT"] = function(msg)
    print("Ahoydar: Начинаю импорт событий...")
    local filterType = nil
    local excludeSystem = false
    if Ahoydar.ImportWoWCalendarEvents then
        Ahoydar:ImportWoWCalendarEvents(filterType, excludeSystem)
    else
        print("Ahoydar: Функция импорта не найдена.")
    end
end

function Ahoydar:LoadPreImportEvents()
    if not C_Calendar then
        print("Ahoydar: API календаря WoW недоступно!")
        return
    end

    local currentYear = date("*t").year
    local eventsToImport = {}

    for month = 1, 12 do
        local daysInMonth = date("*t", time{year = currentYear, month = month + 1, day = 0}).day
        for day = 1, daysInMonth do
            local numEvents = C_Calendar.GetNumDayEvents(0, day)
            for eventIndex = 1, numEvents do
                local event = C_Calendar.GetDayEvent(0, day, eventIndex)
                if event then
                    table.insert(eventsToImport, {
                        title = event.title or "Без названия",
                        description = event.description or "",
                        startDate = string.format("%02d.%02d.%04d", day, month, currentYear),
                        endDate = string.format("%02d.%02d.%04d", day, month, currentYear),
                        selected = true
                    })
                end
            end
        end
    end

    self.preImportFrame.eventList = eventsToImport
    self:UpdatePreImportUI()
end

function Ahoydar:ImportSelectedEvents()
    for _, event in ipairs(self.preImportFrame.eventList) do
        if event.selected then
            local d, m, y = event.startDate:match("(%d%d)%.(%d%d)%.(%d%d%d%d)")
            Ahoydar:AddEvent(tonumber(d), event.title, "Interface\\ICONS\\INV_Misc_QuestionMark", "Нет повторения", event.startDate, event.description, event.endDate, tonumber(y), tonumber(m))
        end
    end
    print("Ahoydar: Импорт завершён!")
    self:UpdateCalendar()
end
