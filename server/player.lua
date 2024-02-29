local Objects = {}
PlayerObjects = {}

---@param playerId string
---@param objectName string
---@return string
function CreateAttachObject(playerId, objectName)
    if not playerId or not objectName then
        print("ERROR: playerId or objectName is nil")
        return ""
    end

    playerId = tostring(playerId)

    local objectId = GetObjectId()
    local nameHash = joaat(objectName)
    Objects[objectId] = {
        playerId = playerId,
        objectName = nameHash,
        objectId = objectId
    }

    if PlayerObjects[playerId] == nil then PlayerObjects[playerId] = {} end
    PlayerObjects[playerId][objectId] = nameHash

    TriggerClientEvent("sf-attachobject:internal:addObject", -1, objectId, playerId, nameHash)

    return objectId
end

---@param playerId string
---@param objectId string
---@return boolean
function RemoveAttachObject(playerId, objectId)
    if not playerId or not objectId then
        print("ERROR: playerId or objectId is nil")
        return false
    end

    playerId = tostring(playerId)
    objectId = tostring(objectId)

    if Objects[objectId] and PlayerObjects[playerId] and PlayerObjects[playerId][objectId] then
        PlayerObjects[playerId][objectId] = nil
        Objects[objectId] = nil

        TriggerClientEvent("sf-attachobject:internal:removeObject", -1, objectId)
        return true
    end

    return false
end

---@param playerId string
---@return table
function GetObjectsOnPlayer(playerId)
    if not playerId then
        print("ERROR: playerId is nil")
        return {}
    end

    playerId = tostring(playerId)
    if PlayerObjects[playerId] == nil then
        return {}
    end

    local objectList = {}

    for objectId, nameHash in pairs(PlayerObjects[playerId]) do
        objectList[#objectList+1] = {
            objectId = objectId,
            objectName = RegisteredObjects[nameHash]?[7]
        }
    end

    return objectList
end

---@param playerId string
---@param objectName string?
function ClearPlayerObjects(playerId, objectName)
    playerId = tostring(playerId)
    if not PlayerObjects[playerId] then return false end
    local objsToRemove = {}

    local objectNameHashed = nil
    if objectName ~= nil then
        objectNameHashed = joaat(objectName)
    end

    for objectId, hash in pairs(PlayerObjects[playerId]) do
        if not objectName or (objectNameHashed == hash) then
            objsToRemove[#objsToRemove + 1] = objectId
            PlayerObjects[playerId][objectId] = nil
            Objects[objectId] = nil
        end
    end

    if #objsToRemove > 0 then
        TriggerClientEvent("sf-attachobject:internal:removeObject", -1, objsToRemove)
    end
end

---@param playerId string
function FixPlayerProps(playerId)
    TriggerClientEvent("sf-attachobject:propfix", tonumber(playerId))
end

RegisterNetEvent("sf-attachobject:ready", function()
    TriggerClientEvent("sf-attachobject:playerObjects", source, Objects)
end)

AddEventHandler("playerDropped", function()
    local playerId = tostring(source)
    if not PlayerObjects[playerId] then return end
    local objsToRemove = {}

    for objectId, _ in pairs(PlayerObjects[playerId]) do
        objsToRemove[#objsToRemove + 1] = objectId
        Objects[objectId] = nil
    end

    PlayerObjects[playerId] = nil

    TriggerClientEvent("sf-attachobject:internal:removeObject", -1, objsToRemove)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for playerId, objects in pairs(PlayerObjects) do
        ClearPlayerObjects(playerId)
    end
end)