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
    local pCache = GetPlayerInfoToCache(source)
    TriggerClientEvent('OMG:initializeinfo', source, pCache.money, pCache.dirtyMoney, pCache.bankBalance, pCache.job)
    TriggerClientEvent("OMG:SendToken", source, token) -- Client side
end)

AddEventHandler('playerConnecting', function(playerName, setKickReason)
    local source = source
    local player = DoesPlayerExisit(source)
    if player[1] == nil then
        creation_utilisateur(source)

        if omg_framework._display_logs == true then
            print('' .. _L("new_user") .. '| '..playerName..'')
        end

    end
end)




PlayersData = {} -- Global for now, maybe turning it local later if not needed

Citizen.CreateThread(function()
    while true do
        SaveDynamicCache()
        Wait(omg_framework._cacheSave*(60*1000))
    end
end)


AddEventHandler('playerDropped', function(reason)
    for k,v in pairs(PlayersData) do
        if v.ServerID == source then
            if omg_framework._display_logs then
                print("Player "..v.ServerID.." dropped, saving data.")
            end
            SavePlayerCache(v.identifier, v)
        end
    end
end)


function SaveDynamicCache()
    local loop = 0
    for k,v in pairs(PlayersData) do
        loop = loop + 1
        if GetPlayerPing(v.ServerID) == 0 then -- If 0, that mean the player is not connected anymore (i suppose, need some test)
            if omg_framework._display_logs then
                print("Removing "..v.ServerID.." - "..loop.." from dynamic cache.")
            end
            table.remove(PlayersData, k)
        else
            SavePlayerCache(v.identifier, v)
        end
    end
end


-- Call this to save user infos to database (identifier + cache table)
function SavePlayerCache(id, cache)
    local encodedInv = EncodeInventory(cache.inventory)
    MySQL.Async.execute("UPDATE player_account SET player_position = @pos, player_inv = @inv, player_money = @money, player_bank_balance = @bankBalance, player_dirty_money = @bankBalance, player_dirty_money = @dirtyMoney, player_job = @job, player_group = @group, player_permission_level = @permission WHERE player_identifier = @identifier", {
        ['@identifier'] = id,
        ['@inv'] = encodedInv,
        ['@money'] = cache.money,
        ['@bankBalance'] = cache.bankBalance,
        ['@dirtyMoney'] = cache.dirtyMoney,
        ['@job'] = cache.job,
        ['@group'] = cache.group,
        ['@permission'] = cache.permission,
        ['@pos'] = cache.pos,
    })

    if omg_framework._display_logs then
        print("Saving "..id.." cache: "..encodedInv, cache.money, cache.bankBalance, cache.dirtyMoney, cache.job, cache.group, cache.permission)
    end
end


function DoesPlayerExisit(id)
    local player = _player_get_identifier(id)
    local info = MySQL.Sync.fetchAll("SELECT * FROM player_account WHERE player_identifier = @identifier", {
        ['@identifier'] = player
    })
    return info
end

-- Call this on player connexion
function GetPlayerInfoToCache(id)
    local player = _player_get_identifier(id)
    table.insert(PlayersData, {ServerID = id})
    --PlayersData[player] = {} -- Init the player PlayerData or it will not work
    local info = MySQL.Sync.fetchAll("SELECT * FROM player_account WHERE player_identifier = @identifier", {
        ['@identifier'] = player
    })
    
    if info[1] ~= nil then
        for k,v in pairs(PlayersData) do
            if v.ServerID == id then
                v.ServerID = id
                v.identifier = player
                v.inventory = DecodeInventory(info[1].player_inv)
                v.money = info[1].player_money
                v.bankBalance = info[1].player_bank_balance
                v.dirtyMoney = info[1].player_dirty_money
                v.job = info[1].player_job
                v.group = info[1].player_group
                v.permission = info[1].player_permission_level
                v.pos = info[1].player_position
                if omg_framework._display_logs then
                    print("Adding ["..id.."] "..GetPlayerName(id).." to dynamic cache.")
                end
                return v
            end
        end
    end
end

function GetPlayerCache(id)
    for k,v in pairs(PlayersData) do
        if v.ServerID == id then
            return k
        end
    end
end

-- type 1 = urgant! error
-- type 2 = success
-- type 3 = debugging
function Log(type, message)
    if(config.debug) then
        local str = ""
        if(type == 1) then
            str = "[^8OMG Logging^7] ^1"
        elseif(type == 2) then
            str = "[^2OMG Logging^7] "
        elseif(type == 3 or type == nil) then
            str = "[^4OMG Logging^7] "
        end

        str = str .. message
        return str 
    end
end