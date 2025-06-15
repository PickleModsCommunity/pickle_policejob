Departments = {}

function GetFormattedTime(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    local dayStr = days > 1 and "s" or ""
    if days > 0 then
        return string.format(("%d day"..dayStr .. " ").."%02d:%02d:%02d", days, hours, minutes, secs)
    else
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    end
end

function GetFormattedDate(seconds, date)
    local date = date or os.date("*t", seconds)
    local hour = date.hour
    local ampm = "AM"
    if hour >= 12 then
        ampm = "PM"
        if hour > 12 then
            hour = hour - 12
        end
    elseif hour == 0 then
        hour = 12
    end
    return string.format("%02d/%02d/%04d %02d:%02d %s", date.month, date.day, date.year, hour, date.min, ampm)
end

function RemoveFields(input, fields)
    local tbl = {}
    for k, v in pairs(input) do
        local found = false
        for i=1, #fields do
            if k == fields[i] then
                found = true
            end
        end
        if not found then
            tbl[k] = v
        end
    end
    return tbl
end