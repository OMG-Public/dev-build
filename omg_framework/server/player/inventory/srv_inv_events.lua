

RegisterNetEvent("OMG:GetPlayerInventory")
AddEventHandler("OMG:GetPlayerInventory", function()
    local player = _player_get_identifier(source)
    local inv = PlayersData[player].inventory
    TriggerClientEvent("OMG:SendPlayerInventory", source, inv)
end)


RegisterNetEvent("OMG:GiveItem")
AddEventHandler("OMG:GiveItem", function(token, item, count)
    if CheckToken(token, source) then
        AddItemToPlayerInv(source, item, count)
    end
end)