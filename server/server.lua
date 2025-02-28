local Bridge = require 'server.bridge'

local VehicleList = {}
local getItemInfo = Shared.Inventory == 'qb' and function(item) return item.info end or function(item) return item.metadata end

function GiveTempKeys(id, plate)
    local citizenid = Bridge:GetPlayerCitizenId(id)
    if not VehicleList[plate] then VehicleList[plate] = {} end
    VehicleList[plate][citizenid] = true
    local ndata = {
        title = 'Recieved',
        description = 'You got temporary key to the vehicle',
        type = 'success'
    }
    TriggerClientEvent('ox_lib:notify', id, ndata)
    TriggerClientEvent('mm_carkeys:client:addtempkeys', id, plate)
end

function RemoveTempKeys(id, plate)
    local citizenid = Bridge:GetPlayerCitizenId(id)
    if VehicleList[plate] and VehicleList[plate][citizenid] then
        VehicleList[plate][citizenid] = nil
    end
    TriggerClientEvent('mm_carkeys:client:removetempkeys', id, plate)
end

exports('GiveTempKeys', function(src, plate)
    if not plate then
        local nData = {
            title = 'Failed',
            description = 'No Vehicle Plate Found',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, nData)
        return
    end
    GiveTempKeys(src, plate)
end)

exports('RemoveTempKeys', function(src, plate)
    if not plate then
        local nData = {
            title = 'Failed',
            description = 'No Vehicle Plate Found',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, nData)
        return
    end
    RemoveTempKeys(src, plate)
end)

exports('GiveKeyItem', function(src, plate, netId)
    if not plate or not netId then
        local nData = {
            title = 'Failed',
            description = 'No Vehicle Data Found',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, nData)
        return
    end
    TriggerClientEvent('mm_carkeys:client:setplayerkey', src, plate, netId)
end)

exports('RemoveKeyItem', function(src, plate)
    if not plate then
        local nData = {
            title = 'Failed',
            description = 'No Vehicle Data Found',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, nData)
        return
    end
    TriggerClientEvent('mm_carkeys:client:removeplayerkey', src, plate)
end)

exports('HaveTemporaryKey', function(src, plate)
    if not plate then
        return lib.notify({
            title = 'Failed',
            description = 'No Vehicle Data Found',
            type = 'error'
        })
    end
    return lib.callback.await('mm_carkeys:client:havekey', src, 'temp', plate)
end)

exports('HavePermanentKey', function(src, plate)
    if not plate then
        return lib.notify({
            title = 'Failed',
            description = 'No Vehicle Data Found',
            type = 'error'
        })
    end
    return lib.callback.await('mm_carkeys:client:havekey', src, 'perma', plate)
end)

lib.callback.register('mm_carkeys:server:getvehiclekeys', function()
    local citizenid = Bridge:GetPlayerCitizenId(id)
    local keysList = {}
    for plate, citizenids in pairs (VehicleList) do
        if citizenids[citizenid] then
            keysList[plate] = true
        end
    end
    return keysList
end)

RegisterNetEvent('mm_carkeys:server:setVehLockState', function(vehNetId, state)
    SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(vehNetId), state)
end)

RegisterNetEvent('mm_carkeys:server:acquiretempvehiclekeys', function(plate)
    local src = source
    GiveTempKeys(src, plate)
end)

RegisterNetEvent('mm_carkeys:server:removetempvehiclekeys', function(plate)
    local src = source
    RemoveTempKeys(src, plate)
end)

RegisterNetEvent('mm_carkeys:server:removelockpick', function(item)
    Bridge:RemoveItem(source, item)
end)

RegisterNetEvent('mm_carkeys:server:acquirevehiclekeys', function(plate, model)
    local src = source
	local Player = Bridge:GetPlayer(src)
    if Player then
        local info = {}
		info.label = model.. '-' ..plate
        info.plate = plate
		Bridge:AddItem(src, 'vehiclekey', info)
	end
end)

RegisterNetEvent('mm_carkeys:server:removevehiclekeys', function(plate)
    local src = source
    local keys = Bridge:GetPlayerItemsByName(src, 'vehiclekey')
    for _, v in pairs(keys) do
        local info = getItemInfo(v)
        if info.plate == plate then
            Bridge:RemoveItem(src, 'vehiclekey', v.slot)
            break
        end
    end
end)

RegisterNetEvent('mm_carkeys:server:stackkeys', function()
    local src = source
    local bagFound = Bridge:GetPlayerItemByName(src, 'keybag')
    local keys = Bridge:GetPlayerItemsByName(src, 'vehiclekey')
    local plates = {}
    local platestxt = ''
    for _, v in pairs(keys) do
        local info = getItemInfo(v)
        if info.plate then
            plates[#plates+1] = {
                plate = info.plate,
                label = info.label
            }
            platestxt = platestxt..info.plate..', '
            Bridge:RemoveItem(src, 'vehiclekey', v.slot)
        end
    end
    if bagFound then
        local info = getItemInfo(bagFound)
        local getplates = info.plates
        for _, v in pairs(getplates) do
            plates[#plates+1] = {
                plate = v.plate,
                label = v.label
            }
            platestxt = platestxt..v.plate..', '
        end
        Bridge:RemoveItem(src, 'keybag', bagFound.slot)
    end
    Bridge:AddItem(src, 'keybag', {plates = plates, platestxt = platestxt})
end)

RegisterNetEvent('mm_carkeys:server:unstackkeys', function()
    local src = source
    local bag = Bridge:GetPlayerItemByName(src, 'keybag')
    if not bag then
        local ndata = {
            description = 'You don\'t have a key bag',
            type = 'error'
        }
        TriggerClientEvent('ox_lib:notify', src, ndata)
        return
    end
    Bridge:RemoveItem(src, 'keybag', bag.slot)
    local itemInfo = getItemInfo(bag)
    for _, v in pairs(itemInfo.plates) do
        local info = {}
		info.label = v.label
        info.plate = v.plate
        Bridge:AddItem(src, 'vehiclekey', info)
    end
end)

lib.versionCheck('SOH69/mm_carkeys')