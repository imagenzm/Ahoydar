if not Ahoydar then Ahoydar = {} end

-- Core.lua
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
function Ahoydar:AddEvent(day, title, icon, repeatOption, startDate, description, endDate, year, month)
    local key = string.format("%04d-%02d-%02d", year, month, day)
    if not AhoydarDB.events[key] then
        AhoydarDB.events[key] = {}
    end
    table.insert(AhoydarDB.events[key], {
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
-- Функция удаления события
---------------------------------------------------
function Ahoydar:DeleteEvent(day, index)
    local key = string.format("%04d-%02d-%02d", self.currentYear, self.currentMonth, day)
    if AhoydarDB.events[key] and AhoydarDB.events[key][index] then
        local title = AhoydarDB.events[key][index].title
        if title == "День Ахоева рождения!" then
            print("Нельзя удалить событие 'День Ахоева рождения!'")
            return
        end
        table.remove(AhoydarDB.events[key], index)
        print("Ahoydar: Событие '" .. title .. "' удалено!")
    end
end

---------------------------------------------------
-- Функция редактирования события
---------------------------------------------------
function Ahoydar:EditEvent(day, index, title, startDate, description, endDate)
    local key = string.format("%04d-%02d-%02d", self.currentYear, self.currentMonth, day)
    if not AhoydarDB.events[key] or not AhoydarDB.events[key][index] then
        print("Событие не найдено для редактирования.")
        return
    end
    AhoydarDB.events[key][index].title = title
    AhoydarDB.events[key][index].startDate = startDate
    AhoydarDB.events[key][index].description = description or ""
    AhoydarDB.events[key][index].endDate = endDate
    print("Событие обновлено: " .. title)
end

---------------------------------------------------
-- Функция разбора даты в формате dd.mm.yyyy
---------------------------------------------------
local function parseDate(dateStr)
    local d, m, y = dateStr:match("(%d%d)%.(%d%d)%.(%d%d%d%d)")
    if d and m and y then
        return tonumber(d), tonumber(m), tonumber(y)
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

    -- Перебираем все 12 месяцев
    for month = 1, 12 do
        local daysInMonth = date("*t", time{year = currentYear, month = month + 1, day = 0}).day
        print("Ahoydar: Импорт событий за " .. month .. "/" .. currentYear)

        -- Перебираем все дни месяца
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

                        -- Проверяем, есть ли поле 'day'
                        if not startTimeTable.day then startTimeTable.day = day end
                        if not endTimeTable.day then endTimeTable.day = day end

                        local startTime = time(startTimeTable)
                        local endTime = time(endTimeTable)

                        local eventDay = date("%d", startTime)
                        local eventMonth = date("%m", startTime)
                        local eventYear = date("%Y", startTime)
                        local startDate = date("%d.%m.%Y", startTime)
                        local endDate = date("%d.%m.%Y", endTime)

                        -- Проверяем, есть ли уже такое событие
                        local key = string.format("%04d-%02d-%02d", eventYear, eventMonth, eventDay)
                        if not AhoydarDB.events[key] then
                            AhoydarDB.events[key] = {}
                        end

                        local exists = false
                        for _, e in ipairs(AhoydarDB.events[key]) do
                            if e.title == title and e.startDate == startDate and e.endDate == endDate then
                                exists = true
                                break
                            end
                        end

                        -- Добавляем событие только если его ещё нет
                        if not exists then
                            self:AddEvent(
                                eventDay,
                                title,
                                "Interface\\ICONS\\INV_Misc_QuestionMark",
                                "Нет повторения",
                                startDate,
                                description,
                                endDate,
                                eventYear,
                                eventMonth
                            )
                            print("Ahoydar: Добавлено событие: " .. title .. " на " .. startDate)
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
    print("Ahoydar: Начинаю импорт событий...") -- Проверка вызова

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
            self:AddEvent(
                tonumber(d), 
                event.title, 
                "Interface\\ICONS\\INV_Misc_QuestionMark", 
                "Нет повторения", 
                event.startDate, 
                event.description, 
                event.endDate, 
                tonumber(y), 
                tonumber(m)
            )
        end
    end
    print("Ahoydar: Импорт завершён!")
    self:UpdateCalendar()
end