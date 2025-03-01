-- DefaultEvents.lua
if not Ahoydar then Ahoydar = {} end

-- Функция добавления событий по умолчанию
function Ahoydar:AddDefaultEvents()
    -- Если база данных ещё не создана, создаём её
    if not AhoydarDB then
        AhoydarDB = { events = {}, settings = { showMinimap = true, soundEnabled = true } }
    end

    local currentYear = date("*t").year
    -- Добавляем событие, если текущий год больше или равен 1991
    if currentYear >= 1991 then
        local month = 1
        local day = 24
        local key = string.format("%04d-%02d-%02d", currentYear, month, day)
        if not AhoydarDB.events[key] then
            AhoydarDB.events[key] = {}
        end

        -- Проверяем, есть ли уже такое событие для текущего года
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
                icon = "Interface\\AddOns\\Ahoydar\\Textures\\inv_misc_celebrationcake_01.jpg",
                repeatOption = "Ежегодно",  -- помечаем как повторяющееся ежегодно
                startDate = string.format("%02d.%02d.%04d 00:00", day, month, currentYear),
                description = "День рождения основателя голдфармерского движения \"Жетон каждому малютке\"",
                endDate = string.format("%02d.%02d.%04d 23:59", day, month, currentYear),
                startYear = 1991,  -- событие повторяется с 1991 года
            })
            print("Добавлено событие 'День Ахоева рождения!' для года " .. currentYear)
        end
    end
end
