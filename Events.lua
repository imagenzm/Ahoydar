-- Events.lua
if not Ahoydar then Ahoydar = {} end

local Ahoydar = Ahoydar

function Ahoydar:GetEvents(day)
    local key = string.format("%04d-%02d-%02d", self.currentYear, self.currentMonth, day)
    return AhoydarDB.events[key] or {}
end

function Ahoydar:AddEvent(day, title, icon, repeatType, startDate, description, endDate, eventYear, eventMonth)
    eventYear = eventYear or self.currentYear
    eventMonth = eventMonth or self.currentMonth
    local key = string.format("%04d-%02d-%02d", eventYear, eventMonth, day)
    if not AhoydarDB.events[key] then
        AhoydarDB.events[key] = {}
    end
    table.insert(AhoydarDB.events[key], {
        title = title,
        icon = icon or "Interface\\ICONS\\INV_Misc_QuestionMark",
        repeatType = repeatType or "Нет повторения",
        startDate = startDate or "",
        description = description or "",
        endDate = endDate or ""
    })
    print("Ahoydar: Событие '" .. title .. "' добавлено на " .. key)
end

function Ahoydar:EditEvent(day, index, newTitle, newStartDate, newDescription, newEndDate)
    local key = string.format("%04d-%02d-%02d", self.currentYear, self.currentMonth, day)
    if not AhoydarDB.events[key] or not AhoydarDB.events[key][index] then
        print("Ahoydar: Ошибка! Попытка редактирования несуществующего события.")
        return
    end

    local event = AhoydarDB.events[key][index]
    event.title = newTitle or event.title
    event.startDate = newStartDate or event.startDate
    event.description = newDescription or event.description
    event.endDate = newEndDate or event.endDate

    print("Ahoydar: Событие успешно обновлено!")
end


function Ahoydar:DeleteEvent(day, index)
    local key = string.format("%04d-%02d-%02d", self.currentYear, self.currentMonth, day)
    if AhoydarDB.events[key] and AhoydarDB.events[key][index] then
        local title = AhoydarDB.events[key][index].title
        table.remove(AhoydarDB.events[key], index)
        print("Ahoydar: Событие '" .. title .. "' удалено!")
    end
end