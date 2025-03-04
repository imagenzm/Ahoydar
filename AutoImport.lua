-- AutoImport.lua
if not Ahoydar then Ahoydar = {} end

-- Функция автоматического импорта событий текущего месяца с фильтрацией
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
            local key = string.format("%04d-%02d-%02d", year, month, day)
            if not AhoydarDB.events[key] then
                AhoydarDB.events[key] = {}
            end
            for i = 1, numEvents do
                local event = C_Calendar.GetDayEvent(0, day, i)
                if event then
                    -- Фильтруем событие по белому списку
                    local allowed = false
                    if WhitelistEvents and type(WhitelistEvents) == "table" then
                        for _, wEvent in ipairs(WhitelistEvents) do
                            if event.title and event.title == wEvent.title then
                                allowed = true
                                break
                            end
                        end
                    end
                    if allowed then
                        local exists = false
                        for _, ev in ipairs(AhoydarDB.events[key]) do
                            if ev.title == event.title then
                                exists = true
                                break
                            end
                        end
                        if not exists then
                            table.insert(AhoydarDB.events[key], {
                                title = event.title or "Без названия",
                                icon = event.icon or "Interface\\ICONS\\INV_Misc_QuestionMark",
                                repeatOption = "Нет повторения",
                                startDate = string.format("%02d.%02d.%04d 00:00", day, month, year),
                                description = event.description or "",
                                endDate = string.format("%02d.%02d.%04d 23:59", day, month, year),
                            })
                        end
                    end
                end
            end
        end
    end

    print("Импорт событий текущего месяца завершён!")
    Ahoydar:UpdateCalendar()
end


-- Фрейм для автоматического запуска импорта через 10 секунд после входа в игру
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
