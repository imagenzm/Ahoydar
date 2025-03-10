-- AutoImport.lua
if not Ahoydar then Ahoydar = {} end

function Ahoydar:AutoImportCalendarEvents()
    if not C_Calendar then
        print("API календаря недоступно!")
        return
    end

    -- Открываем стандартный календарь, чтобы подгрузить данные
    C_Calendar.OpenCalendar()

    local monthInfo = C_Calendar.GetMonthInfo()
    if not monthInfo then
        print("Нет данных календаря. Попробуйте открыть календарь вручную.")
        return
    end

    local year = monthInfo.year
    local month = monthInfo.month
    local numDays = monthInfo.numDays

    for day = 1, numDays do
        local numEvents = C_Calendar.GetNumDayEvents(0, day)
        if numEvents and numEvents > 0 then
            for i = 1, numEvents do
                local event = C_Calendar.GetDayEvent(0, day, i)
                if event then
                    -- Проверяем, есть ли событие в белом списке (WhitelistEvents)
                    local allowed = false
                    if WhitelistEvents and type(WhitelistEvents) == "table" then
                        for _, wEvent in ipairs(WhitelistEvents) do
                            -- Используем поиск подстроки вместо строгого сравнения
                            if event.title and string.find(event.title, wEvent.title) then
                                allowed = true
                                break
                            end
                        end
                    end

                    if allowed then
                        -- Получаем таймстемпы начала и конца события
                        local startTS, endTS
                        if event.startTime and event.endTime then
                            -- Если поле day отсутствует, используем значение monthDay
                            if not event.startTime.day and event.startTime.monthDay then
                                event.startTime.day = event.startTime.monthDay
                            end
                            if not event.endTime.day and event.endTime.monthDay then
                                event.endTime.day = event.endTime.monthDay
                            end
                            startTS = time(event.startTime)
                            endTS   = time(event.endTime)
                        else
                            startTS = time{year=year, month=month, day=day, hour=0, min=0}
                            endTS   = time{year=year, month=month, day=day, hour=23, min=59}
                        end

                        if endTS < startTS then
                            endTS = startTS
                        end

                        local multiDayID = nil
                        local daySec = 86400
                        if endTS > startTS then
                            multiDayID = "multi_" .. tostring(GetTime()) .. "_" .. math.random(1000,9999)
                        end

                        -- Импортируем событие на каждый день диапазона
                        for t = startTS, endTS, daySec do
                            local dt = date("*t", t)
                            -- Импортируем событие только в пределах текущего месяца (при необходимости можно убрать проверку)
                            if dt.year == year and dt.month == month then
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

    print("Импорт событий текущего месяца завершён!")
    Ahoydar:UpdateCalendar()
end

local autoImportFrame = CreateFrame("Frame")
autoImportFrame:RegisterEvent("PLAYER_LOGIN")
autoImportFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(10, function()
            Ahoydar:AutoImportCalendarEvents()
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
