local ReadyPlayers = {}
local Objects = {}
local PlayerObjects = {}
local ObjectId = 0
local RegisteredObjects = {}

function GetObjectId()
	if ObjectId < 65535 then
		ObjectId = ObjectId + 1
	else
		ObjectId = 0
	end
    return tostring(ObjectId)
end

---@param objectName string
---@param modelHash number | string
---@param offset vector3
---@param rotation vector3
---@param boneId number
---@param disableCollision boolean
---@param completelyDisableCollision boolean
--- It register an object with all parameters needed to attach it to a player
--- This way it does not take so much network bandwith when players are constantly
--- getting props attached and detached from them.
function RegisterObject(objectName, modelHash, offset, rotation, boneId, disableCollision, completelyDisableCollision)
    if type(objectName) ~= "string" then
        print("ERROR: objectName has to be a string!")
        return
    end

    local nameHash = joaat(objectName)

    if RegisteredObjects[nameHash] ~= nil then
        print(("ERROR: Object with name %s is already registered! Change used name of object in resource %s"):format(objectName, GetInvokingResource()))
        return
    end

    if type(modelHash) ~= "number" then modelHash = joaat(modelHash) end

    if type(offset) ~= "vector3" then
        print("ERROR: offset is not a vector3!")
        return
    end

    if type(rotation) ~= "vector3" then
        print("ERROR: rotation is not a vector3!")
        return
    end

    if type(boneId) ~= "number" then
        print("ERROR: boneId is not a number!")
        return
    end

    if type(disableCollision) ~= "boolean" then
        print("ERROR: disableCollision is not a number!")
        return
    end

    if type(completelyDisableCollision) ~= "boolean" then
        print("ERROR: completelyDisableCollision is not a number!")
        return
    end

    RegisteredObjects[nameHash] = {
        modelHash,
        offset,
        rotation,
        boneId,
        disableCollision,
        completelyDisableCollision,
        objectName
    }

    TriggerClientEvent("sf-attachobject:registerObject", -1, nameHash, RegisteredObjects[nameHash])
end

---@param objectName string
function UnregisterObject(objectName)
    local nameHash = joaat(objectName)
    if RegisteredObjects[nameHash] == nil then return end
    RegisteredObjects[nameHash] = nil
    TriggerClientEvent("sf-attachobject:unregisterObject", -1, nameHash)
end

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
    Objects[objectId] = nameHash

    if PlayerObjects[playerId] == nil then PlayerObjects[playerId] = {} end
    PlayerObjects[playerId][objectId] = nameHash

    TriggerClientEvent("sf-attachobject:internal:addObject", -1, objectId, playerId, Objects[objectId])

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
    local playerId = tostring(source)
    if ReadyPlayers[playerId] == nil then
        ReadyPlayers[playerId] = true
        TriggerClientEvent("sf-attachobject:registeredObjects", tonumber(playerId), RegisteredObjects)
    end
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
    ReadyPlayers[playerId] = nil

    TriggerClientEvent("sf-attachobject:internal:removeObject", -1, objsToRemove)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for playerId, objects in pairs(PlayerObjects) do
        ClearPlayerObjects(playerId)
    end
end)