-- DefaultEvents.lua
if not Ahoydar then Ahoydar = {} end

function Ahoydar:AddDefaultEvents()
    -- Если база данных ещё не создана, создаём её
    if not AhoydarDB then
        AhoydarDB = { events = {}, settings = { showMinimap = true, soundEnabled = true } }
    end

    local currentDate = date("*t")
    local currentYear = currentDate.year
    local currentMonth = currentDate.month

    -- Пример существующего события "День Ахоева рождения!"
    if currentYear >= 1991 then
        local month = 1
        local day = 24
        local key = string.format("%04d-%02d-%02d", currentYear, month, day)
        if not AhoydarDB.events[key] then
            AhoydarDB.events[key] = {}
        end
        local exists = false
        for _, ev in ipairs(AhoydarDB.events[key]) do
            if ev.title == "День Ахоева рождения!" then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(AhoydarDB.events[key], {
                title = "День Ахоева рождения!",
                icon = "Interface\\AddOns\\Ahoydar\\Textures\\inv_misc_celebrationcake_01.tga",
                repeatOption = "Ежегодно",
                startDate = string.format("%02d.%02d.%04d 00:00", day, month, currentYear),
                description = "День рождения основателя голдфармерского движения \"Жетон каждому малютке\"",
                endDate = string.format("%02d.%02d.%04d 23:59", day, month, currentYear),
            })
            print("Добавлено событие 'День Ахоева рождения!' для года " .. currentYear)
        end
    end
-- Добавляем событие "Среда" каждую среду текущего месяца
local currentDate = date("*t")
local currentYear = currentDate.year
local currentMonth = currentDate.month
local daysInMonth = date("*t", time{year = currentYear, month = currentMonth + 1, day = 0}).day
for day = 1, daysInMonth do
    local dt = date("*t", time{year = currentYear, month = currentMonth, day = day})
    if dt.wday == 4 then  -- В Lua wday: 1-воскресенье, 2-понедельник, ..., 4-среда
        local key = string.format("%04d-%02d-%02d", currentYear, currentMonth, day)
        if not AhoydarDB.events[key] then
            AhoydarDB.events[key] = {}
        end
        local exists = false
        for _, ev in ipairs(AhoydarDB.events[key]) do
            if ev.title == "Среда" then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(AhoydarDB.events[key], {
                title = "Среда",
                icon = "Interface\\AddOns\\Ahoydar\\Textures\\calendarwednesday.tga",
                repeatOption = "Еженедельно",
                startDate = string.format("%02d.%02d.%04d 00:00", day, currentMonth, currentYear),
                description = [[
Среда день прекрасный, тебя ждет хранилище.
Ну и таланты на твою профессию. Не забывай использовать контракт.
Выполнить викли задания, собрать сокровища и нпс заказы.
                ]],
                endDate = string.format("%02d.%02d.%04d 23:59", day, currentMonth, currentYear),
            })
            print("Добавлено событие 'Среда' для " .. key)
        end
    end
end

    -- Новый блок: добавить событие "Рыбоборье в Тайносводье" каждую субботу текущего месяца
    local daysInMonth = date("*t", time{year = currentYear, month = currentMonth + 1, day = 0}).day
    for day = 1, daysInMonth do
        local dt = date("*t", time{year = currentYear, month = currentMonth, day = day})
        -- В Lua: wday=1 это воскресенье, ..., 7 это суббота
        if dt.wday == 7 then
            local key = string.format("%04d-%02d-%02d", currentYear, currentMonth, day)
            if not AhoydarDB.events[key] then
                AhoydarDB.events[key] = {}
            end
            local exists = false
            for _, ev in ipairs(AhoydarDB.events[key]) do
                if ev.title == "Рыбоборье в Тайносводье" then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(AhoydarDB.events[key], {
                    title = "Рыбоборье в Тайносводье",
                    icon = "Interface\\AddOns\\Ahoydar\\Textures\\fish.tga",
                    repeatOption = "Еженедельно",
                    startDate = string.format("%02d.%02d.%04d 00:00", day, currentMonth, currentYear),
                    description = [[
Ивент для рыбаков каждую неделю.
Позволяет получить – Метку рыбоборья.
Валюта нужна для покупки алгарийской нити, чтобы усиливать твою удочку.
Ивент проходит каждую субботу.
                    ]],
                    endDate = string.format("%02d.%02d.%04d 23:59", day, currentMonth, currentYear),
                })
                print("Добавлено событие 'Рыбоборье в Тайносводье' для " .. key)
            end
        end
    end
end
