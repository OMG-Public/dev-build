Citizen.CreateThread(function()
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
    local player = _player_get_identifier(source)
    if PlayersData[player] ~= nil then
        TriggerClientEvent('OMG:initializeinfo', source, PlayersData[player].money, PlayersData[player].dirtyMoney, PlayersData[player].bankBalance, PlayersData[player].job)
    end
end)

AddEventHandler('playerConnecting', function(playerName, setKickReason)
    local source = source
    local player = GetPlayerInfoToCache(source)
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


AddEventHandler('playerDropped', function(reason)
    local i = 0
    for k,v in pairs(PlayersData) do
        local i = i + 1
        if v.ServerID == source then
            if omg_framework._display_logs then
                print("Player "..v.ServerID.." dropped, saving data.")
            end
            SavePlayerCache(v.identifier, v)
        end
    end
end)


function SaveDynamicCache()
    local i = 0
    for k,v in pairs(PlayersData) do
        local i = i + 1
        if GetPlayerPing(v.ServerID) == 0 then -- If 0, that mean the player is not connected anymore (i suppose, need some test)
            table.remove(PlayersData, i)
            if omg_framework._display_logs then
                print("Removing "..v.ServerID.." - "..i.." from dynamic cache.")
            end
        else
            SavePlayerCache(v.identifier, v)
        end
    end
end


-- Call this to save user infos to database (identifier + cache table)
function SavePlayerCache(id, cache)
    local encodedInv = EncodeInventory(cache.inventory)
    MySQL.Async.execute("UPDATE player_account SET player_inv = @inv, player_money = @money, player_bank_balance = @bankBalance, player_dirty_money = @bankBalance, player_dirty_money = @dirtyMoney, player_job = @job, player_group = @group, player_permission_level = @permission WHERE player_identifier = @identifier", {
        ['@identifier'] = id,
        ['@inv'] = encodedInv,
        ['@money'] = cache.money,
        ['@bankBalance'] = cache.bankBalance,
        ['@dirtyMoney'] = cache.dirtyMoney,
        ['@job'] = cache.job,
        ['@group'] = cache.group,
        ['@permission'] = cache.permission,
    })

    if omg_framework._display_logs then
        print("Saving "..id.." cache: "..encodedInv, cache.money, cache.bankBalance, cache.dirtyMoney, cache.job, cache.group, cache.permission)
    end
end

-- Call this on player connexion
function GetPlayerInfoToCache(id)
    local player = _player_get_identifier(id)
    PlayersData[player] = {} -- Init the player PlayerData or it will not work
    local info = MySQL.Sync.fetchAll("SELECT * FROM player_account WHERE player_identifier = @identifier", {
        ['@identifier'] = player
    })
    
    if info[1] ~= nil then
        PlayersData[player].ServerID = id
        PlayersData[player].identifier = player
        PlayersData[player].inventory = DecodeInventory(info[1].player_inv)
        PlayersData[player].money = info[1].player_money
        PlayersData[player].bankBalance = info[1].player_bank_balance
        PlayersData[player].dirtyMoney = info[1].player_dirty_money
        PlayersData[player].job = info[1].player_job
        PlayersData[player].group = info[1].player_group
        PlayersData[player].permission = info[1].player_permission_level
        DebugPrint("Adding ["..id.."] "..GetPlayerName(id).." to dynamic cache.")
    end
    return info
end

