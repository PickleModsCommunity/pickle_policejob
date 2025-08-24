local inArmory = false

function OpenArmory()
    if inArmory then return end
    inArmory = true
    lib.callback("pickle_policejob:openArmory", false, function(result, err)
        if not result then 
            inArmory = false
            return ShowNotification(err)
        end
        TriggerScreenblurFadeIn(250)
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "updateArmoryInfo",
            armoryInfo = {
                items = result,
            },
        })
    end)
end

function CloseArmory()
    inArmory = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "updateArmoryInfo",
    })
    TriggerScreenblurFadeOut(250)
end

RegisterNUICallback("buyArmoryItem", function(data, cb)
    cb("ok")
    TriggerServerEvent("pickle_policejob:buyArmoryItem", data)
end)

RegisterNUICallback("closeArmory", function(data, cb)
    cb("ok")
    CloseArmory()
end)