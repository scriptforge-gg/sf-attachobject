RegisteredObjects = {}
MyServerId = tostring(GetPlayerServerId(PlayerId()))

Citizen.CreateThread(function()
    TriggerServerEvent("sf-attachobject:ready")
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

function ReqModel(modelHash)
    local timeout = 0
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) and timeout < 30 do
        timeout = timeout + 1
        Citizen.Wait(0)
    end
end

function DeleteEntity_2(handle)
    SetEntityAsMissionEntity(handle, true, true)
    DeleteEntity(handle)
end