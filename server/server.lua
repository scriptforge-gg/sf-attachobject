RegisteredObjects = {}

local readyPlayers = {}
local objectId = 0

function GetObjectId()
	if objectId < 65535 then
		objectId = objectId + 1
	else
		objectId = 0
	end
    return tostring(objectId)
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

RegisterNetEvent("sf-attachobject:ready", function()
    local playerId = tostring(source)
    if readyPlayers[playerId] == nil then
        readyPlayers[playerId] = true
        ---@diagnostic disable-next-line: param-type-mismatch
        TriggerClientEvent("sf-attachobject:registeredObjects", tonumber(playerId), RegisteredObjects)
        ---@diagnostic disable-next-line: param-type-mismatch
        TriggerClientEvent("sf-attachobject:getPlayerObjects", tonumber(playerId), PlayerObjects)
        ---@diagnostic disable-next-line: param-type-mismatch
        TriggerClientEvent("sf-attachobject:getVehicleObjects", tonumber(playerId), VehicleObjectsNetId)
    end
end)

AddEventHandler("playerDropped", function()
    local playerId = tostring(source)
    readyPlayers[playerId] = nil
end)