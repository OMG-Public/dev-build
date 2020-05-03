

function AddItemToPlayerInv(id, item, _count)
    if DoesItemExist(item) then
        local player = _player_get_identifier(id)
        local inv, place = GetInventoryFromCache(id)
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

            PlayersData[place].inventory = inv

            -- To remove later 
            for k,v in pairs(PlayersData[place].inventory) do
                DebugPrint(v.name.." - x"..v.count)
            end
        else
            -- To do notification if can not hold the item
        end
    end
end

function RemoveItemFromPlayerInv(id, item, _count)
    if DoesItemExist(item) then
        local player = _player_get_identifier(id)
        local inv, place = GetInventoryFromCache(id)

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

        PlayersData[place].inventory = inv

        -- To remove later / For debug only
        for k,v in pairs(PlayersData[place].inventory) do
            DebugPrint(v.name.." - x"..v.count)
        end
    end
end

function GetInventoryFromCache(id)
    for k,v in pairs(PlayersData) do
        if v.ServerID == id then
            return v.inventory, k
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


local debug = false
function DebugPrint(text)
    if debug then
        print(text)
    end
end