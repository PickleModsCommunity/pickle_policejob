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
