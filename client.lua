local RegisteredObjects = {}
local Objects = {}
local ScopedPlayers = {}
local PlayerToObjects = {}
local ToRemoveObjects = {}

local myId = tostring(GetPlayerServerId(PlayerId()))
local loaded = true

Citizen.CreateThread(function()
    local plaIds = GetActivePlayers()
    for i = 1, #plaIds do
        ScopedPlayers[tostring(GetPlayerServerId(plaIds[i]))] = true
    end
    ScopedPlayers[myId] = nil

    TriggerServerEvent("sf-attachobject:ready")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for id, object in pairs(Objects) do
        if(object.handle and DoesEntityExist(object.handle)) then
            RemoveObject(object.handle)
        end
    end
end)

RegisterNetEvent("sf-attachobject:registerObject", function (name, object)
    if RegisteredObjects[name] ~= nil then return end
    RegisteredObjects[name] = object
end)

RegisterNetEvent("sf-attachobject:unregisterObject", function (name)
    if RegisteredObjects[name] == nil then return end
    RegisteredObjects[name] = nil
end)

RegisterNetEvent("sf-attachobject:registeredObjects", function(objects)
    RegisteredObjects = objects
end)

RegisterNetEvent("sf-attachobject:internal:addObject", function(objectId, playerId, objectName)
    if RegisteredObjects[objectName] == nil then return end
    local objectData = {
        playerId = playerId,
        objectName = objectName,
        objectId = objectId
    }

    Objects[objectId] = objectData

    if PlayerToObjects[objectData.playerId] == nil then PlayerToObjects[objectData.playerId] = {} end
    PlayerToObjects[objectData.playerId][objectId] = true
    if ScopedPlayers[objectData.playerId] or objectData.playerId == myId  then
        CreateObj(objectId)
    end
end)

RegisterNetEvent("sf-attachobject:internal:removeObject", function(objectId)
    if type(objectId) == "string" then
        RemoveObject(objectId)
    else
        for i=1, #objectId do
            RemoveObject(objectId[i])
        end
    end
end)

RegisterNetEvent("onPlayerJoining", function(playerId)
    local playerId = tostring(playerId)

    ScopedPlayers[playerId] = true
    if PlayerToObjects[playerId] then
        Citizen.CreateThread(function()
            local counter = 0

            for objectId, _ in pairs(PlayerToObjects[playerId]) do
                if ScopedPlayers[playerId] == nil then
                    break
                end
                counter = counter + 1
                CreateObj(objectId)
                if counter > 1 then
                    Citizen.Wait(100)
                end
            end
        end)
    end
end)

RegisterNetEvent("onPlayerDropped", function(playerId)
    local playerId = tostring(playerId)
    ScopedPlayers[playerId] = nil

    if PlayerToObjects[playerId] then
        for objectId, _ in pairs(PlayerToObjects[playerId]) do
            if Objects[objectId] then
                ToRemoveObjects[objectId] = Objects[objectId].handle
                Objects[objectId].handle = nil
            end
        end
    end
end)

RegisterNetEvent("sf-attachobject:propfix", function()
    local objects = GetGamePool("CObject")
    local playerPed = PlayerPedId()
    for i=1, #objects do
        if IsEntityAttachedToEntity(objects[i], playerPed) then
            DeleteEntity_2(objects[i])
        end
    end

    if PlayerToObjects[myId] then
        for objectId, _ in pairs(PlayerToObjects[myId]) do
            if Objects[objectId].handle == nil or (not DoesEntityExist(Objects[objectId].handle)) then
                CreateObj(objectId)
            end
        end
    end
end)

function RemoveObject(objectId)
    if Objects[objectId] then
        if PlayerToObjects[Objects[objectId].playerId] then
            PlayerToObjects[Objects[objectId].playerId][objectId] = nil
        end

        if Objects[objectId].handle ~= nil then
            DeleteEntity_2(Objects[objectId].handle)
        end

        Objects[objectId] = nil
    end
end

function CreateObj(objectId)
    if loaded then
        local data = Objects[objectId]
        if data then
            if data.handle and DoesEntityExist(data.handle) then
                return
            end

            local objData = RegisteredObjects[data.objectName]
            if objData == nil then return end

            local player = GetPlayerFromServerId(tonumber(data.playerId))
            if player == -1 and myId ~= data.playerId then return false end
            data.ped = GetPlayerPed(player)

            if DoesEntityExist(data.ped) then
                if IsEntityVisible(data.ped) then
                    local coords = GetEntityCoords(data.ped)
                    ReqModel(objData[1])
                    data.handle = CreateObjectNoOffset(objData[1], coords.x, coords.y, coords.z, false, false, false)
                    if objData[5] then SetEntityCollision(data.handle, false, false) end
                    if objData[6] then SetEntityCompletelyDisableCollision(data.handle, true, true) end

                    AttachEntityToEntity(data.handle, data.ped, GetPedBoneIndex(data.ped, objData[4]), objData[2].x, objData[2].y, objData[2].z, objData[3].x, objData[3].y, objData[3].z, true, true, false, true, 1, true)
                end
            end
            return true
        end
    end

    return false
end

function ReqModel(modelHash)
    if not HasModelLoaded(modelHash) then
        local timeout = 0
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) and timeout < 60 do
            timeout = timeout + 1
            Citizen.Wait(0)
        end
    end
end

function DeleteEntity_2(handle)
    SetEntityAsMissionEntity(handle, true, true)
    DeleteEntity(handle)
end

Citizen.CreateThread(function()
    while true do
        pcall(function()
            for playerId, _ in pairs(ScopedPlayers) do
                if PlayerToObjects[playerId] then
                    for objectId, _ in pairs(PlayerToObjects[tostring(playerId)]) do
                        if Objects[objectId].handle == nil or (not DoesEntityExist(Objects[objectId].handle)) then
                            CreateObj(objectId)
                        else
                            if not IsEntityAttached(Objects[objectId].handle) then
                                if Objects[objectId].handle ~= 0 then RemoveObject(Objects[objectId].handle) end
                                Objects[objectId].handle = nil
                            end
                        end
                    end
                end
                Citizen.Wait(100)
            end

            local _counter = 0
            for objectId, handle in pairs(ToRemoveObjects) do
                _counter = _counter + 1
                if handle ~= 0 then DeleteEntity_2(handle) end
                ToRemoveObjects[objectId] = nil
                if _counter > 1 then Citizen.Wait(100) end
            end
            _counter = nil -- help gc
        end)
        Citizen.Wait(5000)
    end
end)