local ActiveFlashlights = {
    [8] = true
}
GlobalState.ActiveFlashlights = ActiveFlashlights

RegisterNetEvent("pickle_policejob:tools:goggles:setFlashlight", function(bool)
    local _source = source
    ActiveFlashlights[_source] = (bool and true or nil)
    GlobalState.ActiveFlashlights = ActiveFlashlights
end)