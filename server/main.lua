local KGCore = exports['kg-core']:GetCoreObject()

local function exploitBan(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            GetPlayerName(id),
            KGCore.Functions.GetIdentifier(id, 'license'),
            KGCore.Functions.GetIdentifier(id, 'discord'),
            KGCore.Functions.GetIdentifier(id, 'ip'),
            reason,
            2147483647,
            'kg-pawnshop'
        })
    TriggerEvent('kg-log:server:CreateLog', 'pawnshop', 'Player Banned', 'red',
        string.format('%s was banned by %s for %s', GetPlayerName(id), 'kg-pawnshop', reason), true)
    DropPlayer(id, 'You were permanently banned by the server for: Exploiting')
end

RegisterNetEvent('kg-pawnshop:server:sellPawnItems', function(itemName, itemAmount, itemPrice)
    local src = source
    local Player = KGCore.Functions.GetPlayer(src)
    local totalPrice = (tonumber(itemAmount) * itemPrice)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist
    for _, value in pairs(Config.PawnLocation) do
        dist = #(playerCoords - value.coords)
        if #(playerCoords - value.coords) < 2 then
            dist = #(playerCoords - value.coords)
            break
        end
    end
    if dist > 5 then
        exploitBan(src, 'sellPawnItems Exploiting')
        return
    end
    if exports['kg-inventory']:RemoveItem(src, itemName, tonumber(itemAmount), false, 'kg-pawnshop:server:sellPawnItems') then
        if Config.BankMoney then
            Player.Functions.AddMoney('bank', totalPrice, 'kg-pawnshop:server:sellPawnItems')
        else
            Player.Functions.AddMoney('cash', totalPrice, 'kg-pawnshop:server:sellPawnItems')
        end
        TriggerClientEvent('KGCore:Notify', src, Lang:t('success.sold', { value = tonumber(itemAmount), value2 = KGCore.Shared.Items[itemName].label, value3 = totalPrice }), 'success')
        TriggerClientEvent('kg-inventory:client:ItemBox', src, KGCore.Shared.Items[itemName], 'remove')
    else
        TriggerClientEvent('KGCore:Notify', src, Lang:t('error.no_items'), 'error')
    end
    TriggerClientEvent('kg-pawnshop:client:openMenu', src)
end)

RegisterNetEvent('kg-pawnshop:server:meltItemRemove', function(itemName, itemAmount, item)
    local src = source
    local Player = KGCore.Functions.GetPlayer(src)
    if exports['kg-inventory']:RemoveItem(src, itemName, itemAmount, false, 'kg-pawnshop:server:meltItemRemove') then
        TriggerClientEvent('kg-inventory:client:ItemBox', src, KGCore.Shared.Items[itemName], 'remove')
        local meltTime = (tonumber(itemAmount) * item.time)
        TriggerClientEvent('kg-pawnshop:client:startMelting', src, item, tonumber(itemAmount), (meltTime * 60000 / 1000))
        TriggerClientEvent('KGCore:Notify', src, Lang:t('info.melt_wait', { value = meltTime }), 'primary')
    else
        TriggerClientEvent('KGCore:Notify', src, Lang:t('error.no_items'), 'error')
    end
end)

RegisterNetEvent('kg-pawnshop:server:pickupMelted', function(item)
    local src = source
    local Player = KGCore.Functions.GetPlayer(src)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist
    for _, value in pairs(Config.PawnLocation) do
        dist = #(playerCoords - value.coords)
        if #(playerCoords - value.coords) < 2 then
            dist = #(playerCoords - value.coords)
            break
        end
    end
    if dist > 5 then
        exploitBan(src, 'pickupMelted Exploiting')
        return
    end
    for _, v in pairs(item.items) do
        local meltedAmount = v.amount
        for _, m in pairs(v.item.reward) do
            local rewardAmount = m.amount
            if exports['kg-inventory']:AddItem(src, m.item, (meltedAmount * rewardAmount), false, false, 'kg-pawnshop:server:pickupMelted') then
                TriggerClientEvent('kg-inventory:client:ItemBox', src, KGCore.Shared.Items[m.item], 'add')
                TriggerClientEvent('KGCore:Notify', src, Lang:t('success.items_received', { value = (meltedAmount * rewardAmount), value2 = KGCore.Shared.Items[m.item].label }), 'success')
                TriggerClientEvent('kg-pawnshop:client:resetPickup', src)
            else
                TriggerClientEvent('KGCore:Notify', src, Lang:t('error.inventory_full', { value = KGCore.Shared.Items[m.item].label }), 'warning', 7500)
            end
        end
    end
    TriggerClientEvent('kg-pawnshop:client:openMenu', src)
end)

KGCore.Functions.CreateCallback('kg-pawnshop:server:getInv', function(source, cb)
    local Player = KGCore.Functions.GetPlayer(source)
    local inventory = Player.PlayerData.items
    return cb(inventory)
end)
