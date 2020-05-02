
PlayersData = {} -- Global for now, maybe turning it local later if not needed


-- Call this on player connexion
function GetinventoryToCache(id)
    local player = _player_get_identifier(id)
    local info = MySQL.Sync.fetchAll("SELECT player_inv FROM player_account WHERE player_identifier = @identifier", {
        ['@identifier'] = player
    })
    PlayersData[player].inventory = DecodeInventory(info[1].player_inv)
end



-- Call this to save inventory to database (Server id + inventory table)
function SavePlayerInventory(id, inv)
    local player = _player_get_identifier(id)
    local encodedInv = EncodeInventory(inv)
    MySQL.Async.execute("UPDATE player_inv SET player_inv = @inv WHERE player_identifier = @identifier", {
        ['@identifier'] = player,
        ['@inv'] = encodedInv
    })

    if omg_framework._display_logs then
        print("Saving "..GetPlayerName(id).." inventory")
    end
end




function AddItemToPlayerInv(id, item, _count)
    if DoesItemExist(item) then
        local inv = PlayersData[id].inventory
        local countOld, num = GetItemCount(id, item)
        if countOld == 0 then
            table.insert(inv, {name = item, count = _count})
        else
            table.remove(inv, num)
            table.insert(inv, {name = item, count = countOld + _count})
        end
    end
end


function GetItemCount(id, item)
    local inv = PlayersData[id].inventory
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