local ScopedVehicles = {}

local VehiclesToObjects = {}
local Objects = {}

local function createObj(objectId)
    local data = Objects[objectId]
    if data then
        if data.handle and DoesEntityExist(data.handle) then
            return
        end

        local objData = RegisteredObjects[data.objectName]
        if objData == nil then return end

        if not NetworkDoesNetworkIdExist(data.netId) then return end
        data.veh = NetworkGetEntityFromNetworkId(data.netId)

        if DoesEntityExist(data.veh) then
            if IsEntityVisible(data.veh) then
                local coords = GetEntityCoords(data.veh)
                ReqModel(objData[1])
                data.handle = CreateObjectNoOffset(objData[1], coords.x, coords.y, coords.z, false, false, false)
                SetEntityAsMissionEntity(data.handle, true, true)
                if objData[5] then SetEntityCollision(data.handle, false, false) end
                if objData[6] then SetEntityCompletelyDisableCollision(data.handle, true, true) end

                AttachEntityToEntity(data.handle, data.veh, objData[4], objData[2].x, objData[2].y, objData[2].z, objData[3].x, objData[3].y, objData[3].z, true, true, false, true, 1, true)
            end
        end
        return true
    end

    return false
end

local function removeObject(objectId)
    if Objects[objectId] then
        if VehiclesToObjects[Objects[objectId].netId] then
            VehiclesToObjects[Objects[objectId].netId][objectId] = nil
        end

        if Objects[objectId].handle ~= nil then
            DeleteEntity_2(Objects[objectId].handle)
        end

        Objects[objectId] = nil
    end
end

RegisterNetEvent("sf-attachobject:internal:addVehicleObject", function(objectId, netId, objectName)
    if RegisteredObjects[objectName] == nil then return end
    local objectData = {
        netId = netId,
        objectName = objectName,
        objectId = objectId
    }

    Objects[objectId] = objectData

    if VehiclesToObjects[objectData.netId] == nil then VehiclesToObjects[objectData.netId] = {} end
    VehiclesToObjects[objectData.netId][objectId] = true

    if NetworkDoesNetworkIdExist(objectData.netId) then
        createObj(objectId)
    end
end)

RegisterNetEvent("sf-attachobject:internal:removeVehicleObject", function(objectId)
    if type(objectId) == "string" then
        removeObject(objectId)
    else
        for i=1, #objectId do
            removeObject(objectId[i])
        end
    end
end)

AddStateBagChangeHandler("attachObjectVeh", nil, function(bagName, key, value) 
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 then return end
    if not NetworkGetEntityIsNetworked(entity) then return end
    local netId = NetworkGetNetworkIdFromEntity(entity)
    local wasScopedBefore = ScopedVehicles[entity] == nil

    ScopedVehicles[entity] = netId

    if wasScopedBefore then
        -- new vehicle in scope
        if VehiclesToObjects[netId] ~= nil then
            for objectId, _ in pairs(VehiclesToObjects[netId]) do
                createObj(objectId)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        for entity, netId in pairs(ScopedVehicles) do
            if not DoesEntityExist(entity) then
                -- vehicle is no longer in scope
                if VehiclesToObjects[netId] ~= nil then
                    for objectId, _ in pairs(VehiclesToObjects[netId]) do
                        local data = Objects[objectId]
                        if data and data.handle ~= nil and DoesEntityExist(data.handle) then
                            DeleteEntity_2(data.handle)
                            Objects[objectId].handle = nil
                        end
                    end
                end

                ScopedVehicles[entity] = nil
            end
        end
        Citizen.Wait(500)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for id, object in pairs(Objects) do
        if(object.handle and DoesEntityExist(object.handle)) then
            removeObject(object.handle)
        end
    end
end)