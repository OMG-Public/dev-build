
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
    for k,v in pairs(PlayersData) do
        if v.ServerID == source then
            SavePlayerInventory(v.identifier, v.inventory)
            table.remove(PlayersData, k)
        end
    end
end)


function SaveDynamicCache()
    for k,v in pairs(PlayersData) do
        if GetPlayerPing(v.ServerID) == 0 then -- If 0, that mean the player is not connected anymore (i suppose, need some test)
            table.remove(PlayersData, k)
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



-- Call this to save inventory to database (identifier + inventory table)
function SavePlayerInventory(id, inv)
    local encodedInv = EncodeInventory(inv)
    MySQL.Async.execute("UPDATE player_account SET player_inv = @inv WHERE player_identifier = @identifier", {
        ['@identifier'] = id,
        ['@inv'] = encodedInv
    })

    if omg_framework._display_logs then
        print("Saving "..id.." inventory: "..encodedInv)
    end
end


function AddItemToPlayerInv(id, item, _count)
    if DoesItemExist(item) then
        local player = _player_get_identifier(id)
        local inv = PlayersData[player].inventory
        local invWeight = GetInvWeight(inv)
        local itemWeight = GetItemWeight(item, _count)
        DebugPrint(invWeight, itemWeight, invWeight + itemWeight)
        if invWeight + itemWeight <= omg_framework._default_player_max_weight then
            local countOld, num = GetItemCount(item, inv)
            if countOld == 0 then
                table.insert(inv, {name = item, count = _count})
            else
                DebugPrint(countOld, _count, countOld + _count)
                table.remove(inv, num)
                table.insert(inv, {name = item, count = countOld + _count})
            end

            PlayersData[player].inventory = inv

            -- To remove later 
            for k,v in pairs(PlayersData[player].inventory) do
                DebugPrint(""..v.name.." - x"..v.count.."")
            end
        else
            -- To do notification if can not hold the item
        end
    end
end

function RemoveItemFromPlayerInv(id, item, _count)
    if DoesItemExist(item) then
        local player = _player_get_identifier(id)
        local inv = PlayersData[player].inventory

        for k,v in pairs(inv) do
            if v.name == item then
                local count = v.count
                if count - _count <= 0 then -- So we don't get player with negative items 
                    table.remove(inv, k)
                else
                    table.remove(inv, k)
                    table.insert(inv, {name = item, count = count - _count})
                end
            end
        end

        PlayersData[player].inventory = inv

        -- To remove later / For debug only
        for k,v in pairs(PlayersData[player].inventory) do
            DebugPrint(""..v.name.." - x"..v.count.."")
        end
    end
end


function GetInvWeight(inv)
    local weight = 0
    for _,v in pairs(inv) do
        for _, i in pairs(items) do
            local itemWeight = i.weight
            weight = itemWeight * v.count
        end
    end
    return weight
end


function GetItemWeight(item, count)
    for _,v in pairs(items) do
        if item == v.name then
            return v.weight * count
        end
    end
end


function GetItemCount(item, inv)
    local found = false
    for k,v in pairs(inv) do 
        if v.name == item then
            found = true
            return v.count, k
        end
    end
    -- Not sure if the if is needed, i think the return stop the for, not sure tho
    if not found then
        return 0
    end
end


function DoesItemExist(item)
    local exist = false
    for k,v in pairs(items) do
        if v.name == item then
            exist = true
            return exist
        end
    end
    return exist
end

function EncodeInventory(inv)
    local invToJson = json.encode(inv)
    return invToJson
end


function DecodeInventory(inv)
    local JsonToTable = json.decode(inv)
    return JsonToTable
end 


local debug = true
function DebugPrint(text)
    if debug then
        print(text)
    end
end