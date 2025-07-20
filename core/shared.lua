Templates = {}

function lerp(a, b, t) return a + (b-a) * t end

function v3(coords) return vec3(coords.x, coords.y, coords.z), coords.w end

function GetRandomInt(min, max, exclude)
    for i=1, 1000 do 
        local int = math.random(min, max)
        if exclude == nil or exclude ~= int then 
            return int
        end
    end
end

function debugPrint(...)
    if Config.Debug then
        print(...)
    end
end

function NumberWithCommas(x, noCurrency)
    local left, num, right = string.match(x, '^([^%d]*%d)(%d*)(.-)$')
    return (not noCurrency and "$" or "") .. left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())
end

function tolower(str)
    return string.lower(str)
end

function toupper(str)
    return string.upper(str)
end

function GetItemLabel(name)
    if Inventory.Items[name] then
        return Inventory.Items[name].label
    elseif Inventory.Items[toupper(name)] then
        return Inventory.Items[toupper(name)].label
    end
    return name
end

function GetCurrencyString(amount)
    return NumberWithCommas(amount)
end