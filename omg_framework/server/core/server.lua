AddEventHandler('onMySQLReady', function()
    config = {
        player_money = omg_framework._default_player_money,
        player_bank_balance = omg_framework._default_player_bank_balance,
        player_dirty_money = omg_framework._default_player_dirty_money,
		player_job = omg_framework._default_player_job,
    }
end)



function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dumpinitializeinfo(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

RegisterServerEvent('OMG:spawn') 
AddEventHandler('OMG:spawn', function()
    local source = source
    local player = _server_get_player_data_info(source)
    if player[1] ~= nil then
        TriggerClientEvent('OMG:initializeinfo', source, player[1].player_money, player[1].player_dirty_money, player[1].player_bank_balance, player[1].player_job)
    end
end)

AddEventHandler('playerConnecting', function(playerName, setKickReason)
    local source = source
    local player = _server_get_player_data_info(source)
    if player[1] == nil then
        creation_utilisateur(source)

        if omg_framework._display_logs == true then
            print('' .. _L("new_user") .. '| '..playerName..'')
        end

    end
end)




PlayersData = {} -- Global for now, maybe turning it local later if not needed

local second = 1000
local minute = 60*second
Citizen.CreateThread(function()
    while true do
        SaveDynamicCache()
        Wait(1*minute)
    end
end)


AddEventHandler('playerDropped', function (reason)
    local i = 0
    for k,v in pairs(PlayersData) do
        local i = i + 1
        if v.ServerID == source then
            SavePlayerInventory(v.identifier, v.inventory)
            table.remove(PlayersData, i)
        end
    end
end)


function SaveDynamicCache()
    local i = 0
    for k,v in pairs(PlayersData) do
        local i = i + 1
        if GetPlayerPing(v.ServerID) == 0 then -- If 0, that mean the player is not connected anymore (i suppose, need some test)
            table.remove(PlayersData, i)
        else
            SavePlayerInventory(v.identifier, v.inventory)
        end
    end
end

-- Call this on player connexion
function GetinventoryToCache(id)
    local player = _player_get_identifier(id)
    PlayersData[player] = {} -- Init the player PlayerData or it will not work
    local info = MySQL.Sync.fetchAll("SELECT player_inv FROM player_account WHERE player_identifier = @identifier", {
        ['@identifier'] = player
    })
    
    PlayersData[player].ServerID = id -- Will use this later to do dynamic cache logic
    PlayersData[player].identifier = player
    PlayersData[player].inventory = DecodeInventory(info[1].player_inv)
    DebugPrint("Adding ["..id.."] "..GetPlayerName(id).." to dynamic cache.")
end

