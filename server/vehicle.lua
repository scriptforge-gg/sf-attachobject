local VehicleObjects = {}

---@param entity number
---@param objectName string
---@return string
function CreateVehicleAttachObject(entity, objectName)
    if not entity or not objectName then
        print("ERROR: entity or objectName is nil")
        return ""
    end

    local entity = tonumber(entity)
    if entity == nil then
        print("ERROR: entity is nil")
        return ""
    end

    local objectId = GetObjectId()
    local nameHash = joaat(objectName)
    Objects[objectId] = nameHash

    if VehicleObjects[entity] == nil then VehicleObjects[entity] = {} end
    VehicleObjects[entity][objectId] = nameHash

    Entity(entity).state.attachObjectVeh = true
    TriggerClientEvent("sf-attachobject:internal:addVehicleObject", -1, objectId, NetworkGetNetworkIdFromEntity(entity), Objects[objectId])

    return objectId
end

---@param entity number
---@param objectId string
---@return boolean
function RemoveVehicleAttachObject(entity, objectId)
    if not entity or not objectId then
        print("ERROR: entity or objectId is nil")
        return false
    end

    local entity = tonumber(entity)
    if entity == nil then
        print("ERROR: entity is nil")
        return false
    end

    local objectId = tostring(objectId)

    if Objects[objectId] and VehicleObjects[entity] and VehicleObjects[entity][objectId] then
        VehicleObjects[entity][objectId] = nil
        Objects[objectId] = nil

        local noOtherObjectsFound = true
        for k, v in pairs(VehicleObjects[entity]) do
            noOtherObjectsFound = false
            break
        end

        if noOtherObjectsFound then
            Entity(entity).state.attachObjectVeh = nil
        end

        TriggerClientEvent("sf-attachobject:internal:removeVehicleObject", -1, objectId)
        return true
    end

    return false
end

---@param entity number
---@return table
function GetObjectsOnVehicle(entity)
    if not entity then
        print("ERROR: entity is nil")
        return {}
    end

    local entity = tonumber(entity)
    if entity == nil then
        print("ERROR: entity is nil")
        return {}
    end

    if VehicleObjects[entity] == nil then
        return {}
    end

    local objectList = {}

    for objectId, nameHash in pairs(VehicleObjects[entity]) do
        objectList[#objectList+1] = {
            objectId = objectId,
            objectName = RegisteredObjects[nameHash]?[7]
        }
    end

    return objectList
end

---@param entity number
---@param objectName string?
function ClearVehicleObjects(entity, objectName)
    local entity = tonumber(entity)
    if entity == nil then
        print("ERROR: entity is nil")
        return
    end

    if not VehicleObjects[entity] then return false end
    local objsToRemove = {}

    local objectNameHashed = nil
    if objectName ~= nil then
        objectNameHashed = joaat(objectName)
    end

    for objectId, hash in pairs(VehicleObjects[entity]) do
        if not objectName or (objectNameHashed == hash) then
            objsToRemove[#objsToRemove + 1] = objectId
            VehicleObjects[entity][objectId] = nil
            Objects[objectId] = nil
        end
    end

    local noOtherObjectsFound = true
    for k, v in pairs(VehicleObjects[entity]) do
        noOtherObjectsFound = false
        break
    end

    if noOtherObjectsFound then
        Entity(entity).state.attachObjectVeh = nil
    end

    if #objsToRemove > 0 then
        TriggerClientEvent("sf-attachobject:internal:removeVehicleObject", -1, objsToRemove)
    end
end

AddEventHandler("entityRemoved", function(entity)
    if not VehicleObjects[entity] then return end
    local objsToRemove = {}

    for objectId, _ in pairs(VehicleObjects[entity]) do
        objsToRemove[#objsToRemove + 1] = objectId
        Objects[objectId] = nil
    end

    VehicleObjects[entity] = nil

    TriggerClientEvent("sf-attachobject:internal:removeVehicleObject", -1, objsToRemove)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for entity, objects in pairs(VehicleObjects) do
        ClearVehicleObjects(entity)
    end
end)